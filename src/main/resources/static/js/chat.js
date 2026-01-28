// Chat functionality with WebSocket support using STOMP

let stompClient = null;
let conversationId = null;
let currentUserId = null;
let isSending = false; // Flag to prevent duplicate submissions
let wsConnected = false; // Track WebSocket connection state
let wsSubscription = null; // Track subscription
let reconnectAttempts = 0;
const MAX_RECONNECT_ATTEMPTS = 5;
const RECONNECT_DELAY = 3000; // 3 seconds

// Make initialization function available globally
window.initializeChat = function() {
    // Get conversation ID and user ID from window variables or script tags
    if (window.conversationId) {
        conversationId = window.conversationId;
    }
    if (window.currentUserId) {
        currentUserId = window.currentUserId;
    }
    
    // Fallback: try to get from script tags
    if (!conversationId || !currentUserId) {
        const scriptTags = document.querySelectorAll('script');
        for (let scriptTag of scriptTags) {
            if (scriptTag.textContent) {
                const match = scriptTag.textContent.match(/conversationId\s*=\s*(\d+)/);
                if (match) {
                    conversationId = parseInt(match[1]);
                    console.log('Found conversationId from script:', conversationId);
                }
                const userIdMatch = scriptTag.textContent.match(/currentUserId\s*=\s*(\d+)/);
                if (userIdMatch) {
                    currentUserId = parseInt(userIdMatch[1]);
                    console.log('Found currentUserId from script:', currentUserId);
                }
            }
        }
    }
    
    if (!conversationId || !currentUserId) {
        console.error('Failed to initialize: conversationId =', conversationId, 'currentUserId =', currentUserId);
        return;
    }
    
    console.log('Chat initialized with conversationId:', conversationId, 'currentUserId:', currentUserId);
    
    // Test endpoint accessibility
    window.testEndpointAccess();
    
    // Initialize WebSocket connection
    initializeWebSocket();
    
    // Reconnect WebSocket if connection is lost (check every 5 seconds)
    setInterval(function() {
        if (!wsConnected && conversationId) {
            console.log('WebSocket not connected, attempting to reconnect...');
            connectWebSocket();
        }
    }, 5000);
    
    // Setup message form - only use form submit, not button click
    const messageForm = document.getElementById('messageForm');
    
    if (messageForm) {
        // Remove any existing listeners by cloning the form
        const newForm = messageForm.cloneNode(true);
        messageForm.parentNode.replaceChild(newForm, messageForm);
        
        // Add only form submit listener (button click will trigger form submit)
        document.getElementById('messageForm').addEventListener('submit', handleMessageSubmit);
        console.log('Message form event listener attached');
    } else {
        console.error('Message form not found!');
    }
    
    // Auto-scroll to bottom on load
    scrollToBottom();
    
    // Poll for new messages every 3 seconds (fallback if WebSocket fails)
    setInterval(pollMessages, 3000);
};

// Wait for both DOM and script variables to be ready
function waitForInitialization() {
    // Check if variables are set
    if (window.conversationId && window.currentUserId) {
        console.log('Variables ready, initializing chat...');
        window.initializeChat();
    } else {
        // Wait a bit and try again
        setTimeout(waitForInitialization, 100);
    }
}

// Auto-initialize when DOM is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function() {
        setTimeout(waitForInitialization, 100);
    });
} else {
    // DOM is already loaded, wait for variables
    setTimeout(waitForInitialization, 100);
}

function initializeWebSocket() {
    console.log('Initializing WebSocket...');
    console.log('SockJS available:', typeof SockJS !== 'undefined');
    console.log('STOMP available:', typeof Stomp !== 'undefined');
    
    // Load SockJS and STOMP from CDN if not already loaded
    if (typeof SockJS === 'undefined') {
        console.log('Loading SockJS library...');
        const sockjsScript = document.createElement('script');
        sockjsScript.src = 'https://cdn.jsdelivr.net/npm/sockjs-client@1/dist/sockjs.min.js';
        sockjsScript.onload = function() {
            console.log('✓ SockJS loaded successfully');
            if (typeof SockJS === 'undefined') {
                console.error('✗ SockJS still undefined after loading');
                updateConnectionStatus('error', 'SockJS failed to load');
                return;
            }
            loadStomp();
        };
        sockjsScript.onerror = function(error) {
            console.error('✗ Failed to load SockJS library:', error);
            updateConnectionStatus('error', 'Failed to load SockJS');
            alert('Failed to load WebSocket library. Real-time messaging may not work.');
        };
        document.head.appendChild(sockjsScript);
    } else {
        console.log('✓ SockJS already loaded');
        loadStomp();
    }
}

function loadStomp() {
    if (typeof Stomp === 'undefined') {
        console.log('Loading STOMP library...');
        // Use the older, more compatible version of STOMP.js
        const stompScript = document.createElement('script');
        stompScript.src = 'https://cdn.jsdelivr.net/npm/stompjs@2.3.3/lib/stomp.min.js';
        stompScript.onload = function() {
            console.log('STOMP script loaded, checking if Stomp is available...');
            // Wait a moment for the library to initialize
            setTimeout(function() {
                if (typeof Stomp === 'undefined') {
                    console.error('✗ STOMP library failed to load');
                    updateConnectionStatus('error', 'STOMP failed to load');
                    alert('Failed to load STOMP library. Real-time messaging may not work.');
                    return;
                }
                console.log('✓ STOMP library ready, connecting...');
                connectWebSocket();
            }, 100);
        };
        stompScript.onerror = function(error) {
            console.error('✗ Failed to load STOMP library:', error);
            updateConnectionStatus('error', 'Failed to load STOMP');
            alert('Failed to load STOMP library. Real-time messaging may not work.');
        };
        document.head.appendChild(stompScript);
    } else {
        console.log('✓ STOMP library already loaded');
        connectWebSocket();
    }
}

function connectWebSocket() {
    try {
        if (!conversationId) {
            console.error('Cannot connect WebSocket: conversationId is missing');
            return;
        }
        
        // Disconnect existing connection if any
        if (stompClient && wsConnected) {
            console.log('Disconnecting existing WebSocket connection');
            try {
                if (wsSubscription) {
                    wsSubscription.unsubscribe();
                    wsSubscription = null;
                }
                stompClient.disconnect();
            } catch (e) {
                console.error('Error disconnecting:', e);
            }
            wsConnected = false;
        }
        
        console.log('Creating SockJS connection to /ws');
        const socket = new SockJS('/ws');
        console.log('SockJS socket created:', socket);
        
        // Track socket state
        let socketOpened = false;
        let stompConnected = false;
        
        // Use the standard STOMP.js API (compatible with stompjs@2.3.3)
        stompClient = Stomp.over(socket);
        console.log('STOMP client created:', stompClient);
        
        // Enable debug logging to see what's happening
        stompClient.debug = function(str) {
            console.log('STOMP Debug:', str);
            // Check if connection is established in debug messages
            if (str && (str.includes('CONNECTED') || str.includes('connected'))) {
                console.log('✓ STOMP CONNECTED detected in debug');
                stompConnected = true;
            }
        };
        
        updateConnectionStatus('connecting', 'Connecting...');
        
        // Set connection timeout
        const connectionTimeout = setTimeout(function() {
            if (!wsConnected) {
                console.error('✗ WebSocket connection timeout after 10 seconds');
                console.error('Socket opened:', socketOpened);
                console.error('STOMP connected:', stompConnected);
                console.error('Socket readyState:', socket.readyState);
                updateConnectionStatus('error', 'Connection timeout');
                // Don't attempt reconnect immediately, let user see the error
            }
        }, 10000);
        
        // Connect with heartbeat configuration
        const connectHeaders = {
            // Add any headers if needed
        };
        
        console.log('Attempting STOMP connect...');
        stompClient.connect(connectHeaders, function(frame) {
            clearTimeout(connectionTimeout);
            console.log('WebSocket connected successfully!', frame);
            wsConnected = true;
            reconnectAttempts = 0; // Reset reconnect attempts on successful connection
            updateConnectionStatus('connecting', 'Subscribing...');
            
            const topic = '/topic/conversation/' + conversationId;
            console.log('Subscribing to: ' + topic);
            
            try {
                wsSubscription = stompClient.subscribe(topic, function(message) {
                    try {
                        console.log('=== WebSocket Message Received ===');
                        console.log('Raw message body:', message.body);
                        const chatMessage = JSON.parse(message.body);
                        console.log('Parsed WebSocket message:', chatMessage);
                        console.log('Message ID:', chatMessage.id);
                        console.log('Message Content:', chatMessage.content);
                        console.log('Sender:', chatMessage.senderUsername);
                        displayMessage(chatMessage);
                        console.log('=== Message Displayed ===');
                    } catch (e) {
                        console.error('Error parsing WebSocket message:', e);
                        console.error('Message body:', message.body);
                        console.error('Error stack:', e.stack);
                    }
                });
                
                if (wsSubscription) {
                    console.log('✓ Subscription created successfully!');
                    console.log('Subscription object:', wsSubscription);
                    console.log('Now listening for messages on:', topic);
                    updateConnectionStatus('connected', 'Connected');
                } else {
                    console.error('✗ Failed to create subscription - subscription is null/undefined');
                    wsConnected = false;
                    updateConnectionStatus('error', 'Subscription failed');
                }
            } catch (e) {
                console.error('✗ Error creating subscription:', e);
                console.error('Error stack:', e.stack);
                wsConnected = false;
                updateConnectionStatus('error', 'Connection error');
            }
        }, function(error) {
            clearTimeout(connectionTimeout);
            console.error('✗ STOMP connection error:', error);
            console.error('Error details:', JSON.stringify(error));
            if (error.headers) {
                console.error('Error headers:', error.headers);
            }
            wsConnected = false;
            updateConnectionStatus('error', 'Connection failed: ' + (error.message || 'Unknown error'));
            attemptReconnect();
        });
        
        // Handle WebSocket errors
        socket.onerror = function(error) {
            clearTimeout(connectionTimeout);
            console.error('SockJS error:', error);
            console.error('SockJS error type:', error.type);
            console.error('SockJS error target:', error.target);
            wsConnected = false;
            updateConnectionStatus('error', 'Socket error');
        };
        
        socket.onclose = function(event) {
            clearTimeout(connectionTimeout);
            console.log('WebSocket closed:', event.code, event.reason);
            console.log('Close event details:', {
                code: event.code,
                reason: event.reason,
                wasClean: event.wasClean
            });
            wsConnected = false;
            wsSubscription = null;
            
            if (event.code === 1000) {
                // Normal closure
                updateConnectionStatus('error', 'Disconnected');
            } else {
                updateConnectionStatus('error', 'Connection lost (code: ' + event.code + ')');
            }
            
            // Attempt to reconnect if page is still active
            attemptReconnect();
        };
        
        socket.onopen = function() {
            socketOpened = true;
            console.log('✓ SockJS connection opened');
            console.log('Socket readyState:', socket.readyState);
            updateConnectionStatus('connecting', 'Authenticating...');
        };
        
        // Additional connection state tracking
        if (socket.onconnecting) {
            socket.onconnecting = function() {
                console.log('SockJS connecting...');
            };
        }
        
        // Monitor socket state periodically
        const socketStateCheck = setInterval(function() {
            if (socket.readyState !== undefined) {
                const states = ['CONNECTING', 'OPEN', 'CLOSING', 'CLOSED'];
                console.log('Socket state:', states[socket.readyState] || socket.readyState);
            }
            if (wsConnected) {
                clearInterval(socketStateCheck);
            }
        }, 2000);
        
    } catch (error) {
        console.error('Error initializing WebSocket:', error);
        console.error('Error stack:', error.stack);
        wsConnected = false;
        attemptReconnect();
    }
}

function attemptReconnect() {
    if (reconnectAttempts >= MAX_RECONNECT_ATTEMPTS) {
        console.error('Max reconnection attempts reached. WebSocket will not reconnect automatically.');
        return;
    }
    
    reconnectAttempts++;
    const delay = RECONNECT_DELAY * reconnectAttempts; // Exponential backoff
    console.log(`Attempting to reconnect WebSocket (attempt ${reconnectAttempts}/${MAX_RECONNECT_ATTEMPTS}) in ${delay}ms...`);
    
    setTimeout(function() {
        if (!wsConnected && conversationId) {
            console.log('Reconnecting WebSocket...');
            connectWebSocket();
        }
    }, delay);
}

function handleMessageSubmit(e) {
    if (e) {
        e.preventDefault();
        e.stopPropagation();
    }
    
    // Prevent duplicate submissions
    if (isSending) {
        console.log('Message already being sent, ignoring duplicate submission');
        return false;
    }
    
    console.log('handleMessageSubmit called');
    
    const form = document.getElementById('messageForm');
    const messageInput = document.getElementById('messageInput');
    
    if (!messageInput) {
        console.error('Message input not found!');
        return false;
    }
    
    const content = messageInput.value.trim();
    
    if (!content) {
        console.log('Empty message, ignoring');
        return false;
    }
    
    if (!conversationId || !currentUserId) {
        console.error('Missing conversationId or currentUserId', {conversationId, currentUserId});
        alert('Error: Missing conversation or user information. Please refresh the page.');
        return false;
    }
    
    // Set sending flag
    isSending = true;
    
    // Disable form while sending
    const submitButton = form ? form.querySelector('button[type="submit"]') : document.querySelector('#messageForm button[type="submit"]');
    const originalButtonText = submitButton ? submitButton.textContent : 'Send';
    
    if (submitButton) {
        submitButton.disabled = true;
        submitButton.textContent = 'Sending...';
    }
    
    console.log('Sending message:', {content, conversationId, currentUserId});
    
    // Create form data
    const formData = new FormData();
    formData.append('conversationId', conversationId);
    formData.append('content', content);
    
    // Send via HTTP POST
    fetch('/message/send', {
        method: 'POST',
        body: formData
    })
    .then(response => {
        console.log('Response status:', response.status, response.statusText);
        if (!response.ok) {
            return response.json().then(err => {
                throw new Error(err.error || 'Network response was not ok');
            }).catch(() => {
                throw new Error('Network response was not ok: ' + response.status);
            });
        }
        return response.json();
    })
    .then(data => {
        console.log('Message sent successfully:', data);
        if (data.error) {
            console.error('Error sending message:', data.error);
            alert('Error sending message: ' + data.error);
        } else {
            // Display the message immediately
            displayMessage({
                id: data.id,
                content: data.content,
                senderId: data.senderId,
                senderUsername: data.senderUsername,
                createdAt: data.createdAt
            });
            messageInput.value = '';
            console.log('Message displayed and input cleared');
        }
    })
    .catch(error => {
        console.error('Error sending message:', error);
        alert('Error sending message: ' + (error.message || error));
    })
    .finally(() => {
        // Reset sending flag
        isSending = false;
        
        if (submitButton) {
            submitButton.disabled = false;
            submitButton.textContent = originalButtonText;
        }
        if (messageInput) {
            messageInput.focus();
        }
    });
    
    return false;
}

function displayMessage(message) {
    console.log('Displaying message:', message);
    const messagesContainer = document.getElementById('chatMessages');
    if (!messagesContainer) {
        console.error('Messages container not found!');
        return;
    }
    
    // Check if message already exists to avoid duplicates
    if (message.id) {
        const existingMessage = messagesContainer.querySelector(`[data-message-id="${message.id}"]`);
        if (existingMessage) {
            console.log('Message already displayed, skipping:', message.id);
            return; // Message already displayed
        }
    } else {
        // If message doesn't have an ID, check by content and sender to avoid duplicates
        const existingMessages = messagesContainer.querySelectorAll('.message');
        for (let existingMsg of existingMessages) {
            const msgContent = existingMsg.querySelector('.message-content')?.textContent;
            const msgSender = existingMsg.querySelector('.message-sender')?.textContent;
            if (msgContent === message.content && msgSender === (message.senderUsername || 'Unknown')) {
                console.log('Duplicate message detected by content, skipping');
                return;
            }
        }
    }
    
    const messageDiv = document.createElement('div');
    const isSent = message.senderId === currentUserId;
    messageDiv.className = `message ${isSent ? 'message-sent' : 'message-received'}`;
    if (message.id) {
        messageDiv.setAttribute('data-message-id', message.id);
    }
    
    let time;
    try {
        // Handle different date formats
        let dateObj;
        if (message.createdAt) {
            if (typeof message.createdAt === 'string') {
                // Try parsing ISO string or other formats
                dateObj = new Date(message.createdAt);
                // If parsing failed, try to parse as LocalDateTime format
                if (isNaN(dateObj.getTime())) {
                    // Try parsing as "2024-01-01T12:00:00" format
                    const dateStr = message.createdAt.replace(' ', 'T');
                    dateObj = new Date(dateStr);
                }
            } else {
                dateObj = new Date(message.createdAt);
            }
            
            if (isNaN(dateObj.getTime())) {
                throw new Error('Invalid date');
            }
            
            time = dateObj.toLocaleTimeString('en-US', {
                hour: '2-digit',
                minute: '2-digit'
            });
        } else {
            throw new Error('No date provided');
        }
    } catch (e) {
        console.error('Error parsing date:', message.createdAt, e);
        time = new Date().toLocaleTimeString('en-US', {
            hour: '2-digit',
            minute: '2-digit'
        });
    }
    
    // Only show avatar for received messages (not own messages)
    let avatarHtml = '';
    if (!isSent) {
        if (message.senderProfilePicture) {
            avatarHtml = `<div class="message-avatar">
                <div class="avatar-img">
                    <img src="/uploads/profile-pictures/${escapeHtml(message.senderProfilePicture)}" 
                         alt="Profile Picture" 
                         style="width: 40px; height: 40px; border-radius: 50%; object-fit: cover;">
                </div>
            </div>`;
        } else {
            const initial = (message.senderUsername || 'U').charAt(0).toUpperCase();
            avatarHtml = `<div class="message-avatar">
                <div class="avatar-placeholder">${initial}</div>
            </div>`;
        }
    }
    
    messageDiv.innerHTML = `
        ${avatarHtml}
        <div class="message-body">
            <div class="message-header">
                <span class="message-sender">${escapeHtml(message.senderUsername || 'Unknown')}</span>
                <span class="message-time">${time}</span>
            </div>
            <div class="message-content">${escapeHtml(message.content || '')}</div>
        </div>
    `;
    
    messagesContainer.appendChild(messageDiv);
    scrollToBottom();
    console.log('Message displayed successfully');
}

function pollMessages() {
    if (!conversationId) return;
    
    fetch(`/message/conversation/${conversationId}`)
        .then(response => response.json())
        .then(messages => {
            const messagesContainer = document.getElementById('chatMessages');
            if (!messagesContainer) return;
            
            const currentMessageIds = Array.from(messagesContainer.querySelectorAll('.message'))
                .map(msg => {
                    const id = msg.getAttribute('data-message-id');
                    return id ? parseInt(id) : null;
                })
                .filter(id => id !== null);
            
            messages.forEach(message => {
                if (!currentMessageIds.includes(message.id)) {
                    displayMessage({
                        id: message.id,
                        content: message.content,
                        senderId: message.senderId,
                        senderUsername: message.senderUsername,
                        senderProfilePicture: message.senderProfilePicture,
                        createdAt: message.createdAt
                    });
                }
            });
        })
        .catch(error => {
            console.error('Error polling messages:', error);
        });
}

function updateConnectionStatus(status, text) {
    const indicator = document.getElementById('statusIndicator');
    const statusText = document.getElementById('statusText');
    
    if (indicator && statusText) {
        statusText.textContent = text;
        switch(status) {
            case 'connected':
                indicator.style.backgroundColor = '#4caf50';
                break;
            case 'connecting':
                indicator.style.backgroundColor = '#ff9800';
                break;
            case 'error':
                indicator.style.backgroundColor = '#f44336';
                break;
            default:
                indicator.style.backgroundColor = '#ccc';
        }
    }
}

function scrollToBottom() {
    const messagesContainer = document.getElementById('chatMessages');
    if (messagesContainer) {
        messagesContainer.scrollTop = messagesContainer.scrollHeight;
    }
}

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// Expose test function to window for debugging
window.testWebSocketConnection = function() {
    console.log('=== Testing WebSocket Connection ===');
    console.log('Conversation ID:', conversationId);
    console.log('Current User ID:', currentUserId);
    console.log('WebSocket Connected:', wsConnected);
    console.log('STOMP Client:', stompClient);
    console.log('Subscription:', wsSubscription);
    console.log('SockJS available:', typeof SockJS !== 'undefined');
    console.log('STOMP available:', typeof Stomp !== 'undefined');
    
    // Test if WebSocket endpoint is reachable
    if (typeof SockJS !== 'undefined') {
        console.log('Testing WebSocket endpoint...');
        const testSocket = new SockJS('/ws');
        testSocket.onopen = function() {
            console.log('✓ WebSocket endpoint is reachable');
            testSocket.close();
        };
        testSocket.onerror = function(error) {
            console.error('✗ WebSocket endpoint error:', error);
        };
        testSocket.onclose = function(event) {
            console.log('Test socket closed:', event.code);
        };
    }
    
    if (!wsConnected) {
        console.log('WebSocket not connected, attempting to connect...');
        connectWebSocket();
    } else {
        console.log('WebSocket is connected!');
    }
};

// Test endpoint accessibility on page load
window.testEndpointAccess = function() {
    fetch('/ws/info', { method: 'GET' })
        .then(response => {
            console.log('WebSocket info endpoint response:', response.status);
            return response.text();
        })
        .then(data => {
            console.log('WebSocket info:', data);
        })
        .catch(error => {
            console.error('Error accessing WebSocket info:', error);
        });
};

// Log connection status periodically
setInterval(function() {
    if (conversationId) {
        console.log('Connection status check - Connected:', wsConnected, 'Conversation:', conversationId);
    }
}, 10000); // Every 10 seconds
