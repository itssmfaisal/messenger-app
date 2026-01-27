package com.messenger.app.controller;

import com.messenger.app.model.Message;
import com.messenger.app.service.MessageService;
import jakarta.servlet.http.HttpSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Controller
public class MessageController {
    
    @Autowired
    private MessageService messageService;
    
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
        
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/message/conversation/{conversationId}")
    @ResponseBody
    public ResponseEntity<List<Message>> getMessages(@PathVariable Long conversationId,
                                                     HttpSession session) {
        Long userId = (Long) session.getAttribute("userId");
        if (userId == null) {
            return ResponseEntity.status(401).build();
        }
        
        List<Message> messages = messageService.getConversationMessages(conversationId);
        return ResponseEntity.ok(messages);
    }
}
