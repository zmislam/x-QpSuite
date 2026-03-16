import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/formatters.dart';
import '../../../features/page_switcher/providers/managed_pages_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/qp_loading.dart';
import '../models/inbox_models.dart';
import '../providers/inbox_provider.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final pageId = context.read<ManagedPagesProvider>().activePageId;
    if (pageId != null) {
      context.read<InboxProvider>().fetchThreads(pageId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inbox = context.watch<InboxProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Inbox')),
      body: _buildBody(inbox),
    );
  }

  Widget _buildBody(InboxProvider inbox) {
    if (inbox.isLoading && inbox.threads.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: QpLoading(itemCount: 6, height: 72),
      );
    }

    if (inbox.error != null && inbox.threads.isEmpty) {
      return ErrorState(message: inbox.error!, onRetry: _load);
    }

    if (inbox.threads.isEmpty) {
      return const EmptyState(
        icon: Icons.forum_outlined,
        title: 'No messages yet',
        subtitle: 'Messages from page visitors will appear here.',
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _load(),
      child: ListView.separated(
        itemCount: inbox.threads.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) =>
            _ThreadTile(thread: inbox.threads[i]),
      ),
    );
  }
}

class _ThreadTile extends StatelessWidget {
  final InboxThread thread;
  const _ThreadTile({required this.thread});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnread = !thread.isRead;

    return ListTile(
      onTap: () => context.go('/inbox/${thread.id}'),
      leading: CircleAvatar(
        backgroundImage: thread.contact.profilePicture != null
            ? NetworkImage(thread.contact.profilePicture!)
            : null,
        child: thread.contact.profilePicture == null
            ? Text(thread.contact.fullName.isNotEmpty
                ? thread.contact.fullName[0].toUpperCase()
                : '?')
            : null,
      ),
      title: Text(
        thread.contact.fullName,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        thread.lastMessage?.content ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            Formatters.formatTimeAgo(thread.updatedAt),
            style: theme.textTheme.bodySmall,
          ),
          if (isUnread)
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
