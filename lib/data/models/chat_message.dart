import 'package:equatable/equatable.dart';

enum MessageStatus { sent, delivered, seen }

class ChatMessage extends Equatable {
  final int id;
  final String sender;
  final String recipient;
  final String content;
  final MessageStatus status;
  final DateTime sentAt;
  final DateTime? deliveredAt;
  final DateTime? seenAt;
  final String? attachmentUrl;
  final String? attachmentName;
  final String? attachmentType;
  final int? attachmentSize;

  const ChatMessage({
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

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      sender: json['sender'],
      recipient: json['recipient'],
      content: json['content'] ?? '',
      status: _parseStatus(json['status']),
      sentAt: DateTime.parse(json['sentAt']),
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.parse(json['deliveredAt'])
          : null,
      seenAt: json['seenAt'] != null ? DateTime.parse(json['seenAt']) : null,
      attachmentUrl: json['attachmentUrl'],
      attachmentName: json['attachmentName'],
      attachmentType: json['attachmentType'],
      attachmentSize: json['attachmentSize'],
    );
  }

  static MessageStatus _parseStatus(String? status) {
    return switch (status) {
      'DELIVERED' => MessageStatus.delivered,
      'SEEN' => MessageStatus.seen,
      _ => MessageStatus.sent,
    };
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sender': sender,
        'recipient': recipient,
        'content': content,
        'status': switch (status) {
          MessageStatus.sent => 'SENT',
          MessageStatus.delivered => 'DELIVERED',
          MessageStatus.seen => 'SEEN',
        },
        'sentAt': sentAt.toIso8601String(),
        'deliveredAt': deliveredAt?.toIso8601String(),
        'seenAt': seenAt?.toIso8601String(),
        'attachmentUrl': attachmentUrl,
        'attachmentName': attachmentName,
        'attachmentType': attachmentType,
        'attachmentSize': attachmentSize,
      };

  Map<String, dynamic> toSendJson() => {
        'recipient': recipient,
        'content': content,
        if (attachmentUrl != null) 'attachmentUrl': attachmentUrl,
        if (attachmentName != null) 'attachmentName': attachmentName,
        if (attachmentType != null) 'attachmentType': attachmentType,
        if (attachmentSize != null) 'attachmentSize': attachmentSize,
      };

  ChatMessage copyWith({
    int? id,
    String? sender,
    String? recipient,
    String? content,
    MessageStatus? status,
    DateTime? sentAt,
    DateTime? deliveredAt,
    DateTime? seenAt,
    String? attachmentUrl,
    String? attachmentName,
    String? attachmentType,
    int? attachmentSize,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      recipient: recipient ?? this.recipient,
      content: content ?? this.content,
      status: status ?? this.status,
      sentAt: sentAt ?? this.sentAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      seenAt: seenAt ?? this.seenAt,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      attachmentName: attachmentName ?? this.attachmentName,
      attachmentType: attachmentType ?? this.attachmentType,
      attachmentSize: attachmentSize ?? this.attachmentSize,
    );
  }

  @override
  List<Object?> get props => [
        id,
        sender,
        recipient,
        content,
        status,
        sentAt,
        deliveredAt,
        seenAt,
        attachmentUrl,
        attachmentName,
        attachmentType,
        attachmentSize,
      ];
}
