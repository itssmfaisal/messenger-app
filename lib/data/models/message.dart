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
