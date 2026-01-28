package com.messenger.app.service;

import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import javax.imageio.ImageIO;
import java.awt.*;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Iterator;
import java.util.UUID;

@Service
public class ImageService {
    
    private static final String UPLOAD_DIR = "uploads/profile-pictures";
    private static final long MAX_FILE_SIZE = 2 * 1024 * 1024; // 2MB
    private static final long TARGET_FILE_SIZE = 800 * 1024; // 800KB target
    private static final int MAX_WIDTH = 800;
    private static final int MAX_HEIGHT = 800;
    
    public ImageService() {
        // Create upload directory if it doesn't exist
        try {
            Path uploadPath = Paths.get(UPLOAD_DIR);
            if (!Files.exists(uploadPath)) {
                Files.createDirectories(uploadPath);
            }
        } catch (IOException e) {
            System.err.println("Failed to create upload directory: " + e.getMessage());
        }
    }
    
    public String saveAndCompressImage(MultipartFile file) throws IOException {
        // Validate file
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("File is empty");
        }
        
        // Check file size
        if (file.getSize() > MAX_FILE_SIZE) {
            throw new IllegalArgumentException("File size exceeds 2MB limit");
        }
        
        // Validate image format
        String contentType = file.getContentType();
        if (contentType == null || !contentType.startsWith("image/")) {
            throw new IllegalArgumentException("File is not an image");
        }
        
        // Read original image
        BufferedImage originalImage = ImageIO.read(file.getInputStream());
        if (originalImage == null) {
            throw new IllegalArgumentException("Invalid image file");
        }
        
        // Calculate new dimensions maintaining aspect ratio
        int originalWidth = originalImage.getWidth();
        int originalHeight = originalImage.getHeight();
        double aspectRatio = (double) originalWidth / originalHeight;
        
        int newWidth = originalWidth;
        int newHeight = originalHeight;
        
        if (originalWidth > MAX_WIDTH || originalHeight > MAX_HEIGHT) {
            if (originalWidth > originalHeight) {
                newWidth = MAX_WIDTH;
                newHeight = (int) (MAX_WIDTH / aspectRatio);
            } else {
                newHeight = MAX_HEIGHT;
                newWidth = (int) (MAX_HEIGHT * aspectRatio);
            }
        }
        
        // Resize image
        BufferedImage resizedImage = new BufferedImage(newWidth, newHeight, BufferedImage.TYPE_INT_RGB);
        Graphics2D g = resizedImage.createGraphics();
        g.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_BILINEAR);
        g.setRenderingHint(RenderingHints.KEY_RENDERING, RenderingHints.VALUE_RENDER_QUALITY);
        g.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
        g.drawImage(originalImage, 0, 0, newWidth, newHeight, null);
        g.dispose();
        
        // Determine output format
        String format = "jpg"; // Default to JPEG for better compression
        String originalFormat = getImageFormat(contentType);
        if (originalFormat != null && originalFormat.equals("png") && hasTransparency(originalImage)) {
            format = "png";
        }
        
        // Compress and save with quality adjustment
        String filename = UUID.randomUUID().toString() + "." + format;
        Path filePath = Paths.get(UPLOAD_DIR, filename);
        
        // Try different quality levels to get close to target size
        float quality = 0.85f;
        int attempts = 0;
        long fileSize = Long.MAX_VALUE;
        
        while (fileSize > TARGET_FILE_SIZE && attempts < 5 && quality > 0.3f) {
            // Save with current quality
            File outputFile = filePath.toFile();
            if (format.equals("jpg")) {
                saveAsJPEG(resizedImage, outputFile, quality);
            } else {
                ImageIO.write(resizedImage, format, outputFile);
            }
            
            fileSize = outputFile.length();
            
            if (fileSize > TARGET_FILE_SIZE) {
                quality -= 0.1f;
                attempts++;
            }
        }
        
        return filename;
    }
    
    private void saveAsJPEG(BufferedImage image, File file, float quality) throws IOException {
        Iterator<javax.imageio.ImageWriter> writers = ImageIO.getImageWritersByFormatName("jpg");
        if (!writers.hasNext()) {
            // Fallback to PNG if JPEG writer not available
            ImageIO.write(image, "png", file);
            return;
        }
        
        javax.imageio.ImageWriter writer = writers.next();
        javax.imageio.ImageWriteParam param = writer.getDefaultWriteParam();
        
        if (param.canWriteCompressed()) {
            param.setCompressionMode(javax.imageio.ImageWriteParam.MODE_EXPLICIT);
            param.setCompressionQuality(quality);
        }
        
        try (javax.imageio.stream.ImageOutputStream output = 
                ImageIO.createImageOutputStream(file)) {
            writer.setOutput(output);
            writer.write(null, new javax.imageio.IIOImage(image, null, null), param);
        } finally {
            writer.dispose();
        }
    }
    
    private String getImageFormat(String contentType) {
        if (contentType == null) return null;
        if (contentType.equals("image/jpeg") || contentType.equals("image/jpg")) {
            return "jpg";
        } else if (contentType.equals("image/png")) {
            return "png";
        } else if (contentType.equals("image/gif")) {
            return "gif";
        } else if (contentType.equals("image/webp")) {
            return "webp";
        }
        return null;
    }
    
    private boolean hasTransparency(BufferedImage image) {
        return image.getColorModel().hasAlpha();
    }
    
    public boolean deleteImage(String filename) {
        if (filename == null || filename.isEmpty()) {
            return false;
        }
        try {
            Path filePath = Paths.get(UPLOAD_DIR, filename);
            return Files.deleteIfExists(filePath);
        } catch (IOException e) {
            System.err.println("Failed to delete image: " + e.getMessage());
            return false;
        }
    }
    
    public File getImageFile(String filename) {
        if (filename == null || filename.isEmpty()) {
            return null;
        }
        Path filePath = Paths.get(UPLOAD_DIR, filename);
        File file = filePath.toFile();
        return file.exists() ? file : null;
    }
}

