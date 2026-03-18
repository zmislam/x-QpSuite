import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/page_switcher/providers/managed_pages_provider.dart';
import '../../../features/posts/providers/post_provider.dart';
import '../../../features/posts/widgets/post_card.dart';
import '../../../features/posts/widgets/comment_modal.dart';
import '../../../features/posts/widgets/reactions_bottom_sheet.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/qp_loading.dart';
import '../providers/content_provider.dart';
import '../widgets/content_post_card.dart';
import '../widgets/reels_tab.dart';
import '../widgets/stories_tab.dart';
import '../widgets/mentions_tab.dart';
import '../widgets/photos_tab.dart';
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
    _tabController.dispose();
    super.dispose();
  }

  void _loadPostsOnOpen() {
    final pageId = context.read<ManagedPagesProvider>().activePageId;
    if (pageId != null) {
      _lastPageId = pageId;
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
                      final posted = await SchedulePostModal.show(context);
                      // Safety net: refresh posts again after modal closes
                      if (mounted && posted == true) {
                        final pid = context.read<ManagedPagesProvider>().activePageId;
                        if (pid != null) {
                          context.read<PostProvider>().fetchPagePosts(pid, refresh: true);
                        }
                      }
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Create'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
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
                labelPadding:
                    const EdgeInsets.symmetric(horizontal: 16),
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
    final pageId = context.watch<ManagedPagesProvider>().activePageId;

    return Column(
      children: [
        // ── Sub-header: "Published ▼  Feed" ──
        _PostsSubHeader(
          currentFilter: contentProvider.postsFilter,
          onFilterChanged: (f) => contentProvider.setPostsFilter(f),
        ),
        // ── Posts list ──
        Expanded(child: _buildPostsList(context, postProvider, pageId)),
      ],
    );
  }

  Widget _buildPostsList(
      BuildContext context, PostProvider postProvider, String? pageId) {
    if (postProvider.isLoading && postProvider.posts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: QpLoading(itemCount: 3, height: 200),
      );
    }

    if (postProvider.error != null && postProvider.posts.isEmpty) {
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
                  postProvider.fetchPagePosts(pageId, refresh: true);
                }
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (postProvider.posts.isEmpty) {
      return const EmptyState(
        icon: Icons.article_outlined,
        title: 'No posts yet',
        subtitle: 'Create your first post to get started.',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (pageId != null) {
          await postProvider.fetchPagePosts(pageId, refresh: true);
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: postProvider.posts.length,
        itemBuilder: (context, index) {
          final post = postProvider.posts[index];
          return Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: ContentPostCard(post: post, index: index),
          );
        },
      ),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  Icon(Icons.arrow_drop_down,
                      size: 20, color: Colors.grey[700]),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // "Feed" chip
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            icon: Icon(Icons.calendar_month_outlined,
                size: 22, color: Colors.grey[700]),
            onPressed: () => context.push('/content/calendar'),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
                minWidth: 36, minHeight: 36),
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
                      color: isSelected
                          ? AppColors.primary
                          : Colors.grey[600],
                    ),
                    title: Text(
                      opt,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isSelected
                            ? AppColors.primary
                            : Colors.black87,
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

  static const _filterOptions = ['Published', 'Scheduled', 'Drafts'];

  IconData _iconForFilter(String filter) {
    switch (filter) {
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

