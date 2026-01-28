package com.messenger.app.controller;

import com.messenger.app.model.Conversation;
import com.messenger.app.model.Message;
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
@RequestMapping("/admin")
public class AdminController {
    
    @Autowired
    private UserService userService;
    
    @Autowired
    private ConversationService conversationService;
    
    @Autowired
    private MessageService messageService;
    
    private boolean isAdmin(HttpSession session) {
        Long userId = (Long) session.getAttribute("userId");
        if (userId == null) {
            return false;
        }
        return userService.findById(userId)
            .map(user -> user.getIsAdmin() != null && user.getIsAdmin())
            .orElse(false);
    }
    
    @GetMapping("")
    public String adminDashboard(HttpSession session, Model model) {
        if (!isAdmin(session)) {
            return "redirect:/conversations";
        }
        
        String username = (String) session.getAttribute("username");
        
        // Get statistics
        long totalUsers = userService.findAllUsers().size();
        long totalConversations = conversationService.findAllConversations().size();
        long totalMessages = messageService.getTotalMessageCount();
        long onlineUsers = userService.findAllUsers().stream()
            .filter(u -> u.getIsOnline() != null && u.getIsOnline())
            .count();
        
        model.addAttribute("username", username);
        model.addAttribute("totalUsers", totalUsers);
        model.addAttribute("totalConversations", totalConversations);
        model.addAttribute("totalMessages", totalMessages);
        model.addAttribute("onlineUsers", onlineUsers);
        
        return "admin/dashboard";
    }
    
    @GetMapping("/users")
    public String adminUsers(HttpSession session, Model model, @RequestParam(required = false) String search) {
        if (!isAdmin(session)) {
            return "redirect:/conversations";
        }
        
        String username = (String) session.getAttribute("username");
        List<User> users;
        
        if (search != null && !search.isEmpty()) {
            users = userService.searchUsers(search);
        } else {
            users = userService.findAllUsers();
        }
        
        model.addAttribute("username", username);
        model.addAttribute("users", users);
        model.addAttribute("search", search);
        
        return "admin/users";
    }
    
    @GetMapping("/conversations")
    public String adminConversations(HttpSession session, Model model) {
        if (!isAdmin(session)) {
            return "redirect:/conversations";
        }
        
        String username = (String) session.getAttribute("username");
        List<Conversation> conversations = conversationService.findAllConversations();
        
        model.addAttribute("username", username);
        model.addAttribute("conversations", conversations);
        model.addAttribute("conversationService", conversationService);
        
        return "admin/conversations";
    }
    
    @PostMapping("/users/{id}/toggle-admin")
    public String toggleAdmin(@PathVariable Long id, HttpSession session, RedirectAttributes redirectAttributes) {
        if (!isAdmin(session)) {
            return "redirect:/conversations";
        }
        
        userService.findById(id).ifPresent(user -> {
            user.setIsAdmin(!user.getIsAdmin());
            userService.updateUser(user);
        });
        
        redirectAttributes.addFlashAttribute("message", "Admin status updated");
        return "redirect:/admin/users";
    }
    
    @PostMapping("/users/{id}/delete")
    public String deleteUser(@PathVariable Long id, HttpSession session, RedirectAttributes redirectAttributes) {
        if (!isAdmin(session)) {
            return "redirect:/conversations";
        }
        
        Long currentUserId = (Long) session.getAttribute("userId");
        if (id.equals(currentUserId)) {
            redirectAttributes.addFlashAttribute("error", "Cannot delete your own account");
            return "redirect:/admin/users";
        }
        
        userService.findById(id).ifPresent(user -> {
            userService.deleteUser(id);
        });
        
        redirectAttributes.addFlashAttribute("message", "User deleted successfully");
        return "redirect:/admin/users";
    }
    
    @PostMapping("/conversations/{id}/delete")
    public String deleteConversation(@PathVariable Long id, HttpSession session, RedirectAttributes redirectAttributes) {
        if (!isAdmin(session)) {
            return "redirect:/conversations";
        }
        
        conversationService.deleteConversation(id);
        redirectAttributes.addFlashAttribute("message", "Conversation deleted successfully");
        return "redirect:/admin/conversations";
    }
    
    @GetMapping("/conversations/{id}/messages")
    public String viewConversationMessages(@PathVariable Long id, HttpSession session, Model model) {
        if (!isAdmin(session)) {
            return "redirect:/conversations";
        }
        
        String username = (String) session.getAttribute("username");
        Conversation conversation = conversationService.findById(id)
            .orElseThrow(() -> new RuntimeException("Conversation not found"));
        
        List<Message> messages = messageService.getConversationMessages(id);
        
        model.addAttribute("username", username);
        model.addAttribute("conversation", conversation);
        model.addAttribute("messages", messages);
        
        return "admin/conversation-messages";
    }
}

