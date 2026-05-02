import 'package:messenger_app/data/models/profile.dart';
import 'package:messenger_app/data/services/profile_service.dart';
import 'package:messenger_app/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileService _profileService;

  ProfileRepositoryImpl(this._profileService);

  @override
  Future<Profile> getProfile() => _profileService.getProfile();
}
