import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../models/dashboard_models.dart';

/// Top performing posts section — ranked list with thumbnails and engagement stats.
class TopPostsSection extends StatelessWidget {
  final List<TopPost> posts;

  const TopPostsSection({super.key, required this.posts});

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) return const SizedBox.shrink();

    // Show top 5 only
    final displayPosts = posts.take(5).toList();

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
          Row(
            children: [
              const Icon(Icons.star_rounded, size: 20, color: Color(0xFFF7B928)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Top Performing Posts',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
              if (posts.length > 5)
                Text(
                  'See all',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          ...List.generate(displayPosts.length, (i) {
            return _TopPostRow(post: displayPosts[i], rank: i + 1);
          }),
        ],
      ),
    );
  }
}

class _TopPostRow extends StatelessWidget {
  final TopPost post;
  final int rank;

  const _TopPostRow({required this.post, required this.rank});

  @override
  Widget build(BuildContext context) {
    // Resolve thumbnail URL
    final thumbnailUrl = post.media.isNotEmpty
        ? ApiConstants.postMediaUrl(post.media.first)
        : (post.image != null ? ApiConstants.postMediaUrl(post.image) : '');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rank number
          SizedBox(
            width: 20,
            child: Text(
              '#$rank',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: rank <= 3 ? AppColors.primary : AppColors.textSecondaryLight,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 50,
              height: 50,
              color: AppColors.surfaceLight,
              child: thumbnailUrl.isNotEmpty
                  ? Image.network(
                      thumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _PlaceholderIcon(type: post.type),
                    )
                  : _PlaceholderIcon(type: post.type),
            ),
          ),
          const SizedBox(width: 10),

          // Description + stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.description.isNotEmpty ? post.description : 'No description',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                // Engagement stats row
                Row(
                  children: [
                    _StatChip(icon: Icons.favorite_outline, value: post.likes),
                    const SizedBox(width: 10),
                    _StatChip(icon: Icons.chat_bubble_outline, value: post.comments),
                    const SizedBox(width: 10),
                    _StatChip(icon: Icons.share_outlined, value: post.shares),
                    if (post.views > 0) ...[
                      const SizedBox(width: 10),
                      _StatChip(icon: Icons.visibility_outlined, value: post.views),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Date
          Text(
            Formatters.formatTimeAgo(post.date),
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderIcon extends StatelessWidget {
  final String type;
  const _PlaceholderIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    final icon = type == 'video'
        ? Icons.videocam_rounded
        : type == 'reel'
            ? Icons.movie_outlined
            : Icons.image_outlined;
    return Center(child: Icon(icon, color: AppColors.textSecondaryLight, size: 22));
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final int value;

  const _StatChip({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textSecondaryLight),
        const SizedBox(width: 2),
        Text(
          Formatters.compactNumber(value),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}
