import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/content/screens/content_screen.dart';
import '../../features/inbox/screens/inbox_screen.dart';
import '../../features/inbox/screens/thread_detail_screen.dart';
import '../../features/insights/screens/insights_overview_screen.dart';
import '../../features/insights/screens/audience_screen.dart';
import '../../features/insights/screens/content_insights_screen.dart';
import '../../features/insights/screens/post_insights_screen.dart';
import '../../features/more/screens/more_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/todos/screens/todos_screen.dart';
import '../../features/boost/screens/boosted_posts_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/content/screens/schedule_content_screen.dart';
import '../../features/content/screens/content_calendar_screen.dart';
import '../../features/content/screens/scheduled_posts_screen.dart';
import '../../shared/bottom_nav_shell.dart';

final _rootKey = GlobalKey<NavigatorState>();


GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    navigatorKey: _rootKey,
    refreshListenable: authProvider,
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuth = authProvider.isAuthenticated;
      final location = state.uri.path;

      // While checking auth status, stay on splash
      if (location == '/splash') return null;

      // Not authenticated → send to login
      if (!isAuth && location != '/login') return '/login';

      // Authenticated but on login/splash → send to home
      if (isAuth && (location == '/login' || location == '/splash')) {
        return '/home';
      }

      return null;
    },
    routes: [
      // ── Splash ──────────────────────────────────
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // ── Login ───────────────────────────────────
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // ── Main Shell (Bottom Nav) ─────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => BottomNavShell(shell: shell),
        branches: [
          // Tab 0: Home (Dashboard)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),

          // Tab 1: Content
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/content',
                builder: (context, state) => const ContentScreen(),
                routes: [
                  GoRoute(
                    path: 'schedule',
                    builder: (context, state) =>
                        const ScheduleContentScreen(),
                  ),
                  GoRoute(
                    path: 'calendar',
                    builder: (context, state) =>
                        const ContentCalendarScreen(),
                  ),
                  GoRoute(
                    path: 'scheduled-posts',
                    builder: (context, state) =>
                        const ScheduledPostsScreen(),
                  ),
                ],
              ),
            ],
          ),

          // Tab 2: Inbox
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/inbox',
                builder: (context, state) => const InboxScreen(),
                routes: [
                  GoRoute(
                    path: ':threadId',
                    builder: (context, state) {
                      final threadId = state.pathParameters['threadId']!;
                      return ThreadDetailScreen(threadId: threadId);
                    },
                  ),
                ],
              ),
            ],
          ),

          // Tab 3: Insights
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/insights',
                builder: (context, state) =>
                    const InsightsOverviewScreen(),
                routes: [
                  GoRoute(
                    path: 'audience',
                    builder: (context, state) => const AudienceScreen(),
                  ),
                  GoRoute(
                    path: 'content',
                    builder: (context, state) =>
                        const ContentInsightsScreen(),
                  ),
                  GoRoute(
                    path: 'post/:postId',
                    builder: (context, state) {
                      final postId = state.pathParameters['postId']!;
                      return PostInsightsScreen(postId: postId);
                    },
                  ),
                ],
              ),
            ],
          ),

          // Tab 4: More
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/more',
                builder: (context, state) => const MoreScreen(),
                routes: [
                  GoRoute(
                    path: 'notifications',
                    builder: (context, state) =>
                        const NotificationsScreen(),
                  ),
                  GoRoute(
                    path: 'todos',
                    builder: (context, state) => const TodosScreen(),
                  ),
                  GoRoute(
                    path: 'boosted-posts',
                    builder: (context, state) =>
                        const BoostedPostsScreen(),
                  ),
                  GoRoute(
                    path: 'settings',
                    builder: (context, state) =>
                        const SettingsScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
