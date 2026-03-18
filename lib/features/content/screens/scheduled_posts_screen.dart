import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/page_switcher/models/managed_page_model.dart';
import '../../../features/page_switcher/providers/managed_pages_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/qp_loading.dart';
import '../models/content_models.dart';
import '../providers/content_provider.dart';
import '../widgets/countdown_timer.dart';
import '../widgets/edit_scheduled_modal.dart';
import '../widgets/schedule_post_modal.dart';

/// Dedicated screen for managing scheduled posts with live countdown
/// timers, status filters, and edit/delete/publish-now actions.
class ScheduledPostsScreen extends StatefulWidget {
  const ScheduledPostsScreen({super.key});

  @override
  State<ScheduledPostsScreen> createState() => _ScheduledPostsScreenState();
}

class _ScheduledPostsScreenState extends State<ScheduledPostsScreen> {
  String? _lastPageId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    context.read<ContentProvider>().stopPolling();
    super.dispose();
  }

  void _load() {
    final pageId = context.read<ManagedPagesProvider>().activePageId;
    if (pageId != null) {
      _lastPageId = pageId;
      final cp = context.read<ContentProvider>();
      cp.fetchScheduledPosts(pageId);
      cp.startPolling(pageId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPageId = context.watch<ManagedPagesProvider>().activePageId;
    if (currentPageId != null && currentPageId != _lastPageId) {
      _lastPageId = currentPageId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load();
      });
    }

    final cp = context.watch<ContentProvider>();
    final ManagedPageModel? page = context.watch<ManagedPagesProvider>().activePage;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Scheduled Posts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => SchedulePostModal.show(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Status filter chips ──
          _StatusFilters(
            current: cp.scheduledStatusFilter,
            scheduledCount: cp.scheduledCount,
            failedCount: cp.failedCount,
            cancelledCount: cp.cancelledCount,
            onChanged: (f) {
              if (currentPageId != null) {
                cp.setScheduledStatusFilter(f, currentPageId);
              }
            },
          ),

          // ── Content list ──
          Expanded(
            child: _buildList(cp, currentPageId, page),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
      ContentProvider cp, String? pageId, ManagedPageModel? page) {
    if (cp.isScheduledLoading && cp.scheduledItems.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: QpLoading(itemCount: 3, height: 160),
      );
    }

    if (cp.scheduledItems.isEmpty) {
      return const EmptyState(
        icon: Icons.schedule,
        title: 'No scheduled posts',
        subtitle: 'Schedule your first post to see it here.',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (pageId != null) {
          await cp.fetchScheduledPosts(pageId);
        }
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (scrollInfo) {
          if (scrollInfo.metrics.pixels >
                  scrollInfo.metrics.maxScrollExtent - 200 &&
              !cp.isScheduledLoading &&
              cp.scheduledHasMore &&
              pageId != null) {
            cp.fetchScheduledPosts(pageId, loadMore: true);
          }
          return false;
        },
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: cp.scheduledItems.length,
          itemBuilder: (context, index) {
            return _ScheduledPostCard(
              item: cp.scheduledItems[index],
              pageName: page?.pageName ?? '',
              pageAvatar: page?.profilePic as String?,
              onPublishNow: () => _publishNow(pageId, cp.scheduledItems[index]),
              onEdit: () => _editItem(cp.scheduledItems[index]),
              onDelete: () =>
                  _deleteItem(pageId, cp.scheduledItems[index]),
            );
          },
        ),
      ),
    );
  }

  Future<void> _publishNow(String? pageId, ContentItem item) async {
    if (pageId == null) return;
    final cp = context.read<ContentProvider>();
    final ok = await cp.publishNow(pageId, item.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Publishing...' : 'Failed to publish'),
          backgroundColor: ok ? const Color(0xFF307777) : Colors.red,
        ),
      );
      if (ok) cp.fetchScheduledPosts(pageId);
    }
  }

  Future<void> _editItem(ContentItem item) async {
    await EditScheduledModal.show(context, item: item);
  }

  Future<void> _deleteItem(String? pageId, ContentItem item) async {
    if (pageId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.warning_amber_rounded,
            color: Colors.red[400], size: 36),
        title: const Text('Delete Scheduled Post?'),
        content: const Text(
          'This action cannot be undone. The scheduled post will be permanently cancelled.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep It'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final cp = context.read<ContentProvider>();
      final ok = await cp.deleteContent(pageId, item);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? 'Deleted' : 'Failed to delete'),
            backgroundColor: ok ? const Color(0xFF307777) : Colors.red,
          ),
        );
        if (ok) cp.fetchScheduledPosts(pageId);
      }
    }
  }
}

// ─── Status Filter Chips ──────────────────────────
class _StatusFilters extends StatelessWidget {
  final String current;
  final int scheduledCount;
  final int failedCount;
  final int cancelledCount;
  final ValueChanged<String> onChanged;

  const _StatusFilters({
    required this.current,
    required this.scheduledCount,
    required this.failedCount,
    required this.cancelledCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _chip('all', 'All', null),
            _chip('Scheduled', 'Scheduled',
                scheduledCount > 0 ? scheduledCount : null),
            _chip('Failed', 'Failed',
                failedCount > 0 ? failedCount : null),
            _chip('Cancelled', 'Cancelled',
                cancelledCount > 0 ? cancelledCount : null),
          ],
        ),
      ),
    );
  }

  Widget _chip(String value, String label, int? count) {
    final isActive = current == value;
    final displayLabel =
        count != null ? '$label ($count)' : label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF307777) : Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  isActive ? const Color(0xFF307777) : Colors.grey[300]!,
            ),
          ),
          child: Text(
            displayLabel,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Scheduled Post Card ──────────────────────────
class _ScheduledPostCard extends StatelessWidget {
  final ContentItem item;
  final String pageName;
  final String? pageAvatar;
  final VoidCallback onPublishNow;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ScheduledPostCard({
    required this.item,
    required this.pageName,
    this.pageAvatar,
    required this.onPublishNow,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: avatar + name + badges
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: pageAvatar != null
                      ? NetworkImage(
                          ApiConstants.pageProfileUrl(pageAvatar!))
                      : null,
                  child: pageAvatar == null
                      ? const Icon(Icons.store, size: 16)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pageName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          _StatusChip(status: item.status ?? 'Scheduled'),
                          const SizedBox(width: 6),
                          _ContentTypeChip(type: item.contentType),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Scheduled date
            if (item.scheduledFor != null)
              Text(
                DateFormat('EEE, MMM d, yyyy · h:mm a')
                    .format(item.scheduledFor!.toLocal()),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),

            // Countdown timer
            if (item.scheduledFor != null &&
                (item.status == 'Scheduled' || item.status == 'Publishing'))
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: CountdownTimer(
                  scheduledFor: item.scheduledFor!.toLocal(),
                  onExpired: () {},
                ),
              ),

            // Failure reason
            if (item.isFailed && item.failureReason != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        size: 14, color: Colors.red[700]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.failureReason!,
                        style: TextStyle(
                            fontSize: 12, color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Text preview
            if (item.displayText.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                item.displayText,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
            ],

            // Media grid
            if (item.media.isNotEmpty) ...[
              const SizedBox(height: 10),
              _MediaGrid(media: item.media),
            ],

            const SizedBox(height: 12),

            // Action buttons
            if (item.status == 'Scheduled' ||
                item.status == 'Failed') ...[
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (item.status == 'Scheduled')
                    _ActionButton(
                      icon: Icons.rocket_launch,
                      label: 'Publish Now',
                      color: const Color(0xFF307777),
                      onTap: onPublishNow,
                    ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    icon: Icons.edit,
                    label: 'Edit',
                    color: Colors.grey[700]!,
                    onTap: onEdit,
                  ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    icon: Icons.delete_outline,
                    label: 'Delete',
                    color: Colors.red[600]!,
                    onTap: onDelete,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Status Chip ──────────────────────────────────
class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status) {
      'Scheduled' => (Colors.teal, Icons.schedule),
      'Publishing' => (Colors.amber, Icons.autorenew),
      'Published' => (Colors.green, Icons.check_circle),
      'Failed' => (Colors.red, Icons.cancel),
      'Cancelled' => (Colors.grey, Icons.block),
      _ => (Colors.grey, Icons.help_outline),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color[700] ?? color),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color[700] ?? color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Content Type Chip ────────────────────────────
class _ContentTypeChip extends StatelessWidget {
  final String type;
  const _ContentTypeChip({required this.type});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (type) {
      'Post' => (Colors.blue, Icons.article),
      'Reel' => (Colors.pink, Icons.videocam),
      'Story' => (Colors.amber, Icons.auto_stories),
      _ => (Colors.grey, Icons.help_outline),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color[700] ?? color),
          const SizedBox(width: 4),
          Text(
            type,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color[700] ?? color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Media Grid ───────────────────────────────────
class _MediaGrid extends StatelessWidget {
  final List<ContentMedia> media;
  const _MediaGrid({required this.media});

  @override
  Widget build(BuildContext context) {
    final items = media.take(4).toList();
    final extra = media.length - 4;

    if (items.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _mediaImage(items[0], height: 180),
      );
    }

    return SizedBox(
      height: 140,
      child: Row(
        children: items.asMap().entries.map((e) {
          final i = e.key;
          final m = e.value;
          final isLast = i == items.length - 1 && extra > 0;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: i > 0 ? 4 : 0),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _mediaImage(m),
                  ),
                  if (isLast)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        color: Colors.black54,
                        alignment: Alignment.center,
                        child: Text(
                          '+$extra',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _mediaImage(ContentMedia m, {double? height}) {
    final url = ApiConstants.contentMediaDisplayUrl(
      url: m.url,
      thumbnailUrl: m.thumbnailUrl,
      type: m.type,
      mediaBaseDir: m.mediaBaseDir,
    );
    if (url.isEmpty) {
      return Container(
        height: height,
        color: Colors.grey[200],
        child: const Icon(Icons.image, color: Colors.grey),
      );
    }
    return Image.network(
      url,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        height: height,
        color: Colors.grey[200],
        child: const Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }
}

// ─── Action Button ────────────────────────────────
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
