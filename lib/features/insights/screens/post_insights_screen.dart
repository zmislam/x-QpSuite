import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../features/page_switcher/providers/managed_pages_provider.dart';
import '../../../shared/widgets/widgets.dart';
import '../providers/insights_provider.dart';

class PostInsightsScreen extends StatefulWidget {
  final String postId;
  const PostInsightsScreen({super.key, required this.postId});

  @override
  State<PostInsightsScreen> createState() => _PostInsightsScreenState();
}

class _PostInsightsScreenState extends State<PostInsightsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final pageId = context.read<ManagedPagesProvider>().activePageId;
    if (pageId != null) {
      context
          .read<InsightsProvider>()
          .fetchPostInsights(pageId, widget.postId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InsightsProvider>();
    final theme = Theme.of(context);
    final data = provider.postInsights;

    return Scaffold(
      appBar: AppBar(title: const Text('Post Insights')),
      body: provider.isPostLoading
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: QpLoading(itemCount: 6),
            )
          : provider.postError != null && data == null
              ? ErrorState(message: provider.postError!, onRetry: _load)
              : data == null
                  ? const EmptyState(icon: Icons.insights_outlined, title: 'No insights available')
                  : RefreshIndicator(
                      onRefresh: () async => _load(),
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          // Post info
                          if (data.description.isNotEmpty) ...[
                            Text(data.description,
                                style: theme.textTheme.bodyLarge,
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis),
                            if (data.createdAt != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  Formatters.formatDateTime(
                                      DateTime.parse(data.createdAt!)),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme
                                          .colorScheme.onSurfaceVariant),
                                ),
                              ),
                            const SizedBox(height: 16),
                          ],

                          // Metric cards
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 2,
                            children: [
                              KpiCard(
                                  label: 'Reach',
                                  value: data.reach,
                                  isCompact: true),
                              KpiCard(
                                  label: 'Impressions',
                                  value: data.impressions,
                                  isCompact: true),
                              KpiCard(
                                  label: 'Engagement',
                                  value: data.engagement,
                                  isCompact: true),
                              KpiCard(
                                  label: 'Clicks',
                                  value: data.clicks,
                                  isCompact: true),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Engagement breakdown pie chart
                          Text('Engagement Breakdown',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 200,
                            child: _EngagementPie(
                              reactions: data.reactionsBreakdown.values
                                  .fold<int>(0, (a, b) => a + b),
                              comments: data.commentsCount,
                              shares: data.sharesCount,
                              saves: data.savesCount,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Reactions detail
                          if (data.reactionsBreakdown.isNotEmpty) ...[
                            Text('Reactions',
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                                  data.reactionsBreakdown.entries.map((e) {
                                return Chip(
                                  label: Text(
                                      '${_capitalize(e.key)}: ${Formatters.formatNumber(e.value)}'),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Other stats
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  _StatRow('Comments',
                                      Formatters.formatNumber(data.commentsCount)),
                                  const Divider(),
                                  _StatRow('Shares',
                                      Formatters.formatNumber(data.sharesCount)),
                                  const Divider(),
                                  _StatRow('Saves',
                                      Formatters.formatNumber(data.savesCount)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _EngagementPie extends StatelessWidget {
  final int reactions;
  final int comments;
  final int shares;
  final int saves;

  const _EngagementPie({
    required this.reactions,
    required this.comments,
    required this.shares,
    required this.saves,
  });

  @override
  Widget build(BuildContext context) {
    final total = reactions + comments + shares + saves;
    if (total == 0) {
      return const Center(child: Text('No engagement data'));
    }

    final entries = [
      _PieEntry('Reactions', reactions, AppColors.chartBlue),
      _PieEntry('Comments', comments, AppColors.chartGreen),
      _PieEntry('Shares', shares, AppColors.chartOrange),
      _PieEntry('Saves', saves, AppColors.chartPurple),
    ];

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: entries
                  .where((e) => e.value > 0)
                  .map((e) => PieChartSectionData(
                        value: e.value.toDouble(),
                        title: '${(e.value / total * 100).toStringAsFixed(0)}%',
                        titleStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                        color: e.color,
                        radius: 60,
                      ))
                  .toList(),
              centerSpaceRadius: 30,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: entries
              .map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                              color: e.color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Text(
                            '${e.label}: ${Formatters.formatNumber(e.value)}'),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _PieEntry {
  final String label;
  final int value;
  final Color color;
  _PieEntry(this.label, this.value, this.color);
}
