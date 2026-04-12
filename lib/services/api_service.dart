import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models.dart';

const String baseUrl = 'https://messenger.otaworkstation.shop/api';

class ApiService {
  String? _token;

  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('jwt_token');
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  String? getToken() => _token;

  Map<String, String> _headers({bool auth = true}) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (auth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // Auth endpoints
  Future<String> register(String username, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _headers(auth: false),
      body: jsonEncode({'username': username, 'email': email, 'password': password}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['username'];
    } else {
      throw Exception('Failed to register: ${response.body}');
    }
  }

  Future<String> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers(auth: false),
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (response.statusCode == 200) {
      final token = jsonDecode(response.body)['token'];
      await setToken(token);
      return token;
    } else {
      throw Exception('Invalid credentials');
    }
  }

  Future<void> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/forgot-password'),
      headers: _headers(auth: false),
      body: jsonEncode({'email': email}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to send OTP: ${response.body}');
    }
  }

  Future<void> verifyOtp(String email, String otp) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/verify-otp'),
      headers: _headers(auth: false),
      body: jsonEncode({'email': email, 'otp': otp}),
    );
    if (response.statusCode != 200) {
      throw Exception('Invalid OTP: ${response.body}');
    }
  }

  Future<void> resetPassword(String email, String otp, String newPassword) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/reset-password'),
      headers: _headers(auth: false),
      body: jsonEncode({'email': email, 'otp': otp, 'newPassword': newPassword}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to reset password: ${response.body}');
    }
  }

  // Messages endpoints
  Future<ConversationPage> getConversations({int page = 0, int size = 20}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/messages/conversations?page=$page&size=$size'),
      headers: _headers(),
    );
    if (response.statusCode == 200) {
      return ConversationPage.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch conversations');
    }
  }

  Future<MessagePage> getConversation(String withUser, {int page = 0, int size = 20}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/messages/conversation/$withUser?page=$page&size=$size'),
      headers: _headers(),
    );
    if (response.statusCode == 200) {
      return MessagePage.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch conversation');
    }
  }

  Future<Message> sendMessage(String recipient, String content, {String? attachmentUrl}) async {
    final body = {
      'recipient': recipient,
      'content': content,
    };
    if (attachmentUrl != null) {
      body['attachmentUrl'] = attachmentUrl;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/messages/send'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Message.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to send message: ${response.body}');
    }
  }

  Future<AttachmentUploadResponse> uploadAttachment(List<int> fileBytes, String fileName) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/messages/attachment'),
    );
    request.headers.addAll(_headers());
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      fileBytes,
      filename: fileName,
    ));
    final response = await request.send();
    if (response.statusCode == 200) {
      final body = await response.stream.bytesToString();
      return AttachmentUploadResponse.fromJson(jsonDecode(body));
    } else {
      throw Exception('Failed to upload attachment');
    }
  }

  // Presence endpoints
  Future<bool> checkPresence(String username) async {
    final response = await http.get(
      Uri.parse('$baseUrl/presence/$username'),
      headers: _headers(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['online'] ?? false;
    }
    return false;
  }

  Future<List<String>> getOnlineUsers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/presence'),
      headers: _headers(),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<String>.from(data['onlineUsers'] ?? []);
    }
    return [];
  }

  // Profile endpoints
  Future<Profile> getOwnProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/profile'),
      headers: _headers(),
    );
    if (response.statusCode == 200) {
      return Profile.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch profile');
    }
  }

  Future<Profile> getUserProfile(String username) async {
    final response = await http.get(
      Uri.parse('$baseUrl/profile/$username'),
      headers: _headers(),
    );
    if (response.statusCode == 200) {
      return Profile.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('User not found');
    }
  }

  Future<Profile> updateProfile(String? displayName, String? bio) async {
    final body = <String, dynamic>{};
    if (displayName != null) body['displayName'] = displayName;
    if (bio != null) body['bio'] = bio;

    final response = await http.put(
      Uri.parse('$baseUrl/profile'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      return Profile.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update profile');
    }
  }

  Future<Profile> uploadProfilePicture(List<int> fileBytes, String fileName) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/profile/picture'),
    );
    request.headers.addAll(_headers());
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      fileBytes,
      filename: fileName,
    ));
    final response = await request.send();
    if (response.statusCode == 200) {
      final body = await response.stream.bytesToString();
      return Profile.fromJson(jsonDecode(body));
    } else {
      throw Exception('Failed to upload profile picture');
    }
  }

  Future<void> sendEmailVerificationOtp(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/profile/email/send-otp'),
      headers: _headers(),
      body: jsonEncode({'email': email}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to send OTP: ${response.body}');
    }
  }

  Future<Profile> verifyEmailOtp(String otp) async {
    final response = await http.post(
      Uri.parse('$baseUrl/profile/email/verify'),
      headers: _headers(),
      body: jsonEncode({'otp': otp}),
    );
    if (response.statusCode == 200) {
      return Profile.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Invalid OTP');
    }
  }
}
