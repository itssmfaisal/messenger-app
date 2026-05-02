import 'package:equatable/equatable.dart';

class Conversation extends Equatable {
  final String partner;
  final DateTime lastMessageAt;

  const Conversation({
    required this.partner,
    required this.lastMessageAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      partner: json['partner'] as String,
      lastMessageAt: DateTime.parse(json['lastMessageAt']),
    );
  }

  @override
  List<Object?> get props => [partner, lastMessageAt];
}

class ConversationPage extends Equatable {
  final List<Conversation> conversations;
  final int pageNumber;
  final int pageSize;
  final int totalElements;
  final int totalPages;
  final bool last;
  final bool first;

  const ConversationPage({
    required this.conversations,
    required this.pageNumber,
    required this.pageSize,
    required this.totalElements,
    required this.totalPages,
    required this.last,
    required this.first,
  });

  factory ConversationPage.fromJson(Map<String, dynamic> json) {
    final content = json['content'] as List;
    return ConversationPage(
      conversations: content
          .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
          .toList(),
      pageNumber: json['pageable']['pageNumber'] as int,
      pageSize: json['pageable']['pageSize'] as int,
      totalElements: json['totalElements'] as int,
      totalPages: json['totalPages'] as int,
      last: json['last'] as bool,
      first: json['first'] as bool,
    );
  }

  ConversationPage copyWith({List<Conversation>? conversations}) {
    return ConversationPage(
      conversations: conversations ?? this.conversations,
      pageNumber: pageNumber,
      pageSize: pageSize,
      totalElements: totalElements,
      totalPages: totalPages,
      last: last,
      first: first,
    );
  }

  @override
  List<Object?> get props => [
        conversations,
        pageNumber,
        pageSize,
        totalElements,
        totalPages,
        last,
        first,
      ];
}
