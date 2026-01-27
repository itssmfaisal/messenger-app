// Chat functionality with WebSocket support using STOMP

let stompClient = null;
let conversationId = null;
let currentUserId = null;

document.addEventListener('DOMContentLoaded', function() {
    // Get conversation ID and user ID from script tag
    const scriptTag = document.querySelector('script');
    if (scriptTag && scriptTag.textContent) {
        const match = scriptTag.textContent.match(/conversationId = (\d+)/);
        if (match) {
            conversationId = parseInt(match[1]);
        }
        const userIdMatch = scriptTag.textContent.match(/currentUserId = (\d+)/);
        if (userIdMatch) {
            currentUserId = parseInt(userIdMatch[1]);
        }
    }
    
    // Initialize WebSocket connection
    initializeWebSocket();
    
    // Setup message form
    const messageForm = document.getElementById('messageForm');
    if (messageForm) {
        messageForm.addEventListener('submit', handleMessageSubmit);
    }
    
    // Auto-scroll to bottom on load
    scrollToBottom();
    
    // Poll for new messages every 3 seconds (fallback if WebSocket fails)
    setInterval(pollMessages, 3000);
});

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
    e.preventDefault();
    
    const form = e.target;
    const messageInput = document.getElementById('messageInput');
    const content = messageInput.value.trim();
    
    if (!content) {
        return;
    }
    
    // Disable form while sending
    form.querySelector('button').disabled = true;
    
    // Try to send via WebSocket first
    if (stompClient && stompClient.connected) {
        const chatMessage = {
            content: content,
            senderId: currentUserId,
            conversationId: conversationId
        };
        
        stompClient.send('/app/chat/' + conversationId, {}, JSON.stringify(chatMessage));
        messageInput.value = '';
        form.querySelector('button').disabled = false;
        messageInput.focus();
    } else {
        // Fallback to HTTP POST
        const formData = new FormData(form);
        fetch('/message/send', {
            method: 'POST',
            body: formData
        })
        .then(response => response.json())
        .then(data => {
            if (data.error) {
                console.error('Error sending message:', data.error);
            } else {
                messageInput.value = '';
            }
        })
        .catch(error => {
            console.error('Error:', error);
        })
        .finally(() => {
            form.querySelector('button').disabled = false;
            messageInput.focus();
        });
    }
}

function displayMessage(message) {
    const messagesContainer = document.getElementById('chatMessages');
    if (!messagesContainer) return;
    
    const messageDiv = document.createElement('div');
    const isSent = message.senderId === currentUserId;
    messageDiv.className = `message ${isSent ? 'message-sent' : 'message-received'}`;
    
    const time = new Date(message.createdAt).toLocaleTimeString('en-US', {
        hour: '2-digit',
        minute: '2-digit'
    });
    
    messageDiv.innerHTML = `
        <div class="message-header">
            <span class="message-sender">${escapeHtml(message.senderUsername)}</span>
            <span class="message-time">${time}</span>
        </div>
        <div class="message-content">${escapeHtml(message.content)}</div>
    `;
    
    messagesContainer.appendChild(messageDiv);
    scrollToBottom();
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
                    const id = msg.dataset.messageId;
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
