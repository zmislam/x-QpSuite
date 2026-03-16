import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum BadgeStatus { active, paused, draft, completed, archived, rejected }

/// A small pill-shaped badge showing a status label with color coding.
class StatusBadge extends StatelessWidget {
  final BadgeStatus status;
  final String? customLabel;

  const StatusBadge({super.key, required this.status, this.customLabel});

  @override
  Widget build(BuildContext context) {
    final (color, label) = _resolve(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        customLabel ?? label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  static (Color, String) _resolve(BadgeStatus s) => switch (s) {
        BadgeStatus.active => (AppColors.activeDot, 'Active'),
        BadgeStatus.paused => (AppColors.pausedDot, 'Paused'),
        BadgeStatus.draft => (AppColors.draftDot, 'Draft'),
        BadgeStatus.completed => (AppColors.completedDot, 'Completed'),
        BadgeStatus.archived => (AppColors.archivedDot, 'Archived'),
        BadgeStatus.rejected => (AppColors.rejectedDot, 'Rejected'),
      };
}
