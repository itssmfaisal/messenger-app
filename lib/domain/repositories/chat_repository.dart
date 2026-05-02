abstract class ChatRepository {
  Future<Map<String, dynamic>> getChatList({int page, int size});
}
