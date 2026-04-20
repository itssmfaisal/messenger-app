import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;

  bool get isAuthenticated => _isAuthenticated;

  // Initialize and load saved state
  AuthProvider() {
    _loadAuthState();
  }

  // Load auth state from SharedPreferences on app start
  Future<void> _loadAuthState() async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    _isAuthenticated = pref.getString('isLoggedIn') == 'true';
    notifyListeners();
  }

  // Call this when user logs in
  Future<void> login() async {
    // Your login logic here (API call, validation, etc.)

    _isAuthenticated = true;

    // Save to SharedPreferences
    final SharedPreferences pref = await SharedPreferences.getInstance();
    await pref.setString('isLoggedIn', 'true');

    notifyListeners();
  }

  // Call this when user logs out
  Future<void> logout() async {
    _isAuthenticated = false;

    // Clear from SharedPreferences
    final SharedPreferences pref = await SharedPreferences.getInstance();
    await pref.setString('isLoggedIn', 'false');
    // Or use: await pref.remove('isLoggedIn');

    notifyListeners();
  }
}
