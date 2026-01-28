// Chat functionality with WebSocket support using STOMP

let stompClient = null;
let conversationId = null;
let currentUserId = null;
let isSending = false;
let wsConnected = false;
let wsSubscription = null;
let reconnectAttempts = 0;
const MAX_RECONNECT_ATTEMPTS = 5;
const RECONNECT_DELAY = 3000;

// Pagination variables
let currentPage = 0;
let hasMoreMessages = true;
let isLoadingMessages = false;
const PAGE_SIZE = 50;

window.initializeChat = function() {
    if (window.conversationId) {
        conversationId = window.conversationId;
    }
    if (window.currentUserId) {
        currentUserId = window.currentUserId;
    }
    
    if (!conversationId || !currentUserId) {
        const scriptTags = document.querySelectorAll('script');
        for (let scriptTag of scriptTags) {
            if (scriptTag.textContent) {
                const match = scriptTag.textContent.match(/conversationId\s*=\s*(\d+)/);
                if (match) {
                    conversationId = parseInt(match[1]);
                }
                const userIdMatch = scriptTag.textContent.match(/currentUserId\s*=\s*(\d+)/);
                if (userIdMatch) {
                    currentUserId = parseInt(userIdMatch[1]);
                }
            }
        }
    }
    
    if (!conversationId || !currentUserId) {
        return;
    }
    
    initializeWebSocket();
    
    setInterval(function() {
        if (!wsConnected && conversationId) {
            connectWebSocket();
        }
    }, 5000);
    
    const messageForm = document.getElementById('messageForm');
    if (messageForm) {
        const newForm = messageForm.cloneNode(true);
        messageForm.parentNode.replaceChild(newForm, messageForm);
        document.getElementById('messageForm').addEventListener('submit', handleMessageSubmit);
    }
    
    scrollToBottom();
    loadInitialMessages();
    setupInfiniteScroll();
    markMessagesAsRead();
    setInterval(pollMessages, 3000);
    setInterval(markMessagesAsRead, 2000);
};

function waitForInitialization() {
    if (window.conversationId && window.currentUserId) {
        window.initializeChat();
    } else {
        setTimeout(waitForInitialization, 100);
    }
}

if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function() {
        setTimeout(waitForInitialization, 100);
    });
} else {
    setTimeout(waitForInitialization, 100);
}

function initializeWebSocket() {
    if (typeof SockJS === 'undefined') {
        const sockjsScript = document.createElement('script');
        sockjsScript.src = 'https://cdn.jsdelivr.net/npm/sockjs-client@1/dist/sockjs.min.js';
        sockjsScript.onload = function() {
            loadStomp();
        };
        sockjsScript.onerror = function() {
            updateConnectionStatus('error', 'Failed to load SockJS');
        };
        document.head.appendChild(sockjsScript);
    } else {
        loadStomp();
    }
}

function loadStomp() {
    if (typeof Stomp === 'undefined') {
        const stompScript = document.createElement('script');
        stompScript.src = 'https://cdn.jsdelivr.net/npm/stompjs@2.3.3/lib/stomp.min.js';
        stompScript.onload = function() {
            setTimeout(function() {
                if (typeof Stomp !== 'undefined') {
                    connectWebSocket();
                } else {
                    updateConnectionStatus('error', 'STOMP failed to load');
                }
            }, 100);
        };
        stompScript.onerror = function() {
            updateConnectionStatus('error', 'Failed to load STOMP');
        };
        document.head.appendChild(stompScript);
    } else {
        connectWebSocket();
    }
}

function connectWebSocket() {
    try {
        if (!conversationId) {
            return;
        }
        
        if (stompClient && (stompClient.connected || wsConnected)) {
            if (wsSubscription) {
                wsSubscription.unsubscribe();
                wsSubscription = null;
            }
            try {
                stompClient.disconnect();
            } catch (e) {}
            wsConnected = false;
        }
        
        const socket = new SockJS('/ws');
        stompClient = Stomp.over(socket);
        
        stompClient.debug = function(str) {
            if (str && (str.includes('CONNECTED') || str.includes('connected'))) {
                stompConnected = true;
            }
        };
        
        updateConnectionStatus('connecting', 'Connecting...');
        
        const connectionTimeout = setTimeout(function() {
            if (!wsConnected) {
                updateConnectionStatus('error', 'Connection timeout');
                attemptReconnect();
            }
        }, 10000);
        
        const connectHeaders = {};
        
        stompClient.connect(connectHeaders, function(frame) {
            clearTimeout(connectionTimeout);
            wsConnected = true;
            reconnectAttempts = 0;
            updateConnectionStatus('connecting', 'Subscribing...');
            
            const topic = '/topic/conversation/' + conversationId;
            
            try {
                wsSubscription = stompClient.subscribe(topic, function(message) {
                    try {
                        const chatMessage = JSON.parse(message.body);
                        displayMessage(chatMessage);
                        
                        if (chatMessage.senderId !== currentUserId) {
                            setTimeout(markMessagesAsRead, 500);
                        }
                    } catch (e) {
                        console.error('Error parsing WebSocket message:', e);
                    }
                });
                
                const readReceiptTopic = '/topic/read-receipt/' + conversationId;
                stompClient.subscribe(readReceiptTopic, function(receipt) {
                    try {
                        const readReceipt = JSON.parse(receipt.body);
                        if (readReceipt.senderId === currentUserId) {
                            updateMessageReadStatus(readReceipt.messageId, readReceipt.isRead);
                        }
                    } catch (e) {
                        console.error('Error parsing read receipt:', e);
                    }
                });
                
                if (wsSubscription) {
                    updateConnectionStatus('connected', 'Connected');
                } else {
                    wsConnected = false;
                    updateConnectionStatus('error', 'Subscription failed');
                }
            } catch (e) {
                wsConnected = false;
                updateConnectionStatus('error', 'Connection error');
            }
        }, function(error) {
            clearTimeout(connectionTimeout);
            wsConnected = false;
            updateConnectionStatus('error', 'Connection failed');
            attemptReconnect();
        });
        
        socket.onopen = function() {
            updateConnectionStatus('connecting', 'Authenticating...');
        };
        
        socket.onclose = function(event) {
            wsConnected = false;
            wsSubscription = null;
            
            if (event.code === 1000) {
                updateConnectionStatus('error', 'Disconnected');
            } else {
                updateConnectionStatus('error', 'Connection lost');
            }
            
            attemptReconnect();
        };
        
        socket.onerror = function(error) {
            wsConnected = false;
            updateConnectionStatus('error', 'Socket error');
        };
        
    } catch (error) {
        wsConnected = false;
        updateConnectionStatus('error', 'Initialization error');
        attemptReconnect();
    }
}

function attemptReconnect() {
    if (reconnectAttempts >= MAX_RECONNECT_ATTEMPTS) {
        updateConnectionStatus('error', 'Max reconnection attempts reached');
        return;
    }
    
    reconnectAttempts++;
    updateConnectionStatus('error', 'Reconnecting... (' + reconnectAttempts + '/' + MAX_RECONNECT_ATTEMPTS + ')');
    
    setTimeout(function() {
        if (!wsConnected && conversationId) {
            connectWebSocket();
        }
    }, RECONNECT_DELAY);
}

function updateConnectionStatus(status, message) {
    const statusIndicator = document.getElementById('statusIndicator');
    const statusText = document.getElementById('statusText');
    
    if (statusIndicator && statusText) {
        if (status === 'connected') {
            statusIndicator.style.backgroundColor = '#28a745';
        } else if (status === 'connecting') {
            statusIndicator.style.backgroundColor = '#ffc107';
        } else {
            statusIndicator.style.backgroundColor = '#dc3545';
        }
        statusText.textContent = message;
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

function handleMessageSubmit(e) {
    if (e) {
        e.preventDefault();
        e.stopPropagation();
    }
    
    if (isSending) {
        return false;
    }
    
    const form = document.getElementById('messageForm');
    const messageInput = document.getElementById('messageInput');
    
    if (!messageInput) {
        return false;
    }
    
    const content = messageInput.value.trim();
    
    if (!content) {
        return false;
    }
    
    if (!conversationId || !currentUserId) {
        alert('Error: Missing conversation or user information. Please refresh the page.');
        return false;
    }
    
    isSending = true;
    
    const submitButton = form ? form.querySelector('button[type="submit"]') : document.querySelector('#messageForm button[type="submit"]');
    const originalButtonText = submitButton ? submitButton.textContent : 'Send';
    
    if (submitButton) {
        submitButton.disabled = true;
        submitButton.textContent = 'Sending...';
    }
    
    const formData = new FormData();
    formData.append('conversationId', conversationId);
    formData.append('content', content);
    
    fetch('/message/send', {
        method: 'POST',
        body: formData
    })
    .then(response => {
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
        if (data.error) {
            alert('Error sending message: ' + data.error);
        } else {
            displayMessage({
                id: data.id,
                content: data.content,
                senderId: data.senderId,
                senderUsername: data.senderUsername,
                senderProfilePicture: data.senderProfilePicture,
                isRead: false,
                createdAt: data.createdAt
            });
            messageInput.value = '';
        }
    })
    .catch(error => {
        alert('Error sending message: ' + (error.message || error));
    })
    .finally(() => {
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
    const messagesContainer = document.getElementById('chatMessages');
    if (!messagesContainer) {
        return;
    }
    
    if (message.id) {
        const existingMessage = messagesContainer.querySelector(`[data-message-id="${message.id}"]`);
        if (existingMessage) {
            return;
        }
    } else {
        const existingMessages = messagesContainer.querySelectorAll('.message');
        for (let existingMsg of existingMessages) {
            const msgContent = existingMsg.querySelector('.message-content')?.textContent;
            const msgSender = existingMsg.querySelector('.message-sender')?.textContent;
            if (msgContent === message.content && msgSender === (message.senderUsername || 'Unknown')) {
                return;
            }
        }
    }
    
    const messageDiv = createMessageElement(message);
    messagesContainer.appendChild(messageDiv);
    scrollToBottom();
}

function loadInitialMessages() {
    if (!conversationId) return;
    
    currentPage = 0;
    hasMoreMessages = true;
    
    fetch(`/message/conversation/${conversationId}?page=0&size=${PAGE_SIZE}`)
        .then(response => response.json())
        .then(data => {
            const messages = data.messages || [];
            hasMoreMessages = data.hasMore || false;
            
            const messagesContainer = document.getElementById('chatMessages');
            if (!messagesContainer) return;
            
            messages.forEach(message => {
                displayMessage({
                    id: message.id,
                    content: message.content,
                    senderId: message.senderId,
                    senderUsername: message.senderUsername,
                    senderProfilePicture: message.senderProfilePicture,
                    isRead: message.isRead,
                    createdAt: message.createdAt
                });
            });
            
            setTimeout(scrollToBottom, 100);
            setTimeout(markMessagesAsRead, 300);
            setTimeout(updateAllSentMessagesStatus, 500);
        })
        .catch(error => {
            console.error('Error loading initial messages:', error);
        });
}

function loadOlderMessages() {
    if (!conversationId || isLoadingMessages || !hasMoreMessages) {
        return;
    }
    
    isLoadingMessages = true;
    const nextPage = currentPage + 1;
    const messagesContainer = document.getElementById('chatMessages');
    if (!messagesContainer) {
        isLoadingMessages = false;
        return;
    }
    
    const scrollHeight = messagesContainer.scrollHeight;
    const scrollTop = messagesContainer.scrollTop;
    
    fetch(`/message/conversation/${conversationId}?page=${nextPage}&size=${PAGE_SIZE}`)
        .then(response => response.json())
        .then(data => {
            const messages = data.messages || [];
            hasMoreMessages = data.hasMore || false;
            currentPage = nextPage;
            
            if (messages.length > 0) {
                const firstMessage = messagesContainer.querySelector('.message');
                
                messages.forEach(message => {
                    const messageDiv = createMessageElement({
                        id: message.id,
                        content: message.content,
                        senderId: message.senderId,
                        senderUsername: message.senderUsername,
                        senderProfilePicture: message.senderProfilePicture,
                        isRead: message.isRead,
                        createdAt: message.createdAt
                    });
                    
                    if (firstMessage) {
                        messagesContainer.insertBefore(messageDiv, firstMessage);
                    } else {
                        messagesContainer.appendChild(messageDiv);
                    }
                });
                
                const newScrollHeight = messagesContainer.scrollHeight;
                messagesContainer.scrollTop = scrollTop + (newScrollHeight - scrollHeight);
            }
            
            isLoadingMessages = false;
        })
        .catch(error => {
            console.error('Error loading older messages:', error);
            isLoadingMessages = false;
        });
}

function setupInfiniteScroll() {
    const messagesContainer = document.getElementById('chatMessages');
    if (!messagesContainer) return;
    
    messagesContainer.addEventListener('scroll', function() {
        if (messagesContainer.scrollTop < 200 && hasMoreMessages && !isLoadingMessages) {
            loadOlderMessages();
        }
    });
}

function createMessageElement(message) {
    const messageDiv = document.createElement('div');
    const isSent = message.senderId === currentUserId;
    messageDiv.className = `message ${isSent ? 'message-sent' : 'message-received'}`;
    if (message.id) {
        messageDiv.setAttribute('data-message-id', message.id);
    }
    
    let time;
    try {
        let dateObj;
        if (message.createdAt) {
            if (typeof message.createdAt === 'string') {
                dateObj = new Date(message.createdAt);
                if (isNaN(dateObj.getTime())) {
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
        time = new Date().toLocaleTimeString('en-US', {
            hour: '2-digit',
            minute: '2-digit'
        });
    }
    
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
    
    let statusHtml = '';
    if (isSent) {
        const isRead = message.isRead || false;
        if (isRead) {
            statusHtml = '<div class="message-status"><span class="seen-indicator">Seen</span></div>';
        } else {
            statusHtml = '<div class="message-status"><span class="sent-indicator">Sent</span></div>';
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
            ${statusHtml}
        </div>
    `;
    
    return messageDiv;
}

function markMessagesAsRead() {
    if (!conversationId) return;
    
    fetch(`/message/mark-read?conversationId=${conversationId}`, {
        method: 'POST'
    })
    .then(response => response.json())
    .then(data => {
        // Read receipts will be broadcast via WebSocket
    })
    .catch(error => {
        console.error('Error marking messages as read:', error);
    });
}

function updateMessageReadStatus(messageId, isRead) {
    const messagesContainer = document.getElementById('chatMessages');
    if (!messagesContainer) return;
    
    const messageElement = messagesContainer.querySelector(`[data-message-id="${messageId}"]`);
    if (!messageElement) return;
    
    if (!messageElement.classList.contains('message-sent')) return;
    
    let statusElement = messageElement.querySelector('.message-status');
    if (!statusElement) {
        const messageBody = messageElement.querySelector('.message-body');
        if (messageBody) {
            statusElement = document.createElement('div');
            statusElement.className = 'message-status';
            messageBody.appendChild(statusElement);
        } else {
            return;
        }
    }
    
    if (isRead) {
        statusElement.innerHTML = '<span class="seen-indicator">Seen</span>';
    } else {
        statusElement.innerHTML = '<span class="sent-indicator">Sent</span>';
    }
}

function updateAllSentMessagesStatus() {
    if (!conversationId) return;
    
    const messagesContainer = document.getElementById('chatMessages');
    if (!messagesContainer) return;
    
    const sentMessages = messagesContainer.querySelectorAll('.message-sent');
    
    fetch(`/message/conversation/${conversationId}?page=0&size=${PAGE_SIZE}`)
        .then(response => response.json())
        .then(data => {
            const messages = data.messages || [];
            const messageStatusMap = new Map();
            
            messages.forEach(message => {
                if (message.senderId === currentUserId) {
                    messageStatusMap.set(message.id, message.isRead || false);
                }
            });
            
            sentMessages.forEach(messageElement => {
                const messageId = parseInt(messageElement.getAttribute('data-message-id'));
                if (messageId && messageStatusMap.has(messageId)) {
                    const isRead = messageStatusMap.get(messageId);
                    updateMessageReadStatus(messageId, isRead);
                }
            });
        })
        .catch(error => {
            console.error('Error updating message statuses:', error);
        });
}

function pollMessages() {
    if (!conversationId) return;
    
    fetch(`/message/conversation/${conversationId}?page=0&size=${PAGE_SIZE}`)
        .then(response => response.json())
        .then(data => {
            const messages = data.messages || [];
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
                        isRead: message.isRead,
                        createdAt: message.createdAt
                    });
                }
            });
            
            markMessagesAsRead();
        })
        .catch(error => {
            console.error('Error polling messages:', error);
        });
}
