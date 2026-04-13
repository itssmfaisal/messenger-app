// Models for API responses

class Message {
  final int id;
  final String sender;
  final String recipient;
  final String content;
  final String status; // SENT, DELIVERED, SEEN
  final DateTime sentAt;
  final DateTime? deliveredAt;
  final DateTime? seenAt;
  final String? attachmentUrl;
  final String? attachmentName;
  final String? attachmentType;
  final int? attachmentSize;

  Message({
    required this.id,
    required this.sender,
    required this.recipient,
    required this.content,
    required this.status,
    required this.sentAt,
    this.deliveredAt,
    this.seenAt,
    this.attachmentUrl,
    this.attachmentName,
    this.attachmentType,
    this.attachmentSize,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      sender: json['sender'],
      recipient: json['recipient'],
      content: json['content'] ?? '',
      status: json['status'],
      sentAt: DateTime.parse(json['sentAt']),
      deliveredAt:
          json['deliveredAt'] != null ? DateTime.parse(json['deliveredAt']) : null,
      seenAt: json['seenAt'] != null ? DateTime.parse(json['seenAt']) : null,
      attachmentUrl: json['attachmentUrl'],
      attachmentName: json['attachmentName'],
      attachmentType: json['attachmentType'],
      attachmentSize: json['attachmentSize'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sender': sender,
        'recipient': recipient,
        'content': content,
        'status': status,
        'sentAt': sentAt.toIso8601String(),
        'deliveredAt': deliveredAt?.toIso8601String(),
        'seenAt': seenAt?.toIso8601String(),
        'attachmentUrl': attachmentUrl,
        'attachmentName': attachmentName,
        'attachmentType': attachmentType,
        'attachmentSize': attachmentSize,
      };
}

class Conversation {
  final String partner;
  final DateTime lastMessageAt;

  Conversation({required this.partner, required this.lastMessageAt});

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      partner: json['partner'],
      lastMessageAt: DateTime.parse(json['lastMessageAt']),
    );
  }
}

class Profile {
  final String username;
  final String? displayName;
  final String? bio;
  final String? profilePictureUrl;
  final String? email;

  Profile({
    required this.username,
    this.displayName,
    this.bio,
    this.profilePictureUrl,
    this.email,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      username: json['username'],
      displayName: json['displayName'],
      bio: json['bio'],
      profilePictureUrl: json['profilePictureUrl'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() => {
        'displayName': displayName,
        'bio': bio,
      };
}

class AttachmentUploadResponse {
  final String attachmentUrl;
  final String attachmentName;
  final String attachmentType;
  final int attachmentSize;

  AttachmentUploadResponse({
    required this.attachmentUrl,
    required this.attachmentName,
    required this.attachmentType,
    required this.attachmentSize,
  });

  factory AttachmentUploadResponse.fromJson(Map<String, dynamic> json) {
    return AttachmentUploadResponse(
      attachmentUrl: json['attachmentUrl'],
      attachmentName: json['attachmentName'],
      attachmentType: json['attachmentType'],
      attachmentSize: json['attachmentSize'],
    );
  }
}

class ConversationPage {
  final List<Conversation> content;
  final int totalElements;
  final int totalPages;
  final bool isLast;
  final bool isFirst;
  final Map<String, String?> userNameDisplayNameMapping;

  ConversationPage({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.isLast,
    required this.isFirst,
    this.userNameDisplayNameMapping = const {},
  });

  factory ConversationPage.fromJson(Map<String, dynamic> json) {
    final conversationsJson =
        (json['conversations'] is Map<String, dynamic>)
            ? json['conversations'] as Map<String, dynamic>
            : json;
    final mapping = _parseUserNameDisplayNameMapping(json);

    return ConversationPage(
      content: (conversationsJson['content'] as List)
          .map((c) => Conversation.fromJson(c))
          .toList(),
      totalElements: conversationsJson['totalElements'],
      totalPages: conversationsJson['totalPages'],
      isLast: conversationsJson['last'] ?? true,
      isFirst: conversationsJson['first'] ?? true,
      userNameDisplayNameMapping: mapping,
    );
  }
}

class MessagePage {
  final List<Message> content;
  final int totalElements;
  final int totalPages;
  final Map<String, String?> userNameDisplayNameMapping;

  MessagePage({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    this.userNameDisplayNameMapping = const {},
  });

  factory MessagePage.fromJson(Map<String, dynamic> json) {
    final messagesJson =
        (json['messages'] is Map<String, dynamic>)
            ? json['messages'] as Map<String, dynamic>
            : json;
    final mapping = _parseUserNameDisplayNameMapping(json);

    return MessagePage(
      content:
          (messagesJson['content'] as List).map((m) => Message.fromJson(m)).toList(),
      totalElements: messagesJson['totalElements'],
      totalPages: messagesJson['totalPages'],
      userNameDisplayNameMapping: mapping,
    );
  }
}

Map<String, String?> _parseUserNameDisplayNameMapping(Map<String, dynamic> json) {
  final rawMapping = json['userNameDisplayNameMapping'];
  if (rawMapping is! List) {
    return const {};
  }

  final parsed = <String, String?>{};
  for (final item in rawMapping) {
    if (item is! Map<String, dynamic>) continue;
    final username = item['username'];
    if (username is! String || username.isEmpty) continue;

    final displayName = item['displayName'];
    parsed[username] = displayName is String && displayName.trim().isNotEmpty
        ? displayName.trim()
        : null;
  }

  return parsed;
}
