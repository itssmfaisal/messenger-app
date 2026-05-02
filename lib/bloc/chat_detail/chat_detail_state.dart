import 'package:equatable/equatable.dart';
import 'package:messenger_app/data/models/chat_message.dart';

sealed class ChatDetailState extends Equatable {
  const ChatDetailState();

  @override
  List<Object?> get props => [];
}

final class ChatDetailInitial extends ChatDetailState {}

final class ChatDetailLoading extends ChatDetailState {}

final class ChatDetailLoaded extends ChatDetailState {
  final String partnerUsername;
  final List<ChatMessage> messages;
  final bool isLoadingMore;
  final bool hasMoreMessages;
  final bool isPartnerOnline;

  const ChatDetailLoaded({
    required this.partnerUsername,
    required this.messages,
    this.isLoadingMore = false,
    this.hasMoreMessages = true,
    this.isPartnerOnline = false,
  });

  ChatDetailLoaded copyWith({
    String? partnerUsername,
    List<ChatMessage>? messages,
    bool? isLoadingMore,
    bool? hasMoreMessages,
    bool? isPartnerOnline,
  }) {
    return ChatDetailLoaded(
      partnerUsername: partnerUsername ?? this.partnerUsername,
      messages: messages ?? this.messages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
      isPartnerOnline: isPartnerOnline ?? this.isPartnerOnline,
    );
  }

  @override
  List<Object?> get props => [
        partnerUsername,
        messages,
        isLoadingMore,
        hasMoreMessages,
        isPartnerOnline,
      ];
}

final class ChatDetailError extends ChatDetailState {
  final String message;

  const ChatDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
