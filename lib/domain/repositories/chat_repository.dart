import 'package:http/http.dart' as http;
import 'package:messenger_app/data/models/conversation.dart';
import 'package:messenger_app/data/models/message_page.dart';

abstract class ChatRepository {
  Future<ConversationPage> getConversations({int page, int size});
  Future<MessagePage> getConversationHistory({
    required String withUser,
    int page,
    int size,
  });
  Future<Map<String, dynamic>> uploadAttachment(http.MultipartFile file);
}
