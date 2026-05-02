import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:messenger_app/core/app_constants.dart';
import 'package:messenger_app/data/services/token_storage.dart';

class ChatService {
  final TokenStorage _tokenStorage;

  ChatService({TokenStorage? tokenStorage})
      : _tokenStorage = tokenStorage ?? TokenStorage();

  Future<Map<String, dynamic>> getChatList({
    int page = 0,
    int size = 20,
  }) async {
    final token = await _tokenStorage.getToken();

    final response = await http.get(
      Uri.parse(
        '${AppConstants.apiBaseUrl}/messages/conversations?page=$page&size=$size',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load chat list");
    }
  }
}
