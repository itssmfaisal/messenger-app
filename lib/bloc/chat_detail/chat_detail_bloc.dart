import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:messenger_app/bloc/chat_detail/chat_detail_event.dart';
import 'package:messenger_app/bloc/chat_detail/chat_detail_state.dart';
import 'package:messenger_app/data/models/chat_message.dart';
import 'package:messenger_app/data/services/websocket_service.dart';
import 'package:messenger_app/domain/repositories/chat_repository.dart';
import 'package:messenger_app/domain/repositories/presence_repository.dart';

class ChatDetailBloc extends Bloc<ChatDetailEvent, ChatDetailState> {
  final ChatRepository _chatRepository;
  final PresenceRepository _presenceRepository;
  final WebSocketService _webSocketService;

  ChatDetailBloc(
    this._chatRepository,
    this._presenceRepository,
    this._webSocketService,
  ) : super(ChatDetailInitial()) {
    on<OpenChat>(_onOpenChat);
    on<LoadOlderMessages>(_onLoadOlderMessages);
    on<SendMessage>(_onSendMessage);
    on<MessageReceived>(_onMessageReceived);
    on<MessageStatusUpdated>(_onMessageStatusUpdated);
    on<PartnerPresenceChanged>(_onPartnerPresenceChanged);
    on<CloseChat>(_onCloseChat);
  }

  Future<void> _onOpenChat(
    OpenChat event,
    Emitter<ChatDetailState> emit,
  ) async {
    emit(ChatDetailLoading());

    try {
      final messagePage = await _chatRepository.getConversationHistory(
        withUser: event.partnerUsername,
        page: 0,
        size: 20,
      );

      final messages = messagePage.messages.reversed.toList();

      try {
        final presence = await _presenceRepository.getPresence(
          event.partnerUsername,
        );
        emit(ChatDetailLoaded(
          partnerUsername: event.partnerUsername,
          messages: messages,
          hasMoreMessages: !messagePage.last,
          isPartnerOnline: presence.online,
        ));
      } catch (_) {
        emit(ChatDetailLoaded(
          partnerUsername: event.partnerUsername,
          messages: messages,
          hasMoreMessages: !messagePage.last,
        ));
      }

      _markIncomingMessagesAsDelivered(messages);
    } catch (e) {
      emit(ChatDetailError(e.toString()));
    }
  }

  Future<void> _onLoadOlderMessages(
    LoadOlderMessages event,
    Emitter<ChatDetailState> emit,
  ) async {
    if (state is! ChatDetailLoaded) return;
    final current = state as ChatDetailLoaded;
    if (!current.hasMoreMessages || current.isLoadingMore) return;

    emit(current.copyWith(isLoadingMore: true));

    try {
      final nextPage = (current.messages.length / 20).floor();
      final messagePage = await _chatRepository.getConversationHistory(
        withUser: current.partnerUsername,
        page: nextPage,
        size: 20,
      );

      final olderMessages = messagePage.messages.reversed.toList();
      final combined = [...olderMessages, ...current.messages];

      emit(current.copyWith(
        messages: combined,
        isLoadingMore: false,
        hasMoreMessages: !messagePage.last,
      ));
    } catch (e) {
      if (state is ChatDetailLoaded) {
        emit((state as ChatDetailLoaded).copyWith(isLoadingMore: false));
      }
    }
  }

  void _onSendMessage(
    SendMessage event,
    Emitter<ChatDetailState> emit,
  ) {
    if (state is! ChatDetailLoaded) return;
    final current = state as ChatDetailLoaded;

    final tempMessage = ChatMessage(
      id: -1,
      sender: '',
      recipient: current.partnerUsername,
      content: event.content,
      status: MessageStatus.sent,
      sentAt: DateTime.now(),
    );

    final updatedMessages = [...current.messages, tempMessage];
    emit(current.copyWith(messages: updatedMessages));

    _webSocketService.sendMessage(
      recipient: current.partnerUsername,
      content: event.content,
    );
  }

  void _onMessageReceived(
    MessageReceived event,
    Emitter<ChatDetailState> emit,
  ) {
    if (state is! ChatDetailLoaded) return;
    final current = state as ChatDetailLoaded;

    final existingIndex = current.messages.indexWhere(
      (m) => m.id == event.message.id,
    );

    List<ChatMessage> updatedMessages;
    if (existingIndex != -1) {
      updatedMessages = <ChatMessage>[...current.messages];
      updatedMessages[existingIndex] = event.message;
    } else {
      updatedMessages = [...current.messages, event.message];
    }

    emit(current.copyWith(messages: updatedMessages));
    _markIncomingMessagesAsDelivered(updatedMessages);
  }

  void _onMessageStatusUpdated(
    MessageStatusUpdated event,
    Emitter<ChatDetailState> emit,
  ) {
    if (state is! ChatDetailLoaded) return;
    final current = state as ChatDetailLoaded;

    final index = current.messages.indexWhere((m) => m.id == event.messageId);
    if (index == -1) return;

    final updatedMessages = <ChatMessage>[...current.messages];
    final original = updatedMessages[index];
    updatedMessages[index] = original.copyWith(status: event.status);

    emit(current.copyWith(messages: updatedMessages));
  }

  void _onPartnerPresenceChanged(
    PartnerPresenceChanged event,
    Emitter<ChatDetailState> emit,
  ) {
    if (state is! ChatDetailLoaded) return;
    final current = state as ChatDetailLoaded;
    emit(current.copyWith(isPartnerOnline: event.isOnline));
  }

  void _onCloseChat(
    CloseChat event,
    Emitter<ChatDetailState> emit,
  ) {
    emit(ChatDetailInitial());
  }

  void _markIncomingMessagesAsDelivered(List<ChatMessage> messages) {
    for (final message in messages) {
      if (message.status == MessageStatus.sent) {
        _webSocketService.markDelivered(message.id);
      } else if (message.status == MessageStatus.delivered) {
        _webSocketService.markSeen(message.id);
      }
    }
  }
}
