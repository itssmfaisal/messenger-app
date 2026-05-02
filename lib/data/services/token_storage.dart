import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:messenger_app/core/app_constants.dart';

class TokenStorage {
  final _storage = const FlutterSecureStorage();

  Future<String?> getToken() async {
    return _storage.read(key: AppConstants.tokenKey);
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: AppConstants.tokenKey, value: token);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: AppConstants.tokenKey);
  }
}
