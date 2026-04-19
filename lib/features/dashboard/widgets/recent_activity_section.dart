import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../models/dashboard_models.dart';

/// Recent activity timeline — user avatars + messages + relative time.
class RecentActivitySection extends StatelessWidget {
  final List<RecentActivity> activities;

  const RecentActivitySection({super.key, required this.activities});

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) return const SizedBox.shrink();

    // Show latest 8 activities
    final displayActivities = activities.take(8).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.dividerLight.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.timeline_rounded, size: 20, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Recent Activity',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 14),

          ...displayActivities.map((activity) => _ActivityRow(activity: activity)),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final RecentActivity activity;

  const _ActivityRow({required this.activity});

  IconData get _typeIcon => switch (activity.type) {
        'reaction' => Icons.favorite_rounded,
        'comment' => Icons.chat_bubble_rounded,
        'new_follower' => Icons.person_add_rounded,
        _ => Icons.notifications_rounded,
      };

  Color get _typeColor => switch (activity.type) {
        'reaction' => const Color(0xFFFF3B30),
        'comment' => AppColors.primary,
        'new_follower' => AppColors.success,
        _ => AppColors.textSecondaryLight,
      };

  @override
  Widget build(BuildContext context) {
    final avatarUrl = activity.userPic != null
        ? ApiConstants.userProfileUrl(activity.userPic)
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar with activity type badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.surfaceLight,
                backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                onBackgroundImageError: avatarUrl.isNotEmpty ? (_, __) {} : null,
                child: avatarUrl.isEmpty
                    ? Icon(Icons.person, size: 18, color: AppColors.textSecondaryLight)
                    : null,
              ),
              // Type badge (bottom-right corner)
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: _typeColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Icon(_typeIcon, size: 8, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // Message
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.message,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  Formatters.formatTimeAgo(activity.createdAt),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
