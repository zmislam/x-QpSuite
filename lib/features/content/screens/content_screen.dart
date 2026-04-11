import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/page_switcher/providers/managed_pages_provider.dart';
import '../../../features/posts/providers/post_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/qp_loading.dart';
import '../models/content_models.dart';
import '../providers/content_provider.dart';
import '../widgets/countdown_timer.dart';
import '../widgets/edit_scheduled_modal.dart';
import '../widgets/local_video_preview.dart';
import '../widgets/media_viewer_modal.dart';
import '../widgets/network_video_preview.dart';
import '../widgets/reels_tab.dart';
import '../widgets/stories_tab.dart';
import '../widgets/mentions_tab.dart';
import '../widgets/photos_tab.dart';
import '../widgets/edit_post_modal.dart';
import '../widgets/schedule_post_modal.dart';

class ContentScreen extends StatefulWidget {
  const ContentScreen({super.key});

  @override
  State<ContentScreen> createState() => _ContentScreenState();
}

class _ContentScreenState extends State<ContentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _lastPageId;

  static const _tabs = [
    'Posts',
    'Reels',
    'Stories',
    'Mentions and tags',
    'Photos',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPostsOnOpen());
  }

  @override
  void dispose() {
    context.read<ContentProvider>().stopPolling();
    _tabController.dispose();
    super.dispose();
  }

  void _loadPostsOnOpen() {
    final pageId = context.read<ManagedPagesProvider>().activePageId;
    if (pageId != null) {
      _lastPageId = pageId;
      // Unified content fetch (published + scheduled merged)
      final cp = context.read<ContentProvider>();
      cp.fetchContent(pageId);
      // Start polling so Publishing items auto-transition
      cp.startPolling(pageId);
      // Also keep PostProvider loaded for other tabs/features
      context.read<PostProvider>().fetchPagePosts(pageId, refresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch for page changes and reload posts
    final pageId = context.watch<ManagedPagesProvider>().activePageId;
    if (pageId != null && pageId != _lastPageId) {
      _lastPageId = pageId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<ContentProvider>().fetchContent(pageId);
          context.read<PostProvider>().fetchPagePosts(pageId, refresh: true);
        }
      });
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // ── Header: "Content" + Create button ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
              child: Row(
                children: [
                  const Text(
                    'Content',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () async {
                      await SchedulePostModal.show(context);
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Create'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // ── Tab Bar ──
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[300]!, width: 0.5),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: AppColors.primary,
                unselectedLabelColor: Colors.grey[600],
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                tabAlignment: TabAlignment.start,
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                tabs: _tabs.map((t) => Tab(text: t)).toList(),
              ),
            ),
            // ── Tab Body ──
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _PostsTab(),
                  ReelsTab(),
                  StoriesTab(),
                  MentionsTab(),
                  PhotosTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// ── POSTS TAB ──
// ═══════════════════════════════════════════════════════

class _PostsTab extends StatelessWidget {
  const _PostsTab();

  @override
  Widget build(BuildContext context) {
    final postProvider = context.watch<PostProvider>();
    final contentProvider = context.watch<ContentProvider>();
    final pagesProvider = context.watch<ManagedPagesProvider>();
    final pageId = pagesProvider.activePageId;
    final page = pagesProvider.activePage;
    final pageName = page?.pageName ?? 'Your Page';
    final pageAvatar = page?.profilePic;

    return Column(
      children: [
        // ── Sub-header: "Published ▼  Feed" ──
        _PostsSubHeader(
          currentFilter: contentProvider.postsFilter,
          onFilterChanged: (f) => contentProvider.setPostsFilter(f, pageId: pageId),
        ),
        // ── Posts list ──
        Expanded(
          child: _buildPostsList(
            context,
            postProvider,
            contentProvider,
            pageId,
            currentFilter: contentProvider.postsFilter,
            pageName: pageName,
            pageAvatar: pageAvatar,
          ),
        ),
      ],
    );
  }

  Widget _buildPostsList(
    BuildContext context,
    PostProvider postProvider,
    ContentProvider contentProvider,
    String? pageId, {
    required String currentFilter,
    required String pageName,
    String? pageAvatar,
  }) {
    if (currentFilter == 'Drafts') {
      return const EmptyState(
        icon: Icons.edit_note_outlined,
        title: 'No drafts yet',
        subtitle: 'Draft support will be available soon.',
      );
    }

    // Unified content list (published + scheduled merged, or filtered)
    return _buildUnifiedContentList(
      context,
      contentProvider,
      postProvider,
      pageId,
      pageName: pageName,
      pageAvatar: pageAvatar,
    );
  }

  Widget _buildUnifiedContentList(
    BuildContext context,
    ContentProvider contentProvider,
    PostProvider postProvider,
    String? pageId, {
    required String pageName,
    String? pageAvatar,
  }) {
    final pendingNow = pageId == null
        ? const <PendingContentUpload>[]
        : contentProvider.pendingNowUploadsForPage(pageId);
    final pendingScheduled = pageId == null
        ? const <PendingContentUpload>[]
        : contentProvider.pendingScheduledUploadsForPage(pageId);
    final allPending = [...pendingNow, ...pendingScheduled];

    final items = contentProvider.items;

    if (contentProvider.isLoading && items.isEmpty && allPending.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: QpLoading(itemCount: 3, height: 200),
      );
    }

    if (contentProvider.error != null && items.isEmpty && allPending.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'Could not load posts',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                if (pageId != null) {
                  contentProvider.fetchContent(pageId);
                }
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (items.isEmpty && allPending.isEmpty) {
      return const EmptyState(
        icon: Icons.article_outlined,
        title: 'No posts yet',
        subtitle: 'Create your first post to get started.',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (pageId != null) {
          await contentProvider.fetchContent(pageId);
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: allPending.length + items.length,
        itemBuilder: (context, index) {
          // Pending uploads first
          if (index < allPending.length) {
            final upload = allPending[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: _PendingUploadCard(
                upload: upload,
                pageName: pageName,
                pageAvatar: pageAvatar,
                onDismiss: () => context
                    .read<ContentProvider>()
                    .removePendingUpload(upload.id),
              ),
            );
          }

          final item = items[index - allPending.length];

          // Scheduled items → scheduled card with countdown
          if (item.isScheduled) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: _ContentScheduledPostCard(
                item: item,
                pageId: pageId,
                pageName: pageName,
                pageAvatar: pageAvatar,
              ),
            );
          }

          // Published items → published content card
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: _ContentPublishedCard(
              item: item,
              pageId: pageId,
              pageName: pageName,
              pageAvatar: pageAvatar,
            ),
          );
        },
      ),
    );
  }
}

class _PendingUploadCard extends StatelessWidget {
  final PendingContentUpload upload;
  final String pageName;
  final String? pageAvatar;
  final VoidCallback onDismiss;

  const _PendingUploadCard({
    required this.upload,
    required this.pageName,
    this.pageAvatar,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: pageAvatar != null && pageAvatar!.isNotEmpty
                      ? NetworkImage(ApiConstants.pageProfileUrl(pageAvatar!))
                      : null,
                  child: pageAvatar == null || pageAvatar!.isEmpty
                      ? const Icon(Icons.store, size: 16)
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pageName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        upload.isNow
                            ? 'Posting now'
                            : upload.scheduledFor != null
                            ? 'Scheduled · ${DateFormat('MMM d, yyyy · h:mm a').format(upload.scheduledFor!.toLocal())}'
                            : 'Scheduling post',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                _PendingStatusChip(status: upload.status),
              ],
            ),
            if (upload.status != 'Published' &&
                upload.status != 'Scheduled' &&
                !upload.isFailed) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: const LinearProgressIndicator(minHeight: 4),
              ),
            ],
            if (upload.displayText.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                upload.displayText,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
            ],
            if (upload.media.isNotEmpty) ...[
              const SizedBox(height: 10),
              _PendingMediaGrid(media: upload.media),
            ],
            if (upload.isFailed && upload.errorMessage != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error_outline, size: 14, color: Colors.red[700]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        upload.errorMessage!,
                        style: TextStyle(fontSize: 12, color: Colors.red[700]),
                      ),
                    ),
                    TextButton(
                      onPressed: onDismiss,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 28),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: const Text('Dismiss'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PendingStatusChip extends StatelessWidget {
  final String status;
  const _PendingStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    switch (status) {
      case 'Queued':
        color = Colors.blueGrey;
        icon = Icons.hourglass_bottom;
        break;
      case 'Uploading':
        color = Colors.blue;
        icon = Icons.cloud_upload;
        break;
      case 'Scheduling':
        color = Colors.teal;
        icon = Icons.schedule;
        break;
      case 'Publishing':
        color = Colors.amber;
        icon = Icons.autorenew;
        break;
      case 'Published':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'Scheduled':
        color = Colors.teal;
        icon = Icons.event_available;
        break;
      case 'Failed':
        color = Colors.red;
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingMediaGrid extends StatelessWidget {
  final List<PendingUploadMedia> media;

  const _PendingMediaGrid({required this.media});

  @override
  Widget build(BuildContext context) {
    final items = media.take(4).toList();
    final extra = media.length - 4;

    if (items.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _mediaItem(items.first, height: 180),
      );
    }

    return SizedBox(
      height: 140,
      child: Row(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final isLast = i == items.length - 1 && extra > 0;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _mediaItem(item),
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
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
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

  Widget _mediaItem(PendingUploadMedia media, {double? height}) {
    return Stack(
      fit: height != null ? StackFit.loose : StackFit.expand,
      children: [
        if (media.isVideo)
          LocalVideoPreview(file: media.file)
        else if (kIsWeb)
          Image.network(
            media.path,
            height: height,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, error, stackTrace) => Container(
              color: Colors.grey[200],
              child: const Icon(Icons.image, color: Colors.grey),
            ),
          )
        else
          Image.file(
            File(media.path),
            height: height,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, error, stackTrace) => Container(
              color: Colors.grey[200],
              child: const Icon(Icons.image, color: Colors.grey),
            ),
          ),
        if (media.isVideo)
          Positioned.fill(
            child: Center(
              child: Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Posts Sub-Header (Published ▼ + Feed) ─────────

class _PostsSubHeader extends StatelessWidget {
  final String currentFilter;
  final ValueChanged<String> onFilterChanged;

  const _PostsSubHeader({
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.white,
      child: Row(
        children: [
          // "Published ▼" dropdown button
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _showFilterSheet(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currentFilter,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_drop_down,
                    size: 20,
                    color: Colors.grey[700],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // "Feed" chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Feed',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          const Spacer(),
          // Calendar icon
          IconButton(
            icon: Icon(
              Icons.calendar_month_outlined,
              size: 22,
              color: Colors.grey[700],
            ),
            onPressed: () => context.push('/content/calendar'),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'View posts that are',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ..._filterOptions.map((opt) {
                  final isSelected = opt == currentFilter;
                  return ListTile(
                    leading: Icon(
                      _iconForFilter(opt),
                      color: isSelected ? AppColors.primary : Colors.grey[600],
                    ),
                    title: Text(
                      opt,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isSelected ? AppColors.primary : Colors.black87,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check, color: AppColors.primary)
                        : null,
                    onTap: () {
                      Navigator.pop(ctx);
                      onFilterChanged(opt);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  static const _filterOptions = ['Published & Scheduled', 'Published', 'Scheduled', 'Drafts'];

  IconData _iconForFilter(String filter) {
    switch (filter) {
      case 'Published & Scheduled':
        return Icons.all_inclusive;
      case 'Published':
        return Icons.check_circle_outline;
      case 'Scheduled':
        return Icons.schedule;
      case 'Drafts':
        return Icons.edit_note;
      default:
        return Icons.filter_list;
    }
  }
}

// ═══════════════════════════════════════════════════════
// ── PUBLISHED CONTENT CARD (from unified /content API) ──
// ═══════════════════════════════════════════════════════

class _ContentPublishedCard extends StatelessWidget {
  final ContentItem item;
  final String? pageId;
  final String pageName;
  final String? pageAvatar;

  const _ContentPublishedCard({
    required this.item,
    required this.pageId,
    required this.pageName,
    this.pageAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: avatar + name + date + Published badge ──
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: pageAvatar != null && pageAvatar!.isNotEmpty
                      ? NetworkImage(ApiConstants.pageProfileUrl(pageAvatar!))
                      : null,
                  child: pageAvatar == null || pageAvatar!.isEmpty
                      ? const Icon(Icons.store, size: 16)
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pageName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        DateFormat('MMM d, yyyy · h:mm a').format(item.createdAt.toLocal()),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                _PublishedStatusChip(isBoosted: item.isBoosted, isStory: item.isStory),
              ],
            ),

            // ── Story preview card ──
            if (item.isStory) ...[
              const SizedBox(height: 10),
              _StoryPreviewCard(item: item),
            ] else ...[
              // ── Post text ──
              if (item.displayText.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  item.displayText,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
              ],

              // ── Media grid ──
              if (item.media.isNotEmpty) ...[
                const SizedBox(height: 10),
                _PublishedMediaGrid(media: item.media),
              ],
            ],

            // ── Engagement metrics ──
            const SizedBox(height: 10),
            Row(
              children: [
                if (item.isStory && item.viewCount > 0) ...[
                  Icon(Icons.visibility_outlined, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${item.viewCount} views',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 12),
                ],
                if (item.likeCount > 0) ...[
                  Icon(Icons.thumb_up_alt_outlined, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${item.likeCount}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 12),
                ],
                if (item.commentCount > 0) ...[
                  Icon(Icons.chat_bubble_outline, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${item.commentCount}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 12),
                ],
                if (item.shareCount > 0) ...[
                  Icon(Icons.share_outlined, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${item.shareCount}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),

            // ── Action bar ──
            const SizedBox(height: 6),
            const Divider(height: 1),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    // Navigate to insights
                  },
                  icon: const Icon(Icons.insights, size: 16),
                  label: const Text('Insights'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
                // Stories can't be edited after publishing
                if (!item.isStory)
                  TextButton.icon(
                    onPressed: () => _edit(context),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                ),
                TextButton.icon(
                  onPressed: () => _delete(context),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red[600],
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
                if (item.isBoosted)
                  Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.rocket_launch, size: 12, color: Colors.orange[700]),
                        const SizedBox(width: 4),
                        Text(
                          'Boosted',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context) async {
    final postModel = item.toPostModel();
    final edited = await EditPostModal.show(context, post: postModel);
    if (edited == true && context.mounted && pageId != null) {
      await context.read<ContentProvider>().fetchContent(pageId!);
    }
  }

  Future<void> _delete(BuildContext context) async {
    if (pageId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete post?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final cp = context.read<ContentProvider>();
    final ok = await cp.deleteContent(pageId!, item);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Deleted' : 'Failed to delete'),
        backgroundColor: ok ? const Color(0xFF307777) : Colors.red,
      ),
    );
  }
}

class _PublishedStatusChip extends StatelessWidget {
  final bool isBoosted;
  final bool isStory;
  const _PublishedStatusChip({this.isBoosted = false, this.isStory = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isStory
            ? Colors.purple.withValues(alpha: 0.12)
            : Colors.green.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isStory ? Icons.auto_stories : Icons.check_circle,
            size: 12,
            color: isStory ? Colors.purple : Colors.green,
          ),
          const SizedBox(width: 4),
          Text(
            isStory ? 'Story' : 'Published',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isStory ? Colors.purple : Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}

/// Rich story preview card — shows the story as it appears to viewers,
/// with background color/image and centered text.
class _StoryPreviewCard extends StatelessWidget {
  final ContentItem item;
  const _StoryPreviewCard({required this.item});

  Color _parseColor(String? hex, [Color fallback = const Color(0xFF1877F2)]) {
    if (hex == null || hex.isEmpty) return fallback;
    final clean = hex.replaceAll('#', '');
    if (clean.length != 6) return fallback;
    return Color(int.parse('FF$clean', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final meta = item.storyMeta;
    final hasMedia = item.media.isNotEmpty;
    final hasBgImage = meta?.bgImageId != null;
    final bgColor = _parseColor(meta?.color);
    final textColor = _parseColor(meta?.textColor, Colors.white);

    // Use story aspect ratio so preview matches editor/viewer
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 9 / 16,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: hasMedia ? Colors.black : (hasBgImage ? Colors.black : bgColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image from story assets (text stories)
              if (hasBgImage && !hasMedia)
                Image.network(
                  '${ApiConstants.serverOrigin}/assets/stories/${meta!.bgImageId}.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: bgColor),
                ),

              // Photo story media — use contain to match editor framing
              // The uploaded image already has text/gradient baked in
              if (hasMedia)
                Image.network(
                  _resolveMediaUrl(item.media.first),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(color: Colors.grey[900]!),
                ),

              // Only overlay text for non-photo stories (text stories)
              // Photo stories have text baked into the uploaded image
              if (!hasMedia && item.displayText.isNotEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      item.displayText,
                      textAlign: TextAlign.center,
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontSize: meta?.fontSize?.clamp(14, 32) ?? 18,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                        shadows: hasBgImage
                            ? const [
                                Shadow(blurRadius: 8, color: Colors.black54),
                                Shadow(blurRadius: 16, color: Colors.black26),
                              ]
                            : null,
                      ),
                    ),
                  ),
                ),

            // "Story" badge overlay
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_stories, size: 12, color: Colors.white),
                    SizedBox(width: 4),
                    Text('Story',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
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
}

class _PublishedMediaGrid extends StatelessWidget {
  final List<ContentMedia> media;
  const _PublishedMediaGrid({required this.media});

  @override
  Widget build(BuildContext context) {
    final items = media.take(4).toList();
    final extra = media.length - 4;

    if (items.length == 1) {
      return GestureDetector(
        onTap: () => _openViewer(context, 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _mediaItem(items[0], height: 190),
        ),
      );
    }

    return SizedBox(
      height: 150,
      child: Row(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final m = entry.value;
          final isLast = i == items.length - 1 && extra > 0;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
              child: GestureDetector(
                onTap: () => _openViewer(context, i),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _mediaItem(m),
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
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _openViewer(BuildContext context, int index) {
    MediaViewerModal.show(
      context,
      mediaList: media
          .map(
            (m) => ViewableMedia(
              url: m.url,
              type: m.type,
              thumbnailUrl: m.thumbnailUrl,
              mediaBaseDir: m.mediaBaseDir,
              isScheduled: false,
            ),
          )
          .toList(),
      initialIndex: index,
    );
  }

  Widget _mediaItem(ContentMedia m, {double? height}) {
    final displayUrl = ApiConstants.contentMediaDisplayUrl(
      url: m.url,
      thumbnailUrl: m.thumbnailUrl,
      type: m.type,
      mediaBaseDir: m.mediaBaseDir,
      isScheduled: false,
    );
    final fullUrl = ApiConstants.contentMediaFullUrl(
      url: m.url,
      mediaBaseDir: m.mediaBaseDir,
      isScheduled: false,
    );

    return Stack(
      fit: height != null ? StackFit.loose : StackFit.expand,
      children: [
        if (displayUrl.isNotEmpty)
          Image.network(
            displayUrl,
            height: height,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, error, stackTrace) => Container(
              child: m.isVideo && fullUrl.isNotEmpty
                  ? NetworkVideoPreview(url: fullUrl, height: height)
                  : Container(
                      height: height,
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
            ),
          )
        else if (m.isVideo && fullUrl.isNotEmpty)
          NetworkVideoPreview(url: fullUrl, height: height)
        else
          Container(
            height: height,
            color: Colors.grey[200],
            child: Icon(
              m.isVideo ? Icons.videocam : Icons.image,
              color: Colors.grey,
            ),
          ),
        if (m.isVideo)
          Positioned.fill(
            child: Center(
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ContentScheduledPostCard extends StatelessWidget {
  final ContentItem item;
  final String? pageId;
  final String pageName;
  final String? pageAvatar;

  const _ContentScheduledPostCard({
    required this.item,
    required this.pageId,
    required this.pageName,
    this.pageAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: pageAvatar != null && pageAvatar!.isNotEmpty
                      ? NetworkImage(ApiConstants.pageProfileUrl(pageAvatar!))
                      : null,
                  child: pageAvatar == null || pageAvatar!.isEmpty
                      ? const Icon(Icons.store, size: 16)
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pageName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (item.scheduledFor != null)
                        Text(
                          'Scheduled · ${DateFormat('MMM d, yyyy · h:mm a').format(item.scheduledFor!.toLocal())}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                _ScheduledStatusChip(status: item.status ?? 'Scheduled'),
              ],
            ),
            if (item.scheduledFor != null &&
                (item.status == 'Scheduled' ||
                    item.status == 'Publishing')) ...[
              const SizedBox(height: 8),
              CountdownTimer(scheduledFor: item.scheduledFor!.toLocal()),
            ],
            if (item.displayText.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                item.displayText,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
            ],
            if (item.media.isNotEmpty) ...[
              const SizedBox(height: 10),
              _ScheduledMediaGrid(media: item.media),
            ],
            if (item.status == 'Scheduled' || item.status == 'Failed') ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              Row(
                children: [
                  if (item.status == 'Scheduled')
                    TextButton.icon(
                      onPressed: () => _publishNow(context),
                      icon: const Icon(Icons.rocket_launch, size: 16),
                      label: const Text('Publish now'),
                    ),
                  TextButton.icon(
                    onPressed: () => _reschedule(context),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Reschedule'),
                  ),
                  TextButton.icon(
                    onPressed: () => _delete(context),
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red[600],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _publishNow(BuildContext context) async {
    if (pageId == null) return;
    final cp = context.read<ContentProvider>();
    final ok = await cp.publishNow(pageId!, item.id);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Publishing...' : 'Failed to publish'),
        backgroundColor: ok ? const Color(0xFF307777) : Colors.red,
      ),
    );

    if (ok) {
      // Refresh both lists — publishNow also starts background polling
      await Future.wait([
        cp.fetchContent(pageId!),
        cp.fetchScheduledPosts(pageId!),
      ]);
      if (context.mounted) {
        await context.read<PostProvider>().fetchPagePosts(
          pageId!,
          refresh: true,
        );
      }
    }
  }

  Future<void> _reschedule(BuildContext context) async {
    if (pageId == null) return;
    await EditScheduledModal.show(context, item: item);
    if (!context.mounted) return;
    await context.read<ContentProvider>().fetchScheduledPosts(pageId!);
  }

  Future<void> _delete(BuildContext context) async {
    if (pageId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete scheduled post?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final cp = context.read<ContentProvider>();
    final ok = await cp.deleteContent(pageId!, item);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Deleted' : 'Failed to delete'),
        backgroundColor: ok ? const Color(0xFF307777) : Colors.red,
      ),
    );
  }
}

class _ScheduledStatusChip extends StatelessWidget {
  final String status;
  const _ScheduledStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    switch (status) {
      case 'Scheduled':
        color = Colors.teal;
        icon = Icons.schedule;
        break;
      case 'Publishing':
        color = Colors.amber;
        icon = Icons.autorenew;
        break;
      case 'Published':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'Failed':
        color = Colors.red;
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduledMediaGrid extends StatelessWidget {
  final List<ContentMedia> media;
  const _ScheduledMediaGrid({required this.media});

  @override
  Widget build(BuildContext context) {
    final items = media.take(4).toList();
    final extra = media.length - 4;

    if (items.length == 1) {
      return GestureDetector(
        onTap: () => _openViewer(context, 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _mediaItem(items[0], height: 190),
        ),
      );
    }

    return SizedBox(
      height: 150,
      child: Row(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final m = entry.value;
          final isLast = i == items.length - 1 && extra > 0;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
              child: GestureDetector(
                onTap: () => _openViewer(context, i),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _mediaItem(m),
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
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _openViewer(BuildContext context, int index) {
    MediaViewerModal.show(
      context,
      mediaList: media
          .map(
            (m) => ViewableMedia(
              url: m.url,
              type: m.type,
              thumbnailUrl: m.thumbnailUrl,
              mediaBaseDir: m.mediaBaseDir,
              isScheduled: true,
            ),
          )
          .toList(),
      initialIndex: index,
    );
  }

  Widget _mediaItem(ContentMedia m, {double? height}) {
    final displayUrl = ApiConstants.contentMediaDisplayUrl(
      url: m.url,
      thumbnailUrl: m.thumbnailUrl,
      type: m.type,
      mediaBaseDir: m.mediaBaseDir,
      isScheduled: true,
    );
    final fullUrl = ApiConstants.contentMediaFullUrl(
      url: m.url,
      mediaBaseDir: m.mediaBaseDir,
      isScheduled: true,
    );

    return Stack(
      fit: height != null ? StackFit.loose : StackFit.expand,
      children: [
        if (displayUrl.isNotEmpty)
          Image.network(
            displayUrl,
            height: height,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, error, stackTrace) => Container(
              child: m.isVideo && fullUrl.isNotEmpty
                  ? NetworkVideoPreview(url: fullUrl, height: height)
                  : Container(
                      height: height,
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
            ),
          )
        else if (m.isVideo && fullUrl.isNotEmpty)
          NetworkVideoPreview(url: fullUrl, height: height)
        else
          Container(
            height: height,
            color: Colors.grey[200],
            child: Icon(
              m.isVideo ? Icons.videocam : Icons.image,
              color: Colors.grey,
            ),
          ),
        if (m.isVideo)
          Positioned.fill(
            child: Center(
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
