# Admin Panel Setup Guide

## Features Addedd

### 1. Back Button
- Added a prominent "← Back" button in the chat header
- Clicking it returns you to the conversations list

### 2. Admin Panel
The admin panel provides comprehensive community management:

#### Dashboard (`/admin`)
- View statistics: Total users, online users, conversations, messages
- Quick access to management pages

#### User Management (`/admin/users`)
- View all users with details (username, email, status, admin status)
- Search users by name
- Toggle admin status for any user
- Delete users (with confirmation)

#### Conversation Management (`/admin/conversations`)
- View all conversations (direct and group)
- View messages in any conversation
- Delete conversations (with confirmation)

## Making a User an Admin

### Option 1: Using SQL (Recommended)
```sql
-- Connect to your database
psql -U your_username -d messenger_db

-- Make a user admin (replace 'username' with actual username)
UPDATE users SET is_admin = true WHERE username = 'your_username';

-- Verify
SELECT id, username, is_admin FROM users WHERE username = 'your_username';
```

### Option 2: Using Admin Panel
1. First, you need to manually set one user as admin via SQL (see Option 1)
2. Then login as that admin user
3. Go to Admin Panel → Users
4. Click "Make Admin" button next to any user

### Option 3: Programmatically (for first admin)
You can add this to your application startup or create a one-time script.

## Access Control

- Only users with `is_admin = true` can access `/admin/*` routes
- Non-admin users are redirected to `/conversations` if they try to access admin pages
- Admin panel link only appears in navigation for admin users

## Navigation

- **Back Button**: Visible in chat header, returns to conversations list
- **Admin Panel Link**: Appears in sidebar for admin users only
- All admin pages have navigation to switch between dashboard, users, and conversations

## Security Notes

- Admin status is checked on every admin endpoint
- Users cannot delete their own account
- All destructive actions require confirmation
- Admin panel is protected by session-based authentication

