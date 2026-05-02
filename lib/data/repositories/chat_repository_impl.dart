import 'package:http/http.dart' as http;
import 'package:messenger_app/data/models/conversation.dart';
import 'package:messenger_app/data/models/message_page.dart';
import 'package:messenger_app/data/services/chat_service.dart';
import 'package:messenger_app/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatService _chatService;

  ChatRepositoryImpl(this._chatService);

  @override
  Future<ConversationPage> getConversations({int page = 0, int size = 20}) {
    return _chatService.getConversations(page: page, size: size);
  }

  @override
  Future<MessagePage> getConversationHistory({
    required String withUser,
    int page = 0,
    int size = 20,
  }) {
    return _chatService.getConversationHistory(
      withUser: withUser,
      page: page,
      size: size,
    );
  }

  @override
  Future<Map<String, dynamic>> uploadAttachment(http.MultipartFile file) async {
    final response = await _chatService.uploadAttachment(file);
    return {
      'attachmentUrl': response.attachmentUrl,
      'attachmentName': response.attachmentName,
      'attachmentType': response.attachmentType,
      'attachmentSize': response.attachmentSize,
    };
  }
}
