import 'package:equatable/equatable.dart';
import 'package:messenger_app/data/models/conversation.dart';

sealed class ChatListState extends Equatable {
  const ChatListState();

  @override
  List<Object?> get props => [];
}

final class ChatListInitial extends ChatListState {}

final class ChatListLoading extends ChatListState {}

final class ChatListLoaded extends ChatListState {
  final ConversationPage conversationPage;
  final bool isLoadingMore;

  const ChatListLoaded(this.conversationPage, {this.isLoadingMore = false});

  ChatListLoaded copyWith({
    ConversationPage? conversationPage,
    bool? isLoadingMore,
  }) {
    return ChatListLoaded(
      conversationPage ?? this.conversationPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [conversationPage, isLoadingMore];
}

final class ChatListError extends ChatListState {
  final String message;

  const ChatListError(this.message);

  @override
  List<Object?> get props => [message];
}
