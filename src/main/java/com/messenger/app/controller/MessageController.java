package com.messenger.app.controller;

import com.messenger.app.dto.ChatMessage;
import com.messenger.app.dto.MessageDTO;
import com.messenger.app.dto.ReadReceipt;
import com.messenger.app.model.Message;
import com.messenger.app.service.MessageService;
import jakarta.servlet.http.HttpSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Controller
public class MessageController {
    
    @Autowired
    private MessageService messageService;
    
    @Autowired
    private SimpMessagingTemplate messagingTemplate;
    
    @PostMapping("/message/send")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> sendMessage(@RequestParam Long conversationId,
                                                          @RequestParam String content,
                                                          HttpSession session) {
        Long userId = (Long) session.getAttribute("userId");
        if (userId == null) {
            Map<String, Object> error = new HashMap<>();
            error.put("error", "Not authenticated");
            return ResponseEntity.status(401).body(error);
        }
        
        Message message = messageService.sendMessage(userId, conversationId, content);
        
        Map<String, Object> response = new HashMap<>();
        response.put("id", message.getId());
        response.put("content", message.getContent());
        response.put("senderId", message.getSender().getId());
        response.put("senderUsername", message.getSender().getUsername());
        response.put("senderProfilePicture", message.getSender().getProfilePicture());
        response.put("isRead", message.getIsRead());
        response.put("createdAt", message.getCreatedAt().toString());
        
        // Broadcast message via WebSocket to all subscribers
        ChatMessage chatMessage = new ChatMessage(
            message.getId(),
            message.getContent(),
            message.getSender().getId(),
            message.getSender().getUsername(),
            message.getSender().getProfilePicture(),
            conversationId,
            message.getCreatedAt()
        );
        String destination = "/topic/conversation/" + conversationId;
        messagingTemplate.convertAndSend(destination, chatMessage);
        
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/message/conversation/{conversationId}")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> getMessages(
            @PathVariable Long conversationId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "50") int size,
            HttpSession session) {
        Long userId = (Long) session.getAttribute("userId");
        if (userId == null) {
            return ResponseEntity.status(401).build();
        }
        
        // For initial load (page 0), get latest messages
        List<Message> messages;
        boolean hasMore = false;
        
        if (page == 0) {
            // Load latest messages
            messages = messageService.getLatestMessages(conversationId, size);
            // Check if there are more messages
            var pageResult = messageService.getConversationMessagesPaginated(conversationId, 1, size);
            hasMore = pageResult.hasContent();
        } else {
            // Load older messages (pagination)
            var pageResult = messageService.getConversationMessagesPaginated(conversationId, page, size);
            messages = pageResult.getContent();
            // Reverse to get chronological order (oldest first)
            messages = messages.stream()
                .sorted((m1, m2) -> m1.getCreatedAt().compareTo(m2.getCreatedAt()))
                .collect(Collectors.toList());
            hasMore = pageResult.hasNext();
        }
        
        List<MessageDTO> messageDTOs = messages.stream()
            .map(msg -> new MessageDTO(
                msg.getId(),
                msg.getContent(),
                msg.getSender().getId(),
                msg.getSender().getUsername(),
                msg.getSender().getProfilePicture(),
                msg.getCreatedAt(),
                msg.getIsRead()
            ))
            .collect(Collectors.toList());
        
        Map<String, Object> response = new HashMap<>();
        response.put("messages", messageDTOs);
        response.put("hasMore", hasMore);
        response.put("page", page);
        
        return ResponseEntity.ok(response);
    }
    
    @PostMapping("/message/mark-read")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> markMessagesAsRead(
            @RequestParam Long conversationId,
            HttpSession session) {
        Long userId = (Long) session.getAttribute("userId");
        if (userId == null) {
            Map<String, Object> error = new HashMap<>();
            error.put("error", "Not authenticated");
            return ResponseEntity.status(401).body(error);
        }
        
        // Get unread messages before marking as read
        List<Message> unreadMessages = messageService.getUnreadMessages(conversationId, userId);
        
        // Mark all unread messages in the conversation as read
        messageService.markConversationAsRead(conversationId, userId);
        
        // Broadcast read receipts for all messages that were just marked as read
        String destination = "/topic/read-receipt/" + conversationId;
        for (Message message : unreadMessages) {
            ReadReceipt receipt = new ReadReceipt(
                message.getId(),
                conversationId,
                message.getSender().getId(),
                userId,
                true
            );
            messagingTemplate.convertAndSend(destination, receipt);
        }
        
        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("markedCount", unreadMessages.size());
        
        return ResponseEntity.ok(response);
    }
}
