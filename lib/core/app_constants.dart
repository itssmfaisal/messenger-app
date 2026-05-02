import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  static const String apiBaseUrl = 'https://messenger.otaworkstation.shop/api';
  static const String tokenKey = 'jwt_token';

  static const double borderRadiusLarge = 28.0;
  static const double borderRadiusMedium = 25.0;
  static const double borderRadiusCard = 15.0;

  static const double buttonHeight = 56.0;
  static const double socialButtonHeight = 50.0;

  static final EdgeInsets screenPadding = const EdgeInsets.symmetric(horizontal: 24.0);
  static final EdgeInsets contentPadding = const EdgeInsets.all(24.0);
}
