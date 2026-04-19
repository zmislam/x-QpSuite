import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/page_switcher/providers/managed_pages_provider.dart';
import '../../../features/posts/providers/post_provider.dart';
import '../../../features/posts/widgets/comment_modal.dart';
import '../../../features/posts/widgets/post_card.dart';
import '../../../features/posts/widgets/reactions_bottom_sheet.dart';
import '../../../features/content/widgets/schedule_post_modal.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/qp_loading.dart';
import '../models/dashboard_models.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/demographics_section.dart';
import '../widgets/kpi_grid.dart';
import '../widgets/period_filter.dart';
import '../widgets/recent_activity_section.dart';
import '../widgets/top_posts_section.dart';
import '../widgets/trend_chart_section.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _lastPageId;
  bool _showPostsFeed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDashboard());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final pageId = context.read<ManagedPagesProvider>().activePageId;
    if (pageId != null && pageId != _lastPageId) {
      _lastPageId = pageId;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadDashboard());
    }
  }

  void _loadDashboard() {
    final pageId = context.read<ManagedPagesProvider>().activePageId;
    if (pageId != null) {
      _lastPageId = pageId;
      context.read<DashboardProvider>().fetchDashboard(pageId);
      // Posts are loaded on demand via "Manage Posts" button
    }
  }

  void _showPageSwitcher(
      BuildContext context, ManagedPagesProvider pagesProvider) {
    final allPages = pagesProvider.pages;
    final activeId = pagesProvider.activePage?.id;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.55,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[350],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              // Header
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Your account',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Page list
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: allPages.length,
                  itemBuilder: (_, i) {
                    final page = allPages[i];
                    final isActive = page.id == activeId;
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primary.withValues(alpha: 0.06)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        leading: _PageAvatar(
                          profilePicUrl: page.profilePicUrl,
                          pageName: page.pageName,
                          size: 48,
                        ),
                        title: Text(
                          page.pageName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          page.category ?? 'Page',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                        trailing: isActive
                            ? const Icon(Icons.check_circle,
                                color: AppColors.primary, size: 22)
                            : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onTap: () {
                          pagesProvider.setActivePage(page);
                          Navigator.pop(ctx);
                        },
                      ),
                    );
                  },
                ),
              ),
              SizedBox(
                  height: MediaQuery.of(ctx).padding.bottom + 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashProvider = context.watch<DashboardProvider>();
    final pagesProvider = context.watch<ManagedPagesProvider>();
    final currentPageId = pagesProvider.activePageId;

    // Auto-fetch dashboard when active page changes
    if (currentPageId != null && currentPageId != _lastPageId) {
      _lastPageId = currentPageId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<DashboardProvider>().fetchDashboard(currentPageId);
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: _buildBody(dashProvider, pagesProvider, pagesProvider.activePageId),
    );
  }

  Widget _buildBody(DashboardProvider dash, ManagedPagesProvider pages, String? currentPageId) {
    if (pages.activePage == null) {
      return const EmptyState(
        icon: Icons.business,
        title: 'No pages found',
        subtitle: 'Create a page to get started with QP Suite.',
      );
    }

    if (dash.isLoading && dash.data == null) {
      return const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: QpLoading(itemCount: 5, height: 100),
        ),
      );
    }

    if (dash.error != null && dash.data == null) {
      return ErrorState(
        message: dash.error!,
        onRetry: _loadDashboard,
      );
    }

    final data = dash.data;
    if (data == null) {
      return const EmptyState(
        icon: Icons.dashboard,
        title: 'No data yet',
        subtitle: 'Start posting content to see your dashboard.',
      );
    }

    final activePage = pages.activePage!;
    final hasCurrentPageData =
      currentPageId != null && dash.dataPageId == currentPageId;
    final pageInfo = hasCurrentPageData ? data.pageInfo : null;
    final followersCount = hasCurrentPageData
      ? data.kpis.followers.value
      : activePage.followersCount;

    return RefreshIndicator(
      onRefresh: () async => _loadDashboard(),
      child: CustomScrollView(
        slivers: [
          // ── Custom App Bar ──
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0.5,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.menu, color: Colors.black87, size: 26),
              onPressed: () {
                // TODO: open drawer / menu
              },
            ),
            title: GestureDetector(
              onTap: () => _showPageSwitcher(context, pages),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'QP Suite',
                    style: GoogleFonts.pacifico(
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down,
                      size: 22, color: AppColors.primary),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: Colors.black87, size: 26),
                onPressed: () => context.push('/notifications'),
              ),
            ],
          ),

          // ── Content ──
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Cover + Profile Hero ──
                _CoverProfileHero(
                  pageInfo: pageInfo,
                  activePage: activePage,
                  followersCount: followersCount,
                ),

                const SizedBox(height: 16),

                // ── Create Post Button ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        SchedulePostModal.show(context, initialPostMode: 'now');
                      },
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      label: const Text(
                        'Create post',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Quick Actions ──
                const _QuickActionsRow(),

                const SizedBox(height: 8),

                // ── Divider ──
                const Divider(
                    height: 24,
                    thickness: 8,
                    color: AppColors.surfaceLight),

                // ══════════════════════════════════════
                // ── Overview / Manage Posts Toggle ──
                // ══════════════════════════════════════
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        _showPostsFeed ? 'Posts' : 'Overview',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {
                          setState(() => _showPostsFeed = !_showPostsFeed);
                          if (_showPostsFeed) {
                            context
                                .read<PostProvider>()
                                .fetchPagePosts(currentPageId!, refresh: false);
                          }
                        },
                        icon: Icon(
                          _showPostsFeed
                              ? Icons.dashboard_outlined
                              : Icons.article_outlined,
                          size: 18,
                        ),
                        label: Text(
                          _showPostsFeed ? 'Overview' : 'Manage Posts',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ── Dashboard Overview (default view) ──
                if (!_showPostsFeed) ...[  
                  if (dash.isLoading)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Updating overview and trends...',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondaryLight,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (dash.error != null && !dash.isLoading)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF4E5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFFD3A1)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline,
                                size: 16, color: Color(0xFFB45309)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                dash.error!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF92400E),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // ── Period Filter Pills ──
                  PeriodFilter(
                    selectedPeriod: context.watch<DashboardProvider>().period,
                    isLoading: dash.isLoading,
                    onPeriodChanged: (days) {
                      context.read<DashboardProvider>().setPeriod(days, currentPageId!);
                    },
                  ),

                  const SizedBox(height: 16),

                  if (!hasCurrentPageData)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.dividerLight),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dash.isLoading
                                  ? 'Loading dashboard for ${activePage.pageName}...'
                                  : (dash.error ??
                                      'No dashboard data available for ${activePage.pageName}.'),
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondaryLight,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextButton.icon(
                              onPressed: _loadDashboard,
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('Retry'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                padding: EdgeInsets.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                minimumSize: const Size(0, 0),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    KpiGrid(kpis: data.kpis, trendData: data.trend),

                    const SizedBox(height: 24),

                    // ── Performance Trend Chart + Follower Growth ──
                    TrendChartSection(
                      trendData: data.trend,
                      selectedMetric: context.watch<DashboardProvider>().selectedMetric,
                      onMetricChanged: (metric) {
                        context.read<DashboardProvider>().setSelectedMetric(metric);
                      },
                    ),

                    const SizedBox(height: 16),

                    // ── Demographics (Gender, Age, Countries, Cities) ──
                    if (!data.demographics.isEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Audience',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DemographicsSection(demographics: data.demographics),
                      const SizedBox(height: 16),
                    ],

                    // ── Top Performing Posts ──
                    if (data.topPosts.isNotEmpty) ...[
                      TopPostsSection(posts: data.topPosts),
                      const SizedBox(height: 16),
                    ],

                    // ── Recent Activity ──
                    if (data.recentActivity.isNotEmpty) ...[
                      RecentActivitySection(activities: data.recentActivity),
                      const SizedBox(height: 16),
                    ],

                    // ── Divider ──
                    const Divider(
                        height: 32,
                        thickness: 8,
                        color: AppColors.surfaceLight),

                    // ── To-do List ──
                    _TodoListSection(
                      todos: data.todos,
                      recentActivity: data.recentActivity,
                      kpis: data.kpis,
                    ),
                  ],
                ],

                // ── Posts Feed (when toggled) ──
                if (_showPostsFeed) ...[  
                  const Divider(
                      height: 32,
                      thickness: 8,
                      color: AppColors.surfaceLight),
                  _PostsFeedSection(currentPageId: currentPageId!),
                ],

                const SizedBox(height: 8),

                // ── Onboarding ──
                if (hasCurrentPageData && !data.onboarding.isComplete) ...[
                  _OnboardingCard(onboarding: data.onboarding),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// ── Page Avatar Widget ──
// ─────────────────────────────────────────────────────

class _PageAvatar extends StatelessWidget {
  final String profilePicUrl;
  final String pageName;
  final double size;

  const _PageAvatar({
    required this.profilePicUrl,
    required this.pageName,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.surfaceLight,
      backgroundImage:
          profilePicUrl.isNotEmpty ? NetworkImage(profilePicUrl) : null,
      onBackgroundImageError:
          profilePicUrl.isNotEmpty
            ? (exception, stackTrace) {}
            : null,
      child: profilePicUrl.isEmpty
          ? Text(
              pageName.isNotEmpty ? pageName[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: size * 0.4,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            )
          : null,
    );
  }
}

// ─────────────────────────────────────────────────────
// ── Cover + Profile Hero Section ──
// ─────────────────────────────────────────────────────

class _CoverProfileHero extends StatelessWidget {
  final DashboardPageInfo? pageInfo;
  final dynamic activePage;
  final num followersCount;

  const _CoverProfileHero({
    required this.pageInfo,
    required this.activePage,
    required this.followersCount,
  });

  @override
  Widget build(BuildContext context) {
    final pageId = (pageInfo?.id.isNotEmpty ?? false)
      ? pageInfo!.id
      : activePage.id.toString();
    final coverUrl = pageInfo?.coverPic != null
        ? ApiConstants.pageCoverUrl(pageInfo!.coverPic)
        : '';
    final profileUrl = pageInfo?.profilePic != null
        ? ApiConstants.pageProfileUrl(pageInfo!.profilePic)
        : activePage.profilePicUrl;
    final pageName = pageInfo?.pageName ?? activePage.pageName;
    final category = pageInfo?.category ?? activePage.category ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Cover Photo + Overlapping Profile Pic ──
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Cover image
            GestureDetector(
              onTap: coverUrl.isNotEmpty
                  ? () => _ImagePreviewViewer.show(
                        context,
                        imageUrl: coverUrl,
                        heroTag: 'cover-$pageId',
                      )
                  : null,
              child: Hero(
                tag: 'cover-$pageId',
                child: Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    image: coverUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(coverUrl),
                            fit: BoxFit.cover,
                            onError: (exception, stackTrace) {},
                          )
                        : null,
                    gradient: coverUrl.isEmpty
                        ? const LinearGradient(
                            colors: [AppColors.primary, Color(0xFF5AB9E6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                  ),
                  child: coverUrl.isEmpty
                      ? const Center(
                          child: Icon(Icons.business_center,
                              color: Colors.white38, size: 48),
                        )
                      : null,
                ),
              ),
            ),

            // Profile pic overlapping bottom-left
            Positioned(
              left: 16,
              bottom: -32,
              child: GestureDetector(
                onTap: profileUrl.isNotEmpty
                    ? () => _ImagePreviewViewer.show(
                          context,
                          imageUrl: profileUrl,
                          heroTag: 'avatar-$pageId',
                        )
                    : null,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Hero(
                    tag: 'avatar-$pageId',
                    child: _PageAvatar(
                      profilePicUrl: profileUrl,
                      pageName: pageName,
                      size: 72,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 40),

        // ── Page Name + Edit Profile ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pageName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    if (category.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        category,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit profile'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  side: const BorderSide(color: AppColors.dividerLight),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // ── Follower Count ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: InkWell(
            onTap: () => _FollowersListSheet.show(
              context,
              pageId: pageId,
              pageName: pageName,
            ),
            borderRadius: BorderRadius.circular(4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  Formatters.compactNumber(followersCount),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'Followers',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.chevron_right,
                    size: 18, color: AppColors.textSecondaryLight),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────
// ── Quick Actions Row ──
// ─────────────────────────────────────────────────────

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _QuickActionItem(
            icon: Icons.videocam_rounded,
            label: 'Reel',
            color: const Color(0xFFFF3040),
            onTap: () => SchedulePostModal.show(context, initialPostMode: 'now', initialContentType: 'Reel'),
          ),
          _QuickActionItem(
            icon: Icons.add_circle_outline_rounded,
            label: 'Story',
            color: const Color(0xFFF7B928),
            onTap: () => SchedulePostModal.show(context, initialPostMode: 'now', initialContentType: 'Story'),
          ),
          _QuickActionItem(
            icon: Icons.campaign_rounded,
            label: 'Advertise',
            color: AppColors.success,
            onTap: () {
              final messenger = ScaffoldMessenger.of(context);
              messenger.hideCurrentSnackBar();
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Advertise is coming soon.'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          _QuickActionItem(
            icon: Icons.add_photo_alternate_outlined,
            label: 'Photo',
            color: AppColors.primary,
            onTap: () => SchedulePostModal.show(context, initialPostMode: 'now', initialContentType: 'Post'),
          ),
        ],
      ),
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePreviewViewer extends StatelessWidget {
  final String imageUrl;
  final String heroTag;

  const _ImagePreviewViewer({
    required this.imageUrl,
    required this.heroTag,
  });

  static Future<void> show(
    BuildContext context, {
    required String imageUrl,
    required String heroTag,
  }) {
    if (imageUrl.isEmpty) {
      return Future.value();
    }

    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (context, animation, secondaryAnimation) =>
            _ImagePreviewViewer(
          imageUrl: imageUrl,
          heroTag: heroTag,
        ),
        transitionsBuilder:
            (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 4.0,
              child: Hero(
                tag: heroTag,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white38,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.white38,
                      size: 64,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FollowersListSheet extends StatefulWidget {
  final String pageId;
  final String pageName;

  const _FollowersListSheet({
    required this.pageId,
    required this.pageName,
  });

  static Future<void> show(
    BuildContext context, {
    required String pageId,
    required String pageName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FollowersListSheet(pageId: pageId, pageName: pageName),
    );
  }

  @override
  State<_FollowersListSheet> createState() => _FollowersListSheetState();
}

class _FollowersListSheetState extends State<_FollowersListSheet> {
  bool _isLoading = true;
  String? _error;
  List<_FollowerListItem> _followers = const [];

  @override
  void initState() {
    super.initState();
    _loadFollowers();
  }

  Future<void> _loadFollowers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = context.read<ApiService>();
      final res = await api.post(
        ApiConstants.allFollowers,
        data: {'page_id': widget.pageId},
      );
      final payload = res.data;

      if (payload is Map<String, dynamic> && payload['status'] == 200) {
        final rawList = payload['data'];
        if (rawList is List) {
          _followers = rawList
              .whereType<Map<String, dynamic>>()
              .map(_FollowerListItem.fromJson)
              .where((item) => item.name.isNotEmpty)
              .toList();
        } else {
          _followers = const [];
        }
      } else {
        _error = (payload is Map<String, dynamic>)
            ? (payload['message']?.toString() ?? 'Failed to load followers.')
            : 'Failed to load followers.';
      }
    } catch (_) {
      _error = 'Could not load followers. Please try again.';
    }

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.76;

    return SafeArea(
      top: false,
      child: Container(
        height: maxHeight,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[350],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${widget.pageName} followers',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 28),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondaryLight),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _loadFollowers,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_followers.isEmpty) {
      return const Center(
        child: Text(
          'No followers found.',
          style: TextStyle(color: AppColors.textSecondaryLight),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _followers.length,
      separatorBuilder: (context, index) => const Divider(height: 16),
      itemBuilder: (context, index) {
        final follower = _followers[index];
        final avatarUrl = follower.profilePic.isNotEmpty
            ? ApiConstants.userProfileUrl(follower.profilePic)
            : '';

        return Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.surfaceLight,
              backgroundImage: avatarUrl.isNotEmpty
                  ? NetworkImage(avatarUrl)
                  : null,
              child: avatarUrl.isEmpty
                  ? Text(
                      follower.name[0].toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    follower.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  if (follower.followedAt != null)
                    Text(
                      'Followed on ${Formatters.formatDate(follower.followedAt!)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FollowerListItem {
  final String name;
  final String profilePic;
  final DateTime? followedAt;

  const _FollowerListItem({
    required this.name,
    required this.profilePic,
    required this.followedAt,
  });

  factory _FollowerListItem.fromJson(Map<String, dynamic> json) {
    final user = json['user_id'];
    if (user is! Map<String, dynamic>) {
      return const _FollowerListItem(
        name: '',
        profilePic: '',
        followedAt: null,
      );
    }

    final firstName = user['first_name']?.toString().trim() ?? '';
    final lastName = user['last_name']?.toString().trim() ?? '';
    final fallbackName = user['username']?.toString().trim() ?? '';
    final fullName = [firstName, lastName].where((part) => part.isNotEmpty).join(' ');

    final createdAtRaw = json['createdAt']?.toString();
    final createdAt = createdAtRaw != null
        ? DateTime.tryParse(createdAtRaw)
        : null;

    return _FollowerListItem(
      name: fullName.isNotEmpty ? fullName : fallbackName,
      profilePic: user['profile_pic']?.toString() ?? '',
      followedAt: createdAt,
    );
  }
}

// ─────────────────────────────────────────────────────
// ── To-do List Section ──
// ─────────────────────────────────────────────────────

class _TodoListSection extends StatelessWidget {
  final List<TodoItem> todos;
  final List<RecentActivity> recentActivity;
  final DashboardKpis kpis;

  const _TodoListSection({
    required this.todos,
    required this.recentActivity,
    required this.kpis,
  });

  @override
  Widget build(BuildContext context) {
    final List<_TodoEntry> entries = [];

    // API-provided todos
    for (final todo in todos) {
      entries.add(_TodoEntry(
        icon: Icons.check_circle_outline,
        title: todo.title,
        trailing: todo.count > 0 ? '${todo.count} pending' : null,
        hasNotification: todo.count > 0,
      ));
    }

    // Messages
    final unreadMessages = kpis.messages.value.toInt();
    if (unreadMessages > 0) {
      entries.add(_TodoEntry(
        icon: Icons.chat_bubble_outline,
        title: 'Messages',
        trailing: '$unreadMessages unread',
        hasNotification: true,
      ));
    }

    // Comments
    final commentCount =
        recentActivity.where((a) => a.type == 'comment').length;
    if (commentCount > 0) {
      entries.add(_TodoEntry(
        icon: Icons.chat_outlined,
        title: 'Comments',
        trailing: '$commentCount unread',
        hasNotification: true,
      ));
    }

    // New followers
    final newFollowers = kpis.followers.change.toInt();
    if (newFollowers > 0) {
      entries.add(_TodoEntry(
        icon: Icons.person_add_outlined,
        title: 'New followers',
        trailing: '+$newFollowers',
        hasNotification: true,
      ));
    }

    if (entries.isEmpty) {
      entries.add(const _TodoEntry(
        icon: Icons.check_circle,
        title: 'All caught up!',
        trailing: null,
        hasNotification: false,
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text(
                'To-do list',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              if (entries.length > 3)
                TextButton(
                  onPressed: () {},
                  child: const Text('See all'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        ...entries.map((entry) => _TodoTile(entry: entry)),
      ],
    );
  }
}

class _TodoEntry {
  final IconData icon;
  final String title;
  final String? trailing;
  final bool hasNotification;

  const _TodoEntry({
    required this.icon,
    required this.title,
    required this.trailing,
    required this.hasNotification,
  });
}

class _TodoTile extends StatelessWidget {
  final _TodoEntry entry;
  const _TodoTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(entry.icon,
                  color: AppColors.textSecondaryLight, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                entry.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (entry.trailing != null) ...[
              Text(
                entry.trailing!,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondaryLight,
                ),
              ),
              if (entry.hasNotification) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right,
                size: 20, color: AppColors.textSecondaryLight),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// ── Posts Feed Section (Full-Featured) ──
// ─────────────────────────────────────────────────────

class _PostsFeedSection extends StatelessWidget {
  final String currentPageId;
  const _PostsFeedSection({required this.currentPageId});

  @override
  Widget build(BuildContext context) {
    final postProvider = context.watch<PostProvider>();
    final authUser = context.read<AuthProvider>().user;
    final currentUserId = authUser?.id ?? '';
    final currentUserProfilePic = authUser?.profilePic;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text(
                'Recent posts & reels',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.push('/content'),
                child: const Text('See all'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),

        // Schedule post tip banner
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0C2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.calendar_today,
                    size: 20, color: Color(0xFFB8860B)),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Save time by planning ahead',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Schedule posts to keep your audience engaged.',
                      style:
                          TextStyle(fontSize: 12, color: Color(0xFF8B7000)),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon:
                    const Icon(Icons.close, size: 18, color: Colors.black45),
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Loading state
        if (postProvider.isLoading && postProvider.posts.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          )
        // Error state
        else if (postProvider.error != null && postProvider.posts.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                'Could not load posts',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ),
          )
        // Empty state
        else if (postProvider.posts.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Text(
                'No posts yet. Create your first post!',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ),
          )
        // Post cards
        else
          ...postProvider.posts.asMap().entries.map((entry) {
            final index = entry.key;
            final post = entry.value;
            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: PostCard(
                model: post,
                index: index,
                currentUserId: currentUserId,
                onSelectReaction: (reaction) {
                  postProvider.reactOnPost(
                    postIndex: index,
                    reactionType: reaction,
                    userId: currentUserId,
                  );
                },
                onPressedComment: () {
                  showCommentModal(
                    context,
                    post: post,
                    postIndex: index,
                    currentUserId: currentUserId,
                    currentUserProfilePic: currentUserProfilePic,
                  );
                },
                onPressedShare: () {
                  // TODO: Share sheet
                },
                onTapViewReactions: () {
                  if (post.id != null) {
                    ReactionsBottomSheet.show(
                      context,
                      postId: post.id!,
                      api: context.read<ApiService>(),
                    );
                  }
                },
              ),
            );
          }),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────
// ── Onboarding Card ──
// ─────────────────────────────────────────────────────

class _OnboardingCard extends StatelessWidget {
  final OnboardingProgress onboarding;
  const _OnboardingCard({required this.onboarding});

  @override
  Widget build(BuildContext context) {
    final progress = onboarding.completed / onboarding.total;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.dividerLight.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Get Started',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.surfaceLight,
              color: AppColors.primary,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${onboarding.completed} of ${onboarding.total} steps completed',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 14),
          _OnboardingStep('Connect social accounts',
              onboarding.connectedSocial),
          _OnboardingStep(
              'Create your first post', onboarding.createdPost),
          _OnboardingStep(
              'Reply to a message', onboarding.repliedMessage),
          _OnboardingStep(
              'Grow your audience', onboarding.grewAudience),
        ],
      ),
    );
  }
}

class _OnboardingStep extends StatelessWidget {
  final String label;
  final bool done;
  const _OnboardingStep(this.label, this.done);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.circle_outlined,
            size: 22,
            color: done ? AppColors.success : AppColors.dividerLight,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              decoration: done ? TextDecoration.lineThrough : null,
              color:
                  done ? AppColors.textSecondaryLight : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
