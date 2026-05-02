import 'package:equatable/equatable.dart';
import 'package:messenger_app/data/models/chat_message.dart';

sealed class ChatDetailEvent extends Equatable {
  const ChatDetailEvent();

  @override
  List<Object?> get props => [];
}

final class OpenChat extends ChatDetailEvent {
  final String partnerUsername;

  const OpenChat(this.partnerUsername);

  @override
  List<Object?> get props => [partnerUsername];
}

final class LoadOlderMessages extends ChatDetailEvent {}

final class SendMessage extends ChatDetailEvent {
  final String content;

  const SendMessage(this.content);

  @override
  List<Object?> get props => [content];
}

final class MessageReceived extends ChatDetailEvent {
  final ChatMessage message;

  const MessageReceived(this.message);

  @override
  List<Object?> get props => [message];
}

final class MessageStatusUpdated extends ChatDetailEvent {
  final int messageId;
  final MessageStatus status;

  const MessageStatusUpdated(this.messageId, this.status);

  @override
  List<Object?> get props => [messageId, status];
}

final class PartnerPresenceChanged extends ChatDetailEvent {
  final bool isOnline;

  const PartnerPresenceChanged(this.isOnline);

  @override
  List<Object?> get props => [isOnline];
}

final class CloseChat extends ChatDetailEvent {}
