import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:messenger_app/core/app_constants.dart';
import 'package:messenger_app/data/models/conversation.dart';
import 'package:messenger_app/data/models/message_page.dart';
import 'package:messenger_app/data/models/presence.dart';
import 'package:messenger_app/data/models/profile.dart';
import 'package:messenger_app/data/services/token_storage.dart';

class ChatService {
  final TokenStorage _tokenStorage;

  ChatService({TokenStorage? tokenStorage})
      : _tokenStorage = tokenStorage ?? TokenStorage();

  Future<String?> _getToken() async => _tokenStorage.getToken();

  Future<Map<String, String>> _headers() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<ConversationPage> getConversations({int page = 0, int size = 20}) async {
    final response = await http.get(
      Uri.parse(
        '${AppConstants.apiBaseUrl}/messages/conversations?page=$page&size=$size',
      ),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      return ConversationPage.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Failed to load conversations");
    }
  }

  Future<MessagePage> getConversationHistory({
    required String withUser,
    int page = 0,
    int size = 20,
  }) async {
    final response = await http.get(
      Uri.parse(
        '${AppConstants.apiBaseUrl}/messages/conversation/$withUser?page=$page&size=$size',
      ),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      return MessagePage.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Failed to load conversation history");
    }
  }

  Future<PresenceStatus> getPresence(String username) async {
    final response = await http.get(
      Uri.parse('${AppConstants.apiBaseUrl}/presence/$username'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      return PresenceStatus.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Failed to get presence status");
    }
  }

  Future<List<String>> getOnlineUsers() async {
    final response = await http.get(
      Uri.parse('${AppConstants.apiBaseUrl}/presence'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<String>.from(data['onlineUsers']);
    } else {
      throw Exception("Failed to get online users");
    }
  }

  Future<Profile> getUserProfile(String username) async {
    final response = await http.get(
      Uri.parse('${AppConstants.apiBaseUrl}/profile/$username'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      return Profile.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("User not found");
    }
  }

  Future<AttachmentUploadResponse> uploadAttachment(http.MultipartFile file) async {
    final token = await _getToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${AppConstants.apiBaseUrl}/messages/attachment'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(file);

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      return AttachmentUploadResponse.fromJson(jsonDecode(body));
    } else {
      throw Exception(jsonDecode(body)['error'] ?? "Failed to upload attachment");
    }
  }
}

class AttachmentUploadResponse {
  final String attachmentUrl;
  final String attachmentName;
  final String attachmentType;
  final int attachmentSize;

  AttachmentUploadResponse({
    required this.attachmentUrl,
    required this.attachmentName,
    required this.attachmentType,
    required this.attachmentSize,
  });

  factory AttachmentUploadResponse.fromJson(Map<String, dynamic> json) {
    return AttachmentUploadResponse(
      attachmentUrl: json['attachmentUrl'] as String,
      attachmentName: json['attachmentName'] as String,
      attachmentType: json['attachmentType'] as String,
      attachmentSize: json['attachmentSize'] as int,
    );
  }
}
