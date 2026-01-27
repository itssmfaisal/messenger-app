# Quick Setup Guide

## Prerequisites
- Java 17+
- Maven 3.6+
- PostgreSQL 12+

## Step-by-Step Setup

### 1. Create PostgreSQL Database
```bash
# Connect to PostgreSQL
psql -U postgres

# Create database
CREATE DATABASE messenger_db;

# Exit
\q
```

### 2. Update Database Configuration
Edit `src/main/resources/application.properties`:
```properties
spring.datasource.url=jdbc:postgresql://localhost:5432/messenger_db
spring.datasource.username=your_postgres_username
spring.datasource.password=your_postgres_password
```

### 3. Build and Run
```bash
# Build the project
mvn clean install

# Run the application
mvn spring-boot:run
```

### 4. Access the Application
- Open browser: http://localhost:8080
- Register a new account
- Login and start chatting!

## Testing the Application

1. **Register Multiple Users**: Create 2-3 test accounts
2. **Start Conversations**: Go to "New Conversation" and select a user
3. **Send Messages**: Type and send messages in real-time
4. **Test Real-time**: Open multiple browser windows/tabs with different users to see real-time messaging

## Troubleshooting

### Database Connection Error
- Ensure PostgreSQL is running
- Verify database credentials in `application.properties`
- Check if database `messenger_db` exists

### Port Already in Use
- Change port in `application.properties`: `server.port=8081`

### WebSocket Not Working
- Check browser console for errors
- Ensure you're using a modern browser (Chrome, Firefox, Edge)
- The app will fallback to polling if WebSocket fails

## Default Configuration

- **Server Port**: 8080
- **Database**: messenger_db
- **Auto-create tables**: Enabled (spring.jpa.hibernate.ddl-auto=update)
