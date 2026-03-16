import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../features/page_switcher/providers/managed_pages_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/qp_loading.dart';
import '../../../shared/widgets/status_badge.dart';
import '../models/content_models.dart';
import '../providers/content_provider.dart';

class ContentScreen extends StatefulWidget {
  const ContentScreen({super.key});

  @override
  State<ContentScreen> createState() => _ContentScreenState();
}

class _ContentScreenState extends State<ContentScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadContent());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final pageId =
          context.read<ManagedPagesProvider>().activePageId;
      if (pageId != null) {
        context.read<ContentProvider>().fetchContent(pageId, loadMore: true);
      }
    }
  }

  void _loadContent() {
    final pageId =
        context.read<ManagedPagesProvider>().activePageId;
    if (pageId != null) {
      context.read<ContentProvider>().fetchContent(pageId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = context.watch<ContentProvider>();
    final pageId =
        context.watch<ManagedPagesProvider>().activePageId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Content'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () => context.go('/content/calendar'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/content/schedule'),
        icon: const Icon(Icons.add),
        label: const Text('Schedule'),
      ),
      body: Column(
        children: [
          // ── Filters ──
          _FilterBar(
            filter: content.filter,
            typeFilter: content.typeFilter,
            onFilterChanged: (f) {
              if (pageId != null) content.setFilter(f, pageId);
            },
            onTypeChanged: (t) {
              if (pageId != null) content.setTypeFilter(t, pageId);
            },
          ),
          // ── Content list ──
          Expanded(child: _buildList(content)),
        ],
      ),
    );
  }

  Widget _buildList(ContentProvider content) {
    if (content.isLoading && content.items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: QpLoading(itemCount: 4, height: 120),
      );
    }

    if (content.error != null && content.items.isEmpty) {
      return ErrorState(message: content.error!, onRetry: _loadContent);
    }

    if (content.items.isEmpty) {
      return const EmptyState(
        icon: Icons.article_outlined,
        title: 'No content yet',
        subtitle: 'Schedule your first post to get started.',
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadContent(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: content.items.length + (content.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= content.items.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _ContentCard(
            item: content.items[index],
            onDelete: () {
              final pageId =
                  context.read<ManagedPagesProvider>().activePageId;
              if (pageId != null) {
                _confirmDelete(context, content, pageId, content.items[index]);
              }
            },
            onPublishNow: content.items[index].isScheduled
                ? () {
                    final pageId =
                        context.read<ManagedPagesProvider>().activePageId;
                    if (pageId != null) {
                      content.publishNow(pageId, content.items[index].id);
                    }
                  }
                : null,
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, ContentProvider content,
      String pageId, ContentItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Content'),
        content: const Text('This cannot be undone. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              content.deleteContent(pageId, item);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ─── Filter Bar ────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final ContentFilter filter;
  final ContentTypeFilter typeFilter;
  final ValueChanged<ContentFilter> onFilterChanged;
  final ValueChanged<ContentTypeFilter> onTypeChanged;

  const _FilterBar({
    required this.filter,
    required this.typeFilter,
    required this.onFilterChanged,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Main filter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SegmentedButton<ContentFilter>(
            segments: const [
              ButtonSegment(value: ContentFilter.all, label: Text('All')),
              ButtonSegment(value: ContentFilter.published, label: Text('Published')),
              ButtonSegment(value: ContentFilter.scheduled, label: Text('Scheduled')),
            ],
            selected: {filter},
            onSelectionChanged: (s) => onFilterChanged(s.first),
          ),
        ),
        // Type chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: ContentTypeFilter.values.map((t) {
              final label = t == ContentTypeFilter.all
                  ? 'All'
                  : '${t.name[0].toUpperCase()}${t.name.substring(1)}s';
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(label),
                  selected: typeFilter == t,
                  onSelected: (_) => onTypeChanged(t),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ─── Content Card ──────────────────────────────────

class _ContentCard extends StatelessWidget {
  final ContentItem item;
  final VoidCallback onDelete;
  final VoidCallback? onPublishNow;

  const _ContentCard({
    required this.item,
    required this.onDelete,
    this.onPublishNow,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                if (item.isScheduled) ...[
                  StatusBadge(
                    status: item.isFailed
                        ? BadgeStatus.rejected
                        : BadgeStatus.active,
                    customLabel: item.status ?? 'Scheduled',
                  ),
                  const SizedBox(width: 8),
                ],
                if (item.isBoosted)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Boosted',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const Spacer(),
                _PopupMenu(
                  item: item,
                  onDelete: onDelete,
                  onPublishNow: onPublishNow,
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Text
            if (item.displayText.isNotEmpty)
              Text(
                item.displayText,
                style: theme.textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            // Media thumbnails
            if (item.media.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: item.media.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final m = item.media[i];
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        m.thumbnailUrl ?? m.url,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[300],
                          child: Icon(
                            m.type == 'video'
                                ? Icons.videocam
                                : Icons.image,
                            size: 24,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 8),
            // Date / Stats row
            if (item.isPublished)
              Row(
                children: [
                  _stat(Icons.favorite, item.likeCount),
                  const SizedBox(width: 12),
                  _stat(Icons.chat_bubble_outline, item.commentCount),
                  const SizedBox(width: 12),
                  _stat(Icons.share, item.shareCount),
                  const SizedBox(width: 12),
                  _stat(Icons.visibility, item.viewCount),
                  const Spacer(),
                  Text(
                    Formatters.formatTimeAgo(item.createdAt),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              )
            else
              Row(
                children: [
                  const Icon(Icons.schedule, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    item.scheduledFor != null
                        ? Formatters.formatDateTime(item.scheduledFor!)
                        : 'No date set',
                    style: theme.textTheme.bodySmall,
                  ),
                  if (item.isFailed && item.failureReason != null) ...[
                    const Spacer(),
                    Flexible(
                      child: Text(
                        item.failureReason!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.error,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _stat(IconData icon, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 2),
        Text(
          Formatters.compactNumber(count),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}

class _PopupMenu extends StatelessWidget {
  final ContentItem item;
  final VoidCallback onDelete;
  final VoidCallback? onPublishNow;

  const _PopupMenu({
    required this.item,
    required this.onDelete,
    this.onPublishNow,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (action) {
        switch (action) {
          case 'delete':
            onDelete();
            break;
          case 'publish_now':
            onPublishNow?.call();
            break;
        }
      },
      itemBuilder: (_) => [
        if (item.isScheduled && onPublishNow != null)
          const PopupMenuItem(
            value: 'publish_now',
            child: Text('Publish Now'),
          ),
        const PopupMenuItem(
          value: 'delete',
          child: Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}
