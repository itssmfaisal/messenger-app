abstract class AuthRepository {
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
  });

  Future<String> login({
    required String username,
    required String password,
  });

  Future<void> logout();

  Future<String?> getToken();
}
