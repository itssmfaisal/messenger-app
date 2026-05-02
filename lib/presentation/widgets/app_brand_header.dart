import 'package:flutter/material.dart';
import 'package:messenger_app/core/app_colors.dart';
import 'package:messenger_app/core/app_text_styles.dart';

class AppBrandHeader extends StatelessWidget {
  const AppBrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.cloud, color: AppColors.primary),
        SizedBox(width: 10),
        Text(
          "Cirrus Blue",
          style: AppTextStyles.brand,
        ),
      ],
    );
  }
}
