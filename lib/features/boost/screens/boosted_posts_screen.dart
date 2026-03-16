import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../features/page_switcher/providers/managed_pages_provider.dart';
import '../../../shared/widgets/widgets.dart';
import '../models/boost_models.dart';
import '../providers/boost_provider.dart';

class BoostedPostsScreen extends StatefulWidget {
  const BoostedPostsScreen({super.key});

  @override
  State<BoostedPostsScreen> createState() => _BoostedPostsScreenState();
}

class _BoostedPostsScreenState extends State<BoostedPostsScreen> {
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
            .read<BoostProvider>()
            .fetchBoostedPosts(pageId, loadMore: true);
      }
    }
  }

  void _load() {
    final pageId = context.read<ManagedPagesProvider>().activePageId;
    if (pageId != null) {
      context.read<BoostProvider>().fetchBoostedPosts(pageId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BoostProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Boosted Posts')),
      body: provider.isLoading && provider.items.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: QpLoading(itemCount: 5),
            )
          : provider.error != null && provider.items.isEmpty
              ? ErrorState(message: provider.error!, onRetry: _load)
              : provider.items.isEmpty
                  ? const EmptyState(
                      icon: Icons.rocket_launch_outlined,
                      title: 'No boosted posts yet',
                      subtitle: 'Boost a post from your content to reach more people.',
                    )
                  : RefreshIndicator(
                      onRefresh: () async => _load(),
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.items.length,
                        itemBuilder: (_, i) => _BoostedPostCard(
                          post: provider.items[i],
                          onToggle: () {
                            final pageId = context
                                .read<ManagedPagesProvider>()
                                .activePageId;
                            if (pageId == null) return;
                            final action =
                                provider.items[i].status == 'Active'
                                    ? 'pause'
                                    : 'resume';
                            context
                                .read<BoostProvider>()
                                .togglePauseResume(
                                    pageId, provider.items[i].id, action);
                          },
                        ),
                      ),
                    ),
    );
  }
}

BadgeStatus _toBadgeStatus(String s) {
  switch (s) {
    case 'Active':
      return BadgeStatus.active;
    case 'Paused':
      return BadgeStatus.paused;
    case 'Draft':
      return BadgeStatus.draft;
    case 'Completed':
      return BadgeStatus.completed;
    case 'Archived':
      return BadgeStatus.archived;
    case 'Rejected':
      return BadgeStatus.rejected;
    default:
      return BadgeStatus.draft;
  }
}

class _BoostedPostCard extends StatelessWidget {
  final BoostedPost post;
  final VoidCallback onToggle;
  const _BoostedPostCard({required this.post, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                // Thumbnail
                if (post.postThumbnail != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      ApiConstants.mediaUrl(post.postThumbnail!),
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholderBox(),
                    ),
                  )
                else
                  _placeholderBox(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.postDescription ?? 'Boosted Post',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      StatusBadge(status: _toBadgeStatus(post.status)),
                    ],
                  ),
                ),
                // Pause/Resume toggle
                if (post.status == 'Active' || post.status == 'Paused')
                  IconButton(
                    icon: Icon(
                      post.status == 'Active'
                          ? Icons.pause_circle
                          : Icons.play_circle,
                    ),
                    onPressed: onToggle,
                    tooltip:
                        post.status == 'Active' ? 'Pause' : 'Resume',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            // Metrics row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _MetricCol('Budget', post.formattedBudget),
                _MetricCol('Spent', post.formattedSpend),
                _MetricCol('Reach', Formatters.compactNumber(post.reach)),
                _MetricCol(
                    'Clicks', Formatters.compactNumber(post.clicks)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderBox() => Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.campaign, color: Colors.grey),
      );
}

class _MetricCol extends StatelessWidget {
  final String label;
  final String value;
  const _MetricCol(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}
