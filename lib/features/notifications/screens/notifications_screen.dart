import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/constants/api_constants.dart';
import '../../../features/page_switcher/providers/managed_pages_provider.dart';
import '../../../shared/widgets/widgets.dart';
import '../models/notification_models.dart';
import '../providers/notifications_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      final pageId = context.read<ManagedPagesProvider>().activePageId;
      if (pageId != null) {
        context
            .read<NotificationsProvider>()
            .fetchNotifications(pageId, loadMore: true);
      }
    }
  }

  void _load() {
    final pageId = context.read<ManagedPagesProvider>().activePageId;
    if (pageId != null) {
      context.read<NotificationsProvider>().fetchNotifications(pageId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(provider.unreadCount > 0
            ? 'Notifications (${provider.unreadCount})'
            : 'Notifications'),
        actions: [
          if (provider.unreadCount > 0)
            TextButton(
              onPressed: () {
                final pageId =
                    context.read<ManagedPagesProvider>().activePageId;
                if (pageId != null) {
                  context.read<NotificationsProvider>().markAllRead(pageId);
                }
              },
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: provider.isLoading && provider.items.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: QpLoading(itemCount: 8, height: 72),
            )
          : provider.error != null && provider.items.isEmpty
              ? ErrorState(message: provider.error!, onRetry: _load)
              : provider.items.isEmpty
                  ? const EmptyState(
                      icon: Icons.notifications_none,
                      title: 'No notifications yet')
                  : RefreshIndicator(
                      onRefresh: () async => _load(),
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: provider.items.length,
                        itemBuilder: (_, i) => Dismissible(
                          key: ValueKey(provider.items[i].id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 16),
                            child:
                                const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (_) => provider.removeAt(i),
                          child: _NotificationTile(
                            notification: provider.items[i],
                          ),
                        ),
                      ),
                    ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: notification.isRead
          ? null
          : (isDark ? Colors.blue.withAlpha(20) : Colors.blue.withAlpha(10)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: notification.actor?.avatar != null
              ? NetworkImage(
                  ApiConstants.userProfileUrl(notification.actor!.avatar!))
              : null,
          child: notification.actor?.avatar == null
              ? Icon(_iconForType(notification.type))
              : null,
        ),
        title: Text(
          notification.title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: notification.isRead ? null : FontWeight.bold,
          ),
        ),
        subtitle: Text(
          notification.body,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall,
        ),
        trailing: Text(
          timeago.format(notification.createdAt),
          style: theme.textTheme.labelSmall,
        ),
        onTap: () {
          // TODO: Deep-link navigation based on notification.link
        },
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'new_follower':
        return Icons.person_add;
      case 'new_message':
        return Icons.message;
      case 'post_milestone':
        return Icons.trending_up;
      case 'review':
        return Icons.star;
      case 'mention':
        return Icons.alternate_email;
      case 'ad_update':
        return Icons.campaign;
      case 'content_published':
        return Icons.check_circle;
      case 'content_failed':
        return Icons.error;
      case 'comment':
        return Icons.comment;
      case 'reaction':
        return Icons.thumb_up;
      default:
        return Icons.notifications;
    }
  }
}
