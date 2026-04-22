import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  final String baseUrl =
      "https://messenger.otaworkstation.shop/api"; // Replace with your server IP for physical devices

  // 1. Register Functionality
  Future<Map<String, dynamic>> register(
    String username,
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "username": username,
        "email": email,
        "password": password,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body); // Returns {"username": "john"}
    } else {
      throw Exception(
        jsonDecode(response.body)['error'] ?? "Failed to register",
      );
    }
  }

  // 2. Login Functionality
  Future<String> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"username": username, "password": password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['token']; // Returns the JWT token
    } else if (response.statusCode == 401) {
      throw Exception("Invalid credentials");
    } else {
      throw Exception("Server error: ${response.statusCode}");
    }
  }
}
