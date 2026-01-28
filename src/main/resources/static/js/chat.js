// Chat functionality with WebSocket support using STOMP

let stompClient = null;
let conversationId = null;
let currentUserId = null;
let isSending = false; // Flag to prevent duplicate submissions

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
    
    // Initialize WebSocket connection
    initializeWebSocket();
    
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

// Auto-initialize when DOM is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', window.initializeChat);
} else {
    // DOM is already loaded
    window.initializeChat();
}

function initializeWebSocket() {
    // Load SockJS and STOMP from CDN if not already loaded
    if (typeof SockJS === 'undefined') {
        const sockjsScript = document.createElement('script');
        sockjsScript.src = 'https://cdn.jsdelivr.net/npm/sockjs-client@1/dist/sockjs.min.js';
        sockjsScript.onload = function() {
            loadStomp();
        };
        document.head.appendChild(sockjsScript);
    } else {
        loadStomp();
    }
}

function loadStomp() {
    if (typeof Stomp === 'undefined') {
        const stompScript = document.createElement('script');
        stompScript.src = 'https://cdn.jsdelivr.net/npm/@stomp/stompjs@7/bundles/stomp.umd.min.js';
        stompScript.onload = connectWebSocket;
        document.head.appendChild(stompScript);
    } else {
        connectWebSocket();
    }
}

function connectWebSocket() {
    const socket = new SockJS('/ws');
    stompClient = Stomp.over(socket);
    
    stompClient.connect({}, function(frame) {
        console.log('Connected: ' + frame);
        
        stompClient.subscribe('/topic/conversation/' + conversationId, function(message) {
            const chatMessage = JSON.parse(message.body);
            displayMessage(chatMessage);
        });
    }, function(error) {
        console.error('STOMP error:', error);
        // Fallback to polling
    });
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
    }
    
    const messageDiv = document.createElement('div');
    const isSent = message.senderId === currentUserId;
    messageDiv.className = `message ${isSent ? 'message-sent' : 'message-received'}`;
    if (message.id) {
        messageDiv.setAttribute('data-message-id', message.id);
    }
    
    let time;
    try {
        time = new Date(message.createdAt).toLocaleTimeString('en-US', {
            hour: '2-digit',
            minute: '2-digit'
        });
    } catch (e) {
        console.error('Error parsing date:', message.createdAt, e);
        time = new Date().toLocaleTimeString('en-US', {
            hour: '2-digit',
            minute: '2-digit'
        });
    }
    
    messageDiv.innerHTML = `
        <div class="message-header">
            <span class="message-sender">${escapeHtml(message.senderUsername || 'Unknown')}</span>
            <span class="message-time">${time}</span>
        </div>
        <div class="message-content">${escapeHtml(message.content || '')}</div>
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
                        senderId: message.sender.id,
                        senderUsername: message.sender.username,
                        createdAt: message.createdAt
                    });
                }
            });
        })
        .catch(error => {
            console.error('Error polling messages:', error);
        });
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
