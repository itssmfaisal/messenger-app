import 'package:messenger_app/data/models/profile.dart';

abstract class ProfileRepository {
  Future<Profile> getProfile();
}
