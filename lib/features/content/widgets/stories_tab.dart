import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/page_switcher/providers/managed_pages_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/qp_loading.dart';
import '../models/content_models.dart';
import '../providers/content_provider.dart';

/// Stories tab with Active/Expired filter and story cards or empty state.
class StoriesTab extends StatefulWidget {
  const StoriesTab({super.key});

  @override
  State<StoriesTab> createState() => _StoriesTabState();
}

class _StoriesTabState extends State<StoriesTab> {
  String _filter = 'Active';
  String? _lastPageId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStories());
  }

  void _loadStories() {
    final pageId = context.read<ManagedPagesProvider>().activePageId;
    if (pageId != null) {
      _lastPageId = pageId;
      context.read<ContentProvider>().fetchContentByType(pageId, 'Story');
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
          context.read<ContentProvider>().fetchContentByType(currentPageId, 'Story');
        }
      });
    }

    final content = context.watch<ContentProvider>();
    final stories = content.storyItems;

    return Column(
      children: [
        // Filter row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _FilterDropdown(
                value: _filter,
                items: const ['Active', 'Expired'],
                onChanged: (val) {
                  setState(() => _filter = val);
                },
              ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: content.isTypeLoading && stories.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: QpLoading(itemCount: 3, height: 120),
                )
              : stories.isEmpty
                  ? _emptyState()
                  : RefreshIndicator(
                      onRefresh: () async => _loadStories(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: stories.length,
                        itemBuilder: (context, index) {
                          return _StoryCard(item: stories[index]);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Illustration placeholder
          Container(
            width: 180,
            height: 180,
            margin: const EdgeInsets.only(bottom: 24),
            child: Icon(
              Icons.amp_stories_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
          ),
          const Text(
            'No active stories',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your active stories will appear here.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // TODO: Navigate to create story
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Create Story',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _resolveMediaUrl(ContentMedia media) {
  final url = media.url;
  if (url.startsWith('http')) return url;
  final dir = media.mediaBaseDir;
  if (dir != null && dir.isNotEmpty) {
    return '${ApiConstants.serverOrigin}/uploads/$dir/$url';
  }
  return '${ApiConstants.serverOrigin}/uploads/$url';
}

class _StoryCard extends StatelessWidget {
  final ContentItem item;
  const _StoryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Story thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: item.media.isNotEmpty
                  ? Image.network(
                      _resolveMediaUrl(item.media.first),
                      width: 60,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 60,
                        height: 80,
                        color: AppColors.surfaceLight,
                        child: const Icon(Icons.amp_stories),
                      ),
                    )
                  : Container(
                      width: 60,
                      height: 80,
                      color: AppColors.surfaceLight,
                      child: const Icon(Icons.amp_stories),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.displayText.isNotEmpty ? item.displayText : 'Story',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.visibility_outlined,
                          size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        '${item.viewCount} views',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  const _FilterDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.dividerLight),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
          items: items
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
        ),
      ),
    );
  }
}
