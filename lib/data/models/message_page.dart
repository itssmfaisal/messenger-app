import 'package:equatable/equatable.dart';
import 'package:messenger_app/data/models/chat_message.dart';

class MessagePage extends Equatable {
  final List<ChatMessage> messages;
  final int pageNumber;
  final int pageSize;
  final int totalElements;
  final int totalPages;
  final bool last;
  final bool first;

  const MessagePage({
    required this.messages,
    required this.pageNumber,
    required this.pageSize,
    required this.totalElements,
    required this.totalPages,
    required this.last,
    required this.first,
  });

  factory MessagePage.fromJson(Map<String, dynamic> json) {
    final content = json['content'] as List;
    return MessagePage(
      messages: content
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
      pageNumber: json['pageable']['pageNumber'] as int,
      pageSize: json['pageable']['pageSize'] as int,
      totalElements: json['totalElements'] as int,
      totalPages: json['totalPages'] as int,
      last: json['last'] as bool,
      first: json['first'] as bool,
    );
  }

  @override
  List<Object?> get props => [
        messages,
        pageNumber,
        pageSize,
        totalElements,
        totalPages,
        last,
        first,
      ];
}
