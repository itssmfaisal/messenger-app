import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:messenger_app/core/app_constants.dart';
import 'package:messenger_app/data/services/token_storage.dart';

class AuthService {
  final TokenStorage _tokenStorage;

  AuthService({TokenStorage? tokenStorage})
      : _tokenStorage = tokenStorage ?? TokenStorage();

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConstants.apiBaseUrl}/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "username": username,
        "email": email,
        "password": password,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
        jsonDecode(response.body)['error'] ?? "Failed to register",
      );
    }
  }

  Future<String> login({
    required String username,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConstants.apiBaseUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"username": username, "password": password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'] as String;
      await _tokenStorage.saveToken(token);
      return token;
    } else if (response.statusCode == 401) {
      throw Exception("Invalid credentials");
    } else {
      throw Exception("Server error: ${response.statusCode}");
    }
  }

  Future<void> logout() async {
    await _tokenStorage.deleteToken();
  }

  Future<String?> getToken() async {
    return _tokenStorage.getToken();
  }
}
