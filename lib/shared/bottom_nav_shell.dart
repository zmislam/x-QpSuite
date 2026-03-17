import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../features/boost/providers/boost_provider.dart';
import '../features/dashboard/providers/dashboard_provider.dart';
import '../features/inbox/providers/inbox_provider.dart';
import '../features/insights/providers/insights_provider.dart';
import '../features/notifications/providers/notifications_provider.dart';
import '../features/page_switcher/providers/managed_pages_provider.dart';
import '../features/posts/providers/post_provider.dart';
import '../features/todos/providers/todos_provider.dart';

class BottomNavShell extends StatefulWidget {
  final StatefulNavigationShell shell;

  const BottomNavShell({super.key, required this.shell});

  @override
  State<BottomNavShell> createState() => _BottomNavShellState();
}

class _BottomNavShellState extends State<BottomNavShell> {
  String? _lastPageId;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Watch for page changes — triggers rebuild when active page switches
    final pagesProvider = context.watch<ManagedPagesProvider>();
    final currentPageId = pagesProvider.activePageId;

    // Reload all providers when page changes
    if (currentPageId != null && currentPageId != _lastPageId) {
      final isFirstLoad = _lastPageId == null;
      _lastPageId = currentPageId;

      if (!isFirstLoad) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _reloadAllProviders(currentPageId);
        });
      }
    }

    return Scaffold(
      body: widget.shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.shell.currentIndex,
        onDestinationSelected: (index) {
          widget.shell.goBranch(index, initialLocation: index == widget.shell.currentIndex);
        },
        backgroundColor:
            isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.article_outlined),
            selectedIcon: Icon(Icons.article),
            label: 'Content',
          ),
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum),
            label: 'Inbox',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Insights',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu),
            selectedIcon: Icon(Icons.menu),
            label: 'More',
          ),
        ],
      ),
    );
  }

  /// Reload all page-dependent providers when the active page changes.
  void _reloadAllProviders(String pageId) {
    if (!mounted) return;
    context.read<DashboardProvider>().fetchDashboard(pageId);
    context.read<PostProvider>().fetchPagePosts(pageId, refresh: true);
    context.read<InboxProvider>().fetchThreads(pageId);
    context.read<NotificationsProvider>().fetchNotifications(pageId);
    context.read<TodosProvider>().fetchTodos(pageId);
    context.read<InsightsProvider>().fetchOverview(pageId);
    context.read<BoostProvider>().fetchBoostedPosts(pageId);
  }
}
