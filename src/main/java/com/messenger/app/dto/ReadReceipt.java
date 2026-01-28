package com.messenger.app.dto;

public class ReadReceipt {
    private Long messageId;
    private Long conversationId;
    private Long senderId;
    private Long readerId;
    private Boolean isRead;
    
    public ReadReceipt() {}
    
    public ReadReceipt(Long messageId, Long conversationId, Long senderId, Long readerId, Boolean isRead) {
        this.messageId = messageId;
        this.conversationId = conversationId;
        this.senderId = senderId;
        this.readerId = readerId;
        this.isRead = isRead;
    }
    
    public Long getMessageId() {
        return messageId;
    }
    
    public void setMessageId(Long messageId) {
        this.messageId = messageId;
    }
    
    public Long getConversationId() {
        return conversationId;
    }
    
    public void setConversationId(Long conversationId) {
        this.conversationId = conversationId;
    }
    
    public Long getReaderId() {
        return readerId;
    }
    
    public void setReaderId(Long readerId) {
        this.readerId = readerId;
    }
    
    public Boolean getIsRead() {
        return isRead;
    }
    
    public void setIsRead(Boolean isRead) {
        this.isRead = isRead;
    }
    
    public Long getSenderId() {
        return senderId;
    }
    
    public void setSenderId(Long senderId) {
        this.senderId = senderId;
    }
}

