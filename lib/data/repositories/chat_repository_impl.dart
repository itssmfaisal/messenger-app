import 'package:messenger_app/data/services/chat_service.dart';
import 'package:messenger_app/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatService _chatService;

  ChatRepositoryImpl(this._chatService);

  @override
  Future<Map<String, dynamic>> getChatList({int page = 0, int size = 20}) {
    return _chatService.getChatList(page: page, size: size);
  }
}
