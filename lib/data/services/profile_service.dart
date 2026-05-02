import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:messenger_app/core/app_constants.dart';
import 'package:messenger_app/data/models/profile.dart';
import 'package:messenger_app/data/services/token_storage.dart';

class ProfileService {
  final TokenStorage _tokenStorage;

  ProfileService({TokenStorage? tokenStorage})
      : _tokenStorage = tokenStorage ?? TokenStorage();

  Future<Profile> getProfile() async {
    final token = await _tokenStorage.getToken();

    final response = await http.get(
      Uri.parse('${AppConstants.apiBaseUrl}/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Profile.fromJson(data);
    } else {
      throw Exception("Failed to load profile data");
    }
  }
}
