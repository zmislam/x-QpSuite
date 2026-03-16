import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../features/page_switcher/providers/managed_pages_provider.dart';
import '../../../shared/widgets/widgets.dart';
import '../models/insights_models.dart';
import '../providers/insights_provider.dart';

class InsightsOverviewScreen extends StatefulWidget {
  const InsightsOverviewScreen({super.key});

  @override
  State<InsightsOverviewScreen> createState() => _InsightsOverviewScreenState();
}

class _InsightsOverviewScreenState extends State<InsightsOverviewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final pageId = context.read<ManagedPagesProvider>().activePageId;
    if (pageId != null) {
      context.read<InsightsProvider>().fetchOverview(pageId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InsightsProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context).pushNamed('/insights/audience'),
            child: const Text('Audience'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(context).pushNamed('/insights/content'),
            child: const Text('Content'),
          ),
        ],
      ),
      body: provider.isOverviewLoading && provider.overview == null
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: QpLoading(itemCount: 6),
            )
          : provider.overviewError != null && provider.overview == null
              ? ErrorState(
                  message: provider.overviewError!,
                  onRetry: _load,
                )
              : RefreshIndicator(
                  onRefresh: () async => _load(),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Period selector
                      _PeriodSelector(
                        period: provider.period,
                        onChanged: (p) {
                          provider.setPeriod(p);
                          _load();
                        },
                      ),
                      const SizedBox(height: 16),

                      // KPI Summary cards
                      if (provider.overview != null)
                        _KpiGrid(summary: provider.overview!.summary),
                      const SizedBox(height: 24),

                      // Trend chart
                      if (provider.overview != null &&
                          provider.overview!.daily.isNotEmpty) ...[
                        Text('Trends',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        _MetricSelector(
                          selected: provider.selectedMetric,
                          onChanged: provider.setSelectedMetric,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 240,
                          child: _TrendChart(
                            daily: provider.overview!.daily,
                            metric: provider.selectedMetric,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }
}

// ── Period Selector ──

class _PeriodSelector extends StatelessWidget {
  final InsightsPeriod period;
  final ValueChanged<InsightsPeriod> onChanged;

  const _PeriodSelector({required this.period, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<InsightsPeriod>(
      segments: const [
        ButtonSegment(value: InsightsPeriod.days7, label: Text('7d')),
        ButtonSegment(value: InsightsPeriod.days14, label: Text('14d')),
        ButtonSegment(value: InsightsPeriod.days30, label: Text('30d')),
        ButtonSegment(value: InsightsPeriod.days90, label: Text('90d')),
      ],
      selected: {period},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

// ── KPI Grid ──

class _KpiGrid extends StatelessWidget {
  final InsightsSummary summary;
  const _KpiGrid({required this.summary});

  @override
  Widget build(BuildContext context) {
    final items = [
      _KpiItem('Reach', summary.reach, summary.reachTrend),
      _KpiItem('Impressions', summary.impressions, summary.impressionsTrend),
      _KpiItem('Engagement', summary.engagement, summary.engagementTrend),
      _KpiItem('Page Views', summary.pageViews, summary.pageViewsTrend),
      _KpiItem('New Followers', summary.newFollowers, summary.newFollowersTrend),
      _KpiItem('Posts', summary.postsPublished, null),
      _KpiItem('Messages', summary.messagesReceived, null),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.0,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => KpiCard(
        label: items[i].label,
        value: items[i].value,
        trendPercent: items[i].trend,
        isCompact: true,
      ),
    );
  }
}

class _KpiItem {
  final String label;
  final num value;
  final double? trend;
  _KpiItem(this.label, this.value, this.trend);
}

// ── Metric Selector Tabs ──

class _MetricSelector extends StatelessWidget {
  final InsightsMetric selected;
  final ValueChanged<InsightsMetric> onChanged;

  const _MetricSelector({required this.selected, required this.onChanged});

  static const _labels = {
    InsightsMetric.reach: 'Reach',
    InsightsMetric.impressions: 'Impressions',
    InsightsMetric.engagement: 'Engagement',
    InsightsMetric.pageViews: 'Page Views',
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: InsightsMetric.values.map((m) {
          final isSelected = m == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(_labels[m]!),
              selected: isSelected,
              onSelected: (_) => onChanged(m),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Trend Chart ──

class _TrendChart extends StatelessWidget {
  final List<DailyInsight> daily;
  final InsightsMetric metric;

  const _TrendChart({required this.daily, required this.metric});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spots = <FlSpot>[];
    for (var i = 0; i < daily.length; i++) {
      spots.add(FlSpot(i.toDouble(), daily[i].valueFor(metric).toDouble()));
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              getTitlesWidget: (v, _) => Text(
                Formatters.compactNumber(v.toInt()),
                style: theme.textTheme.labelSmall,
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: (daily.length / 5).ceilToDouble().clamp(1, 30),
              getTitlesWidget: (v, _) {
                final idx = v.toInt();
                if (idx < 0 || idx >= daily.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    Formatters.formatChartDate(DateTime.parse(daily[idx].date)),
                    style: theme.textTheme.labelSmall,
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.primary,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withAlpha(30),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots
                .map((s) => LineTooltipItem(
                      Formatters.formatNumber(s.y.toInt()),
                      TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}
