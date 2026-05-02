import 'package:messenger_app/data/models/presence.dart';
import 'package:messenger_app/data/models/profile.dart';

abstract class PresenceRepository {
  Future<PresenceStatus> getPresence(String username);
  Future<List<String>> getOnlineUsers();
  Future<Profile> getUserProfile(String username);
}
