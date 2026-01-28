package com.messenger.app.dto;

import java.time.LocalDateTime;

public class MessageDTO {
    private Long id;
    private String content;
    private Long senderId;
    private String senderUsername;
    private String senderProfilePicture;
    private LocalDateTime createdAt;
    private Boolean isRead;
    
    public MessageDTO() {}
    
    public MessageDTO(Long id, String content, Long senderId, String senderUsername, 
                     String senderProfilePicture, LocalDateTime createdAt, Boolean isRead) {
        this.id = id;
        this.content = content;
        this.senderId = senderId;
        this.senderUsername = senderUsername;
        this.senderProfilePicture = senderProfilePicture;
        this.createdAt = createdAt;
        this.isRead = isRead;
    }
    
    // Getters and Setters
    public Long getId() {
        return id;
    }
    
    public void setId(Long id) {
        this.id = id;
    }
    
    public String getContent() {
        return content;
    }
    
    public void setContent(String content) {
        this.content = content;
    }
    
    public Long getSenderId() {
        return senderId;
    }
    
    public void setSenderId(Long senderId) {
        this.senderId = senderId;
    }
    
    public String getSenderUsername() {
        return senderUsername;
    }
    
    public void setSenderUsername(String senderUsername) {
        this.senderUsername = senderUsername;
    }
    
    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
    
    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
    
    public Boolean getIsRead() {
        return isRead;
    }
    
    public void setIsRead(Boolean isRead) {
        this.isRead = isRead;
    }
    
    public String getSenderProfilePicture() {
        return senderProfilePicture;
    }
    
    public void setSenderProfilePicture(String senderProfilePicture) {
        this.senderProfilePicture = senderProfilePicture;
    }
}

