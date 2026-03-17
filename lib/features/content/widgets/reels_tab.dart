import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../features/page_switcher/providers/managed_pages_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/qp_loading.dart';
import '../models/content_models.dart';
import '../providers/content_provider.dart';

/// Grid view for Reels content with 3-column layout and platform badges.
class ReelsTab extends StatefulWidget {
  const ReelsTab({super.key});

  @override
  State<ReelsTab> createState() => _ReelsTabState();
}

class _ReelsTabState extends State<ReelsTab> {
  String? _lastPageId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadReels());
  }

  void _loadReels() {
    final pageId = context.read<ManagedPagesProvider>().activePageId;
    if (pageId != null) {
      _lastPageId = pageId;
      context.read<ContentProvider>().fetchContentByType(pageId, 'Reel');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch for page changes
    final currentPageId = context.watch<ManagedPagesProvider>().activePageId;
    if (currentPageId != null && currentPageId != _lastPageId) {
      _lastPageId = currentPageId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<ContentProvider>().fetchContentByType(currentPageId, 'Reel');
        }
      });
    }

    final content = context.watch<ContentProvider>();
    final reels = content.reelItems;

    if (content.isTypeLoading && reels.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: QpLoading(itemCount: 6, height: 150),
      );
    }

    if (reels.isEmpty) {
      return const EmptyState(
        icon: Icons.videocam_outlined,
        title: 'No reels yet',
        subtitle: 'Create your first reel to engage your audience.',
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadReels(),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
            childAspectRatio: 0.65,
          ),
          itemCount: reels.length,
          itemBuilder: (context, index) {
            final reel = reels[index];
            return _ReelGridItem(item: reel);
          },
        ),
      ),
    );
  }
}

class _ReelGridItem extends StatelessWidget {
  final ContentItem item;
  const _ReelGridItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final m = item.media.isNotEmpty ? item.media.first : null;
    final thumbnailUrl = m != null
        ? ApiConstants.contentMediaDisplayUrl(
            url: m.url,
            thumbnailUrl: m.thumbnailUrl,
            type: m.type,
            mediaBaseDir: m.mediaBaseDir ?? 'reels',
          )
        : '';

    return Stack(
      fit: StackFit.expand,
      children: [
        // Thumbnail
        thumbnailUrl.isNotEmpty
            ? Image.network(
                thumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.surfaceLight,
                  child: const Icon(Icons.videocam, color: Colors.grey),
                ),
              )
            : Container(
                color: AppColors.surfaceLight,
                child: const Icon(Icons.videocam, size: 32, color: Colors.grey),
              ),

        // Gradient overlay at bottom
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.6),
                ],
              ),
            ),
          ),
        ),

        // Heart icon top-left for reactions
        if (item.likeCount > 0)
          Positioned(
            top: 6,
            left: 6,
            child: Row(
              children: [
                const Icon(Icons.favorite, color: Colors.red, size: 14),
                const SizedBox(width: 2),
                Text(
                  Formatters.compactNumber(item.likeCount),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                  ),
                ),
              ],
            ),
          ),


      ],
    );
  }
}
