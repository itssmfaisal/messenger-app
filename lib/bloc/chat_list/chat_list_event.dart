import 'package:equatable/equatable.dart';

sealed class ChatListEvent extends Equatable {
  const ChatListEvent();

  @override
  List<Object?> get props => [];
}

final class LoadConversations extends ChatListEvent {
  final int page;

  const LoadConversations({this.page = 0});

  @override
  List<Object?> get props => [page];
}

final class RefreshConversations extends ChatListEvent {}
