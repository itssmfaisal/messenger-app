import 'package:messenger_app/data/models/presence.dart';
import 'package:messenger_app/data/models/profile.dart';
import 'package:messenger_app/data/services/chat_service.dart';
import 'package:messenger_app/domain/repositories/presence_repository.dart';

class PresenceRepositoryImpl implements PresenceRepository {
  final ChatService _chatService;

  PresenceRepositoryImpl(this._chatService);

  @override
  Future<PresenceStatus> getPresence(String username) {
    return _chatService.getPresence(username);
  }

  @override
  Future<List<String>> getOnlineUsers() {
    return _chatService.getOnlineUsers();
  }

  @override
  Future<Profile> getUserProfile(String username) {
    return _chatService.getUserProfile(username);
  }
}
