import 'package:messenger_app/data/services/auth_service.dart';
import 'package:messenger_app/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthService _authService;

  AuthRepositoryImpl(this._authService);

  @override
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
  }) {
    return _authService.register(
      username: username,
      email: email,
      password: password,
    );
  }

  @override
  Future<String> login({
    required String username,
    required String password,
  }) {
    return _authService.login(username: username, password: password);
  }

  @override
  Future<void> logout() => _authService.logout();

  @override
  Future<String?> getToken() => _authService.getToken();
}
