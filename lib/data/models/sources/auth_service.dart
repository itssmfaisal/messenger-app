import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthService {
  final String baseUrl =
      "https://messenger.otaworkstation.shop/api"; // Replace with your server IP for physical devices
  final _storage = const FlutterSecureStorage();

  // Register Functionality
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

  // Login Functionality
  Future<String> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"username": username, "password": password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      String token = data['token'];
      await _storage.write(key: 'jwt_token', value: token);
      return token; // Returns the JWT token
    } else if (response.statusCode == 401) {
      throw Exception("Invalid credentials");
    } else {
      throw Exception("Server error: ${response.statusCode}");
    }
  }

  // Profile Functionality
  Future<Map<String, dynamic>> getProfile() async {
    // 1. Get the token (usually from Secure Storage or a shared variable)
    String? token = await getToken();
    //print(token);

    final response = await http.get(
      Uri.parse('$baseUrl/profile'), // Standard endpoint for profile
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // Passing the JWT
      },
    );
    await getChatList();
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      token = data['token'];
      return data;
    } else {
      throw Exception("Failed to load profile data");
    }
  }

  // Logout Functionality
  Future<void> logout() async {
    // Delete the JWT
    await _storage.delete(key: 'jwt_token');
  }

  // List of Conversation
  Future<Map<String, dynamic>> getChatList() async {
    // 1. Get the token (usually from Secure Storage or a shared variable)
    String? token = await getToken();
    //print(token);

    final response = await http.get(
      Uri.parse(
        '$baseUrl/messages/conversations?page=0&size=20',
      ), // Standard endpoint for profile
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // Passing the JWT
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print(data);
      return data;
    } else {
      throw Exception("Failed to load chat list");
    }
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }
}
