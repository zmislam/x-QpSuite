import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../features/page_switcher/providers/managed_pages_provider.dart';
import '../../../shared/widgets/widgets.dart';
import '../models/insights_models.dart';
import '../providers/insights_provider.dart';

class ContentInsightsScreen extends StatefulWidget {
  const ContentInsightsScreen({super.key});

  @override
  State<ContentInsightsScreen> createState() => _ContentInsightsScreenState();
}

class _ContentInsightsScreenState extends State<ContentInsightsScreen> {
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
            .read<InsightsProvider>()
            .fetchContentPerformance(pageId, loadMore: true);
      }
    }
  }

  void _load() {
    final pageId = context.read<ManagedPagesProvider>().activePageId;
    if (pageId != null) {
      context.read<InsightsProvider>().fetchContentPerformance(pageId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InsightsProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Content Performance')),
      body: Column(
        children: [
          // Sort selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text('Sort by:', style: theme.textTheme.bodySmall),
                const SizedBox(width: 8),
                ..._sortOptions.map((opt) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(opt.label),
                        selected: provider.contentSort == opt.value,
                        onSelected: (_) {
                          provider.setContentSort(opt.value);
                          _load();
                        },
                      ),
                    )),
              ],
            ),
          ),
          const Divider(height: 1),
          // Content list
          Expanded(
            child: provider.isContentLoading && provider.contentItems.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: QpLoading(itemCount: 6),
                  )
                : provider.contentError != null &&
                        provider.contentItems.isEmpty
                    ? ErrorState(
                        message: provider.contentError!,
                        onRetry: _load,
                      )
                    : provider.contentItems.isEmpty
                        ? const EmptyState(
                            icon: Icons.analytics_outlined, title: 'No content performance data yet')
                        : RefreshIndicator(
                            onRefresh: () async => _load(),
                            child: ListView.separated(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: provider.contentItems.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (_, i) => _ContentTile(
                                item: provider.contentItems[i],
                                onTap: () => context.push(
                                    '/insights/post/${provider.contentItems[i].postId}'),
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  static const _sortOptions = [
    _SortOption('Reach', 'reach'),
    _SortOption('Engagement', 'engagement'),
    _SortOption('Clicks', 'clicks'),
  ];
}

class _SortOption {
  final String label;
  final String value;
  const _SortOption(this.label, this.value);
}

class _ContentTile extends StatelessWidget {
  final ContentPerformanceItem item;
  final VoidCallback onTap;
  const _ContentTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: item.thumbnail != null
                    ? Image.network(
                        ApiConstants.mediaUrl(item.thumbnail!),
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
              const SizedBox(width: 12),
              // Description + metrics
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _MetricChip(
                            label: 'Reach',
                            value: Formatters.compactNumber(item.reach)),
                        const SizedBox(width: 12),
                        _MetricChip(
                            label: 'Eng.',
                            value:
                                Formatters.compactNumber(item.engagement)),
                        const SizedBox(width: 12),
                        _MetricChip(
                            label: 'Clicks',
                            value: Formatters.compactNumber(item.clicks)),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 56,
        height: 56,
        color: Colors.grey[300],
        child: const Icon(Icons.image, color: Colors.grey),
      );
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  const _MetricChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }
}
