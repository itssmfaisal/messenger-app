import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:messenger_app/bloc/authbloc/auth_bloc.dart';
import 'package:messenger_app/bloc/authbloc/auth_event.dart';
import 'package:messenger_app/bloc/profile/profile_bloc.dart';
import 'package:messenger_app/bloc/profile/profile_event.dart';
import 'package:messenger_app/bloc/profile/profile_state.dart';
import 'package:messenger_app/core/app_colors.dart';
import 'package:messenger_app/core/app_constants.dart';
import 'package:messenger_app/core/app_text_styles.dart';
import 'package:messenger_app/data/models/profile.dart';
import 'package:messenger_app/presentation/profile_skeleton.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    context.read<ProfileBloc>().add(LoadProfile());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Profile",
          style: AppTextStyles.title,
        ),
      ),
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const ProfileSkeleton();
          } else if (state is ProfileLoaded) {
            return _buildProfileContent(state.profile, context);
          } else if (state is ProfileError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Error: ${state.message}"),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<ProfileBloc>().add(LoadProfile()),
                    child: const Text("Retry"),
                  ),
                ],
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildProfileContent(Profile profile, BuildContext context) {
    return SingleChildScrollView(
      padding: AppConstants.contentPadding,
      child: Column(
        children: [
          const CircleAvatar(
            radius: 60,
            backgroundColor: AppColors.primary,
            child: Icon(Icons.person, size: 60, color: Colors.white),
          ),
          const SizedBox(height: 20),
          Text(
            profile.username,
            style: AppTextStyles.title,
          ),
          if (profile.email != null)
            Text(
              profile.email!,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          const SizedBox(height: 40),
          _buildInfoTile(Icons.phone, "Phone", "Not provided"),
          _buildInfoTile(Icons.location_on, "Location", "Bangladesh"),
          const SizedBox(height: 40),
          _buildLogoutButton(context),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusCard),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.label),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => _showLogoutDialog(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusCard),
          ),
        ),
        child: const Text(
          "Log Out",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              dialogContext.read<AuthBloc>().add(LoggedOut());
            },
            child: const Text('Logout', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
