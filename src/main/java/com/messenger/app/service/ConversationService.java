package com.messenger.app.service;

import com.messenger.app.model.Conversation;
import com.messenger.app.model.Participant;
import com.messenger.app.model.User;
import com.messenger.app.repository.ConversationRepository;
import com.messenger.app.repository.ParticipantRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@Transactional
public class ConversationService {
    
    @Autowired
    private ConversationRepository conversationRepository;
    
    @Autowired
    private ParticipantRepository participantRepository;
    
    @Autowired
    private UserService userService;
    
    public Conversation createDirectConversation(Long userId1, Long userId2) {
        // Check if conversation already exists
        Conversation existing = conversationRepository.findDirectConversation(userId1, userId2);
        if (existing != null) {
            return existing;
        }
        
        // Create new conversation
        User user1 = userService.findById(userId1).orElseThrow();
        User user2 = userService.findById(userId2).orElseThrow();
        
        String conversationName = user1.getUsername() + " & " + user2.getUsername();
        Conversation conversation = new Conversation(conversationName, false);
        conversation = conversationRepository.save(conversation);
        
        // Add participants
        Participant p1 = new Participant(user1, conversation);
        Participant p2 = new Participant(user2, conversation);
        participantRepository.save(p1);
        participantRepository.save(p2);
        
        return conversation;
    }
    
    public Conversation createGroupConversation(String name, List<Long> userIds) {
        Conversation conversation = new Conversation(name, true);
        conversation = conversationRepository.save(conversation);
        
        for (Long userId : userIds) {
            User user = userService.findById(userId).orElseThrow();
            Participant participant = new Participant(user, conversation);
            participantRepository.save(participant);
        }
        
        return conversation;
    }
    
    public List<Conversation> getUserConversations(Long userId) {
        return conversationRepository.findByUserId(userId);
    }
    
    public Optional<Conversation> findById(Long id) {
        return conversationRepository.findById(id);
    }
    
    public List<User> getConversationParticipants(Long conversationId, Long currentUserId) {
        return participantRepository.findOtherParticipants(conversationId, currentUserId)
            .stream()
            .map(Participant::getUser)
            .collect(Collectors.toList());
    }
    
    public String getConversationDisplayName(Conversation conversation, Long currentUserId) {
        if (conversation.getIsGroup()) {
            return conversation.getConversationName();
        } else {
            List<User> otherUsers = getConversationParticipants(conversation.getId(), currentUserId);
            if (!otherUsers.isEmpty()) {
                return otherUsers.get(0).getUsername();
            }
            return conversation.getConversationName();
        }
    }
    
    public void updateLastRead(Long userId, Long conversationId) {
        participantRepository.findByUserIdAndConversationId(userId, conversationId)
            .ifPresent(participant -> {
                participant.setLastReadAt(LocalDateTime.now());
                participantRepository.save(participant);
            });
    }
}
