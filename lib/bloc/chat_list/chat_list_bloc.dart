import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:messenger_app/bloc/chat_list/chat_list_event.dart';
import 'package:messenger_app/bloc/chat_list/chat_list_state.dart';
import 'package:messenger_app/domain/repositories/chat_repository.dart';

class ChatListBloc extends Bloc<ChatListEvent, ChatListState> {
  final ChatRepository _repository;

  ChatListBloc(this._repository) : super(ChatListInitial()) {
    on<LoadConversations>(_onLoadConversations);
    on<RefreshConversations>(_onRefreshConversations);
  }

  Future<void> _onLoadConversations(
    LoadConversations event,
    Emitter<ChatListState> emit,
  ) async {
    if (event.page == 0) {
      emit(ChatListLoading());
    } else if (state is ChatListLoaded) {
      final current = state as ChatListLoaded;
      emit(current.copyWith(isLoadingMore: true));
    }

    try {
      final page = await _repository.getConversations(
        page: event.page,
        size: 20,
      );
      if (event.page > 0 && state is ChatListLoaded) {
        final current = state as ChatListLoaded;
        final combined = current.conversationPage.conversations + page.conversations;
        emit(ChatListLoaded(
          page.copyWith(conversations: combined),
          isLoadingMore: false,
        ));
      } else {
        emit(ChatListLoaded(page));
      }
    } catch (e) {
      if (state is ChatListLoaded) {
        final current = state as ChatListLoaded;
        emit(current.copyWith(isLoadingMore: false));
      } else {
        emit(ChatListError(e.toString()));
      }
    }
  }

  Future<void> _onRefreshConversations(
    RefreshConversations event,
    Emitter<ChatListState> emit,
  ) async {
    add(const LoadConversations(page: 0));
  }
}
