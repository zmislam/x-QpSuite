import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'core/providers/theme_provider.dart';
import 'core/services/api_service.dart';
import 'core/services/socket_service.dart';
import 'core/services/storage_service.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/boost/providers/boost_provider.dart';
import 'features/content/providers/content_provider.dart';
import 'features/dashboard/providers/dashboard_provider.dart';
import 'features/inbox/providers/inbox_provider.dart';
import 'features/insights/providers/insights_provider.dart';
import 'features/notifications/providers/notifications_provider.dart';
import 'features/page_switcher/providers/managed_pages_provider.dart';
import 'features/posts/providers/post_provider.dart';
import 'features/todos/providers/todos_provider.dart';
import 'features/ads_manager/providers/ads_manager_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();

  final apiService = ApiService();
  final socketService = SocketService();

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: apiService),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            api: apiService,
            socket: socketService,
          ),
        ),
        ChangeNotifierProxyProvider<AuthProvider, ManagedPagesProvider>(
          create: (_) => ManagedPagesProvider(api: apiService),
          update: (_, auth, pages) {
            if (auth.isAuthenticated && (pages?.pages.isEmpty ?? true)) {
              pages?.fetchPages();
            }
            return pages!;
          },
        ),
        ChangeNotifierProvider(
          create: (_) => DashboardProvider(api: apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => ContentProvider(api: apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => InboxProvider(api: apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => InsightsProvider(api: apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationsProvider(api: apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => TodosProvider(api: apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => BoostProvider(api: apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => PostProvider(api: apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => AdsManagerProvider(api: apiService),
        ),
      ],
      child: const QpSuiteApp(),
    ),
  );
}


