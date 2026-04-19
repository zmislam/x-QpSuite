import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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

class _BottomNavShellState extends State<BottomNavShell>
    with SingleTickerProviderStateMixin {
  String? _lastPageId;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Watch for page changes — triggers rebuild when active page switches
    final pagesProvider = context.watch<ManagedPagesProvider>();
    final currentPageId = pagesProvider.activePageId;
    final isSwitching = pagesProvider.isSwitchingPage;

    // Show/hide overlay based on switching state
    if (isSwitching && !_fadeController.isAnimating && _fadeController.value == 0) {
      _fadeController.forward();
    }

    // Reload all providers when page changes
    if (currentPageId != null && currentPageId != _lastPageId) {
      final isFirstLoad = _lastPageId == null;
      final shouldReload = !isFirstLoad || isSwitching;
      _lastPageId = currentPageId;

      if (shouldReload) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _reloadAllProviders(currentPageId);
        });
      }
    }

    return Scaffold(
      body: Stack(
        children: [
          widget.shell,
          // Page switching overlay
          if (isSwitching)
            FadeTransition(
              opacity: _fadeAnimation,
              child: _PageSwitchOverlay(
                pageName: pagesProvider.activePage?.pageName ?? '',
              ),
            ),
        ],
      ),
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
  /// Awaits the dashboard fetch before clearing the switching overlay.
  Future<void> _reloadAllProviders(String pageId) async {
    if (!mounted) return;

    // Fire all fetches — await dashboard as the primary content
    final dashboardFuture =
        context.read<DashboardProvider>().fetchDashboard(pageId);
    context.read<PostProvider>().fetchPagePosts(pageId, refresh: true);
    context.read<InboxProvider>().fetchThreads(pageId);
    context.read<NotificationsProvider>().fetchNotifications(pageId);
    context.read<TodosProvider>().fetchTodos(pageId);
    context.read<InsightsProvider>().fetchOverview(pageId);
    context.read<BoostProvider>().fetchBoostedPosts(pageId);

    // Wait for dashboard data (main screen) before removing overlay
    await dashboardFuture;

    if (!mounted) return;
    await _fadeController.reverse();
    if (mounted) {
      context.read<ManagedPagesProvider>().clearSwitching();
    }
  }
}

/// Full-screen overlay shown during page switch with branded animation.
class _PageSwitchOverlay extends StatefulWidget {
  final String pageName;
  const _PageSwitchOverlay({required this.pageName});

  @override
  State<_PageSwitchOverlay> createState() => _PageSwitchOverlayState();
}

class _PageSwitchOverlayState extends State<_PageSwitchOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pulsing logo icon
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.7),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.business,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // "Switching to" label
            Text(
              'Switching to',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 6),
            // Page name
            Text(
              widget.pageName,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            // Animated loading bar
            SizedBox(
              width: 160,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
