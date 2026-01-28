package com.messenger.app.controller;

import com.messenger.app.dto.ChatMessage;
import com.messenger.app.model.Message;
import com.messenger.app.service.MessageService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.messaging.handler.annotation.DestinationVariable;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.SendTo;
import org.springframework.stereotype.Controller;

@Controller
public class WebSocketController {
    
    @Autowired
    private MessageService messageService;
    
    @MessageMapping("/chat/{conversationId}")
    @SendTo("/topic/conversation/{conversationId}")
    public ChatMessage sendMessage(@DestinationVariable Long conversationId, 
                                  ChatMessage chatMessage) {
        // Save message to database
        Message message = messageService.sendMessage(
            chatMessage.getSenderId(),
            conversationId,
            chatMessage.getContent()
        );
        
        // Convert to DTO and broadcast
        ChatMessage response = new ChatMessage(
            message.getId(),
            message.getContent(),
            message.getSender().getId(),
            message.getSender().getUsername(),
            message.getSender().getProfilePicture(),
            conversationId,
            message.getCreatedAt()
        );
        
        return response;
    }
}
