package com.messenger.app.controller;

import com.messenger.app.model.Conversation;
import com.messenger.app.model.User;
import com.messenger.app.service.ConversationService;
import com.messenger.app.service.MessageService;
import com.messenger.app.service.UserService;
import jakarta.servlet.http.HttpSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.util.List;

@Controller
public class ConversationController {
    
    @Autowired
    private ConversationService conversationService;
    
    @Autowired
    private MessageService messageService;
    
    @Autowired
    private UserService userService;
    
    @GetMapping("/conversations")
    public String conversations(HttpSession session, Model model) {
        Long userId = (Long) session.getAttribute("userId");
        if (userId == null) {
            return "redirect:/login";
        }
        
        String username = (String) session.getAttribute("username");
        List<Conversation> conversations = conversationService.getUserConversations(userId);
        
        // Check if user is admin
        boolean isAdmin = userService.findById(userId)
            .map(user -> user.getIsAdmin() != null && user.getIsAdmin())
            .orElse(false);
        
        model.addAttribute("conversations", conversations);
        model.addAttribute("currentUserId", userId);
        model.addAttribute("username", username);
        model.addAttribute("conversationService", conversationService);
        model.addAttribute("messageService", messageService);
        model.addAttribute("isAdmin", isAdmin);
        
        return "conversations";
    }
    
    @GetMapping("/conversation/{id}")
    public String viewConversation(@PathVariable Long id,
                                  HttpSession session,
                                  Model model) {
        Long userId = (Long) session.getAttribute("userId");
        if (userId == null) {
            return "redirect:/login";
        }
        
        String username = (String) session.getAttribute("username");
        Conversation conversation = conversationService.findById(id)
            .orElseThrow(() -> new RuntimeException("Conversation not found"));
        
        // Mark messages as read
        messageService.markConversationAsRead(id, userId);
        
        List<com.messenger.app.model.Message> messages = messageService.getConversationMessages(id);
        List<User> participants = conversationService.getConversationParticipants(id, userId);
        
        // Check if user is admin
        boolean isAdmin = userService.findById(userId)
            .map(user -> user.getIsAdmin() != null && user.getIsAdmin())
            .orElse(false);
        
        model.addAttribute("conversation", conversation);
        model.addAttribute("messages", messages);
        model.addAttribute("participants", participants);
        model.addAttribute("currentUserId", userId);
        model.addAttribute("username", username);
        model.addAttribute("conversationName", conversationService.getConversationDisplayName(conversation, userId));
        model.addAttribute("isAdmin", isAdmin);
        
        return "chat";
    }
    
    @PostMapping("/conversation/create")
    public String createConversation(@RequestParam Long userId2,
                                     HttpSession session,
                                     RedirectAttributes redirectAttributes) {
        Long userId1 = (Long) session.getAttribute("userId");
        if (userId1 == null) {
            return "redirect:/login";
        }
        
        Conversation conversation = conversationService.createDirectConversation(userId1, userId2);
        return "redirect:/conversation/" + conversation.getId();
    }
    
    @GetMapping("/users")
    public String users(HttpSession session, Model model, @RequestParam(required = false) String search) {
        Long userId = (Long) session.getAttribute("userId");
        if (userId == null) {
            return "redirect:/login";
        }
        
        String username = (String) session.getAttribute("username");
        List<User> users;
        if (search != null && !search.isEmpty()) {
            users = userService.searchUsers(search);
        } else {
            users = userService.findAllUsers();
        }
        
        // Remove current user from list
        users = users.stream()
            .filter(u -> !u.getId().equals(userId))
            .toList();
        
        // Check if user is admin
        boolean isAdmin = userService.findById(userId)
            .map(user -> user.getIsAdmin() != null && user.getIsAdmin())
            .orElse(false);
        
        model.addAttribute("users", users);
        model.addAttribute("currentUserId", userId);
        model.addAttribute("username", username);
        model.addAttribute("isAdmin", isAdmin);
        
        return "users";
    }
}
