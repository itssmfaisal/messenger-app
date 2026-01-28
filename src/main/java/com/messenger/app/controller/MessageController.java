package com.messenger.app.controller;

import com.messenger.app.dto.ChatMessage;
import com.messenger.app.dto.MessageDTO;
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
        System.out.println("=== Broadcasting Message ===");
        System.out.println("Destination: " + destination);
        System.out.println("Message ID: " + chatMessage.getId());
        System.out.println("Message content: " + chatMessage.getContent());
        System.out.println("Sender ID: " + chatMessage.getSenderId());
        System.out.println("Sender Username: " + chatMessage.getSenderUsername());
        System.out.println("Conversation ID: " + chatMessage.getConversationId());
        System.out.println("Created At: " + chatMessage.getCreatedAt());
        try {
            messagingTemplate.convertAndSend(destination, chatMessage);
            System.out.println("✓ Message broadcasted successfully");
        } catch (Exception e) {
            System.err.println("✗ Error broadcasting message: " + e.getMessage());
            e.printStackTrace();
        }
        System.out.println("============================");
        
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/message/conversation/{conversationId}")
    @ResponseBody
    public ResponseEntity<List<MessageDTO>> getMessages(@PathVariable Long conversationId,
                                                         HttpSession session) {
        Long userId = (Long) session.getAttribute("userId");
        if (userId == null) {
            return ResponseEntity.status(401).build();
        }
        
        List<Message> messages = messageService.getConversationMessages(conversationId);
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
        
        return ResponseEntity.ok(messageDTOs);
    }
}
