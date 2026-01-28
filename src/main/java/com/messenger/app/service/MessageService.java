package com.messenger.app.service;

import com.messenger.app.model.Message;
import com.messenger.app.model.Conversation;
import com.messenger.app.model.User;
import com.messenger.app.repository.MessageRepository;
import com.messenger.app.repository.ConversationRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;
import java.util.Optional;

@Service
@Transactional
public class MessageService {
    
    @Autowired
    private MessageRepository messageRepository;
    
    @Autowired
    private ConversationRepository conversationRepository;
    
    @Autowired
    private UserService userService;
    
    public Message sendMessage(Long senderId, Long conversationId, String content) {
        User sender = userService.findById(senderId).orElseThrow();
        Conversation conversation = conversationRepository.findById(conversationId).orElseThrow();
        
        Message message = new Message(content, sender, conversation);
        message = messageRepository.save(message);
        
        // Update conversation timestamp
        conversation.setUpdatedAt(java.time.LocalDateTime.now());
        conversationRepository.save(conversation);
        
        return message;
    }
    
    public List<Message> getConversationMessages(Long conversationId) {
        return messageRepository.findByConversationIdOrderByCreatedAtAsc(conversationId);
    }
    
    public Optional<Message> findById(Long id) {
        return messageRepository.findById(id);
    }
    
    public void markAsRead(Long messageId) {
        messageRepository.findById(messageId).ifPresent(message -> {
            message.setIsRead(true);
            messageRepository.save(message);
        });
    }
    
    public void markConversationAsRead(Long conversationId, Long userId) {
        List<Message> messages = messageRepository.findByConversationIdOrderByCreatedAtAsc(conversationId);
        messages.stream()
            .filter(m -> !m.getSender().getId().equals(userId) && !m.getIsRead())
            .forEach(m -> {
                m.setIsRead(true);
                messageRepository.save(m);
            });
    }
    
    public Long getUnreadCount(Long conversationId, Long userId) {
        return messageRepository.countUnreadMessages(conversationId, userId);
    }
    
    public long getTotalMessageCount() {
        return messageRepository.count();
    }
}
