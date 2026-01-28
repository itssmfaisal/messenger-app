package com.messenger.app.controller;

import com.messenger.app.model.User;
import com.messenger.app.service.ImageService;
import com.messenger.app.service.UserService;
import jakarta.servlet.http.HttpSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.io.IOException;
import java.util.Optional;

@Controller
@RequestMapping("/profile")
public class ProfileController {
    
    @Autowired
    private UserService userService;
    
    @Autowired
    private ImageService imageService;
    
    @GetMapping("")
    public String viewProfile(HttpSession session, Model model) {
        Long userId = (Long) session.getAttribute("userId");
        if (userId == null) {
            return "redirect:/login";
        }
        
        Optional<User> userOpt = userService.findById(userId);
        if (userOpt.isEmpty()) {
            return "redirect:/login";
        }
        
        User user = userOpt.get();
        String username = (String) session.getAttribute("username");
        
        // Check if user is admin
        boolean isAdmin = user.getIsAdmin() != null && user.getIsAdmin();
        
        model.addAttribute("user", user);
        model.addAttribute("username", username);
        model.addAttribute("isAdmin", isAdmin);
        
        return "profile";
    }
    
    @PostMapping("/update")
    public String updateProfile(@RequestParam(required = false) String fullName,
                                @RequestParam(required = false) String email,
                                @RequestParam(required = false) MultipartFile profilePicture,
                                HttpSession session,
                                RedirectAttributes redirectAttributes) {
        Long userId = (Long) session.getAttribute("userId");
        if (userId == null) {
            return "redirect:/login";
        }
        
        Optional<User> userOpt = userService.findById(userId);
        if (userOpt.isEmpty()) {
            return "redirect:/login";
        }
        
        User user = userOpt.get();
        
        // Update full name
        if (fullName != null && !fullName.trim().isEmpty()) {
            user.setFullName(fullName.trim());
        }
        
        // Update email (with validation)
        if (email != null && !email.trim().isEmpty()) {
            // Check if email is already taken by another user
            Optional<User> existingUser = userService.findByEmail(email.trim());
            if (existingUser.isPresent() && !existingUser.get().getId().equals(userId)) {
                redirectAttributes.addFlashAttribute("error", "Email already taken");
                return "redirect:/profile";
            }
            user.setEmail(email.trim());
        }
        
        // Handle profile picture upload
        if (profilePicture != null && !profilePicture.isEmpty()) {
            try {
                // Delete old profile picture if exists
                if (user.getProfilePicture() != null && !user.getProfilePicture().isEmpty()) {
                    imageService.deleteImage(user.getProfilePicture());
                }
                
                // Save and compress new image
                String filename = imageService.saveAndCompressImage(profilePicture);
                user.setProfilePicture(filename);
                redirectAttributes.addFlashAttribute("message", "Profile updated successfully!");
            } catch (IllegalArgumentException e) {
                redirectAttributes.addFlashAttribute("error", e.getMessage());
                return "redirect:/profile";
            } catch (IOException e) {
                redirectAttributes.addFlashAttribute("error", "Failed to upload image: " + e.getMessage());
                return "redirect:/profile";
            }
        }
        
        userService.updateUser(user);
        
        // Update session username if changed
        session.setAttribute("username", user.getUsername());
        
        return "redirect:/profile";
    }
    
    @PostMapping("/picture/delete")
    public String deleteProfilePicture(HttpSession session, RedirectAttributes redirectAttributes) {
        Long userId = (Long) session.getAttribute("userId");
        if (userId == null) {
            return "redirect:/login";
        }
        
        Optional<User> userOpt = userService.findById(userId);
        if (userOpt.isPresent()) {
            User user = userOpt.get();
            if (user.getProfilePicture() != null && !user.getProfilePicture().isEmpty()) {
                imageService.deleteImage(user.getProfilePicture());
                user.setProfilePicture(null);
                userService.updateUser(user);
                redirectAttributes.addFlashAttribute("message", "Profile picture deleted");
            }
        }
        
        return "redirect:/profile";
    }
}

