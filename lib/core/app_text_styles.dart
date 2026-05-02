import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static const String fontFamily = 'Poppins';

  static const TextStyle headline = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    fontFamily: fontFamily,
  );

  static const TextStyle title = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    fontFamily: fontFamily,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    fontFamily: fontFamily,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontFamily: fontFamily,
  );

  static const TextStyle label = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
    fontFamily: fontFamily,
  );

  static const TextStyle brand = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
    fontFamily: fontFamily,
  );

  static const TextStyle link = TextStyle(
    color: AppColors.primary,
    fontWeight: FontWeight.bold,
    fontFamily: fontFamily,
  );
}
