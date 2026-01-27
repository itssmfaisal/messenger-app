# Messenger Web Application

A full-featured messenger-like web application built with Spring Boot MVC and PostgreSQL.

## Features

- User registration and authentication
- Real-time messaging with WebSocket support
- Direct conversations between users
- Group conversations support
- Message read status
- Online/offline user status
- Modern, responsive UI

## Technology Stack

- **Backend**: Spring Boot 4.0.2
- **Database**: PostgreSQL
- **Frontend**: Thymeleaf, HTML, CSS, JavaScript
- **Real-time**: WebSocket with STOMP
- **ORM**: Spring Data JPA

## Prerequisites

- Java 17 or higher
- Maven 3.6+
- PostgreSQL 12+

## Setup Instructions

### 1. Database Setup

Create a PostgreSQL database:

```sql
CREATE DATABASE messenger_db;
```

### 2. Configure Database Connection

Update `src/main/resources/application.properties` with your PostgreSQL credentials:

```properties
spring.datasource.url=jdbc:postgresql://localhost:5432/messenger_db
spring.datasource.username=your_username
spring.datasource.password=your_password
```

### 3. Build and Run

```bash
# Build the project
mvn clean install

# Run the application
mvn spring-boot:run
```

The application will be available at `http://localhost:8080`

### 4. Access the Application

1. Navigate to `http://localhost:8080`
2. Register a new account
3. Login and start chatting!

## Project Structure

```
src/
├── main/
│   ├── java/com/messenger/app/
│   │   ├── config/          # Configuration classes
│   │   ├── controller/       # MVC controllers
│   │   ├── dto/              # Data transfer objects
│   │   ├── model/            # JPA entities
│   │   ├── repository/       # JPA repositories
│   │   └── service/          # Business logic services
│   └── resources/
│       ├── static/           # CSS, JS, images
│       │   ├── css/
│       │   └── js/
│       ├── templates/        # Thymeleaf templates
│       └── application.properties
└── test/
```

## API Endpoints

### Authentication
- `GET /login` - Login page
- `POST /login` - Process login
- `GET /register` - Registration page
- `POST /register` - Process registration
- `GET /logout` - Logout

### Conversations
- `GET /conversations` - List all conversations
- `GET /conversation/{id}` - View conversation
- `POST /conversation/create` - Create new conversation
- `GET /users` - List/search users

### Messages
- `POST /message/send` - Send a message
- `GET /message/conversation/{id}` - Get conversation messages

### WebSocket
- `/ws/chat/{conversationId}` - WebSocket endpoint for real-time messaging

## Database Schema

The application uses the following main entities:

- **User**: User accounts
- **Conversation**: Chat conversations (direct or group)
- **Message**: Individual messages
- **Participant**: Many-to-many relationship between users and conversations

## Development Notes

- The application uses session-based authentication (HttpSession)
- WebSocket connections use STOMP protocol for messaging
- Database schema is auto-generated on first run (spring.jpa.hibernate.ddl-auto=update)
- Passwords are stored in plain text (for demo purposes - use password encoding in production)

## Future Enhancements

- Password encryption
- File attachments
- Message reactions
- Typing indicators
- Push notifications
- Mobile app support
# messenger-app
