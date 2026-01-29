package com.messenger.app.service;

import com.messenger.app.model.Message;
import com.messenger.app.model.Conversation;
import com.messenger.app.model.User;
import com.messenger.app.repository.MessageRepository;
import com.messenger.app.repository.ConversationRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

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
    
    public Page<Message> getConversationMessagesPaginated(Long conversationId, int page, int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by("createdAt").descending());
        return messageRepository.findByConversationIdOrderByCreatedAtDesc(conversationId, pageable);
    }
    
    public List<Message> getLatestMessages(Long conversationId, int limit) {
        Pageable pageable = PageRequest.of(0, limit, Sort.by("createdAt").descending());
        Page<Message> page = messageRepository.findByConversationIdOrderByCreatedAtDesc(conversationId, pageable);
        // Reverse to get chronological order (oldest first)
        return page.getContent().stream()
            .sorted((m1, m2) -> m1.getCreatedAt().compareTo(m2.getCreatedAt()))
            .collect(Collectors.toList());
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
    
    public List<Message> getUnreadMessages(Long conversationId, Long userId) {
        return messageRepository.findByConversationIdOrderByCreatedAtAsc(conversationId).stream()
            .filter(m -> !m.getSender().getId().equals(userId) && !m.getIsRead())
            .collect(Collectors.toList());
    }
    
    public List<Message> getReadMessagesFromOthers(Long conversationId, Long userId) {
        return messageRepository.findByConversationIdOrderByCreatedAtAsc(conversationId).stream()
            .filter(m -> !m.getSender().getId().equals(userId) && m.getIsRead())
            .collect(Collectors.toList());
    }
    
    public Long getUnreadCount(Long conversationId, Long userId) {
        return messageRepository.countUnreadMessages(conversationId, userId);
    }
    
    public long getTotalMessageCount() {
        return messageRepository.count();
    }
}
