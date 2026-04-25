import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Avatar Skeleton
            const CircleAvatar(radius: 60, backgroundColor: Colors.white),
            const SizedBox(height: 20),
            // Name Skeleton
            Container(width: 150, height: 24, color: Colors.white),
            const SizedBox(height: 8),
            // Email Skeleton
            Container(width: 200, height: 16, color: Colors.white),
            const SizedBox(height: 40),
            // Info Tiles Skeletons
            _buildTileSkeleton(),
            _buildTileSkeleton(),
            _buildTileSkeleton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTileSkeleton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }
}
