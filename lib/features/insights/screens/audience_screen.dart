import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../features/page_switcher/providers/managed_pages_provider.dart';
import '../../../shared/widgets/widgets.dart';
import '../providers/insights_provider.dart';

class AudienceScreen extends StatefulWidget {
  const AudienceScreen({super.key});

  @override
  State<AudienceScreen> createState() => _AudienceScreenState();
}

class _AudienceScreenState extends State<AudienceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final pageId = context.read<ManagedPagesProvider>().activePageId;
    if (pageId != null) {
      context.read<InsightsProvider>().fetchAudience(pageId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InsightsProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Audience')),
      body: provider.isAudienceLoading && provider.audience == null
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: QpLoading(itemCount: 5),
            )
          : provider.audienceError != null && provider.audience == null
              ? ErrorState(
                  message: provider.audienceError!,
                  onRetry: _load,
                )
              : provider.audience == null
                  ? const EmptyState(icon: Icons.people_outline, title: 'No audience data available')
                  : RefreshIndicator(
                      onRefresh: () async => _load(),
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          // Total followers
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Text('Total Followers',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                              color: theme.colorScheme
                                                  .onSurfaceVariant)),
                                  const SizedBox(height: 4),
                                  Text(
                                    Formatters.formatNumber(
                                        provider.audience!.totalFollowers),
                                    style: theme.textTheme.headlineMedium
                                        ?.copyWith(
                                            fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Gender pie chart
                          if (provider
                              .audience!.genderBreakdown.isNotEmpty) ...[
                            _SectionTitle('Gender'),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 200,
                              child: _GenderPieChart(
                                  data: provider.audience!.genderBreakdown),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Age distribution bar chart
                          if (provider
                              .audience!.ageBreakdown.isNotEmpty) ...[
                            _SectionTitle('Age Distribution'),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 200,
                              child: _AgeBarChart(
                                  data: provider.audience!.ageBreakdown),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Top countries
                          if (provider
                              .audience!.topCountries.isNotEmpty) ...[
                            _SectionTitle('Top Countries'),
                            const SizedBox(height: 8),
                            ...provider.audience!.topCountries.map(
                              (c) => _RankedRow(
                                label: c.country,
                                count: c.count,
                                maxCount:
                                    provider.audience!.topCountries.first.count,
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Top cities
                          if (provider.audience!.topCities.isNotEmpty) ...[
                            _SectionTitle('Top Cities'),
                            const SizedBox(height: 8),
                            ...provider.audience!.topCities.map(
                              (c) => _RankedRow(
                                label: c.city,
                                count: c.count,
                                maxCount:
                                    provider.audience!.topCities.first.count,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold));
  }
}

// ── Gender Pie Chart ──

class _GenderPieChart extends StatelessWidget {
  final Map<String, int> data;
  const _GenderPieChart({required this.data});

  static const _genderColors = {
    'Male': AppColors.chartBlue,
    'Female': AppColors.chartPink,
    'Other': AppColors.chartGrey,
  };

  @override
  Widget build(BuildContext context) {
    final total = data.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) return const SizedBox();

    final sections = data.entries.map((e) {
      final pct = e.value / total * 100;
      return PieChartSectionData(
        value: pct,
        title: '${pct.toStringAsFixed(0)}%',
        titleStyle: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
        color: _genderColors[e.key] ?? AppColors.chartGrey,
        radius: 60,
      );
    }).toList();

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 30,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: data.entries
              .map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _genderColors[e.key] ?? AppColors.chartGrey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('${e.key}: ${Formatters.formatNumber(e.value)}'),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

// ── Age Distribution Bar Chart ──

class _AgeBarChart extends StatelessWidget {
  final Map<String, int> data;
  const _AgeBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = data.entries.toList();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: entries.fold<int>(0, (a, b) => a > b.value ? a : b.value) * 1.2,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (v, _) => Text(
                Formatters.compactNumber(v.toInt()),
                style: theme.textTheme.labelSmall,
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final idx = v.toInt();
                if (idx < 0 || idx >= entries.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(entries[idx].key,
                      style: theme.textTheme.labelSmall),
                );
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barGroups: entries.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.value.toDouble(),
                color: AppColors.primary,
                width: 20,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ── Ranked Row (countries / cities) ──

class _RankedRow extends StatelessWidget {
  final String label;
  final int count;
  final int maxCount;
  const _RankedRow(
      {required this.label, required this.count, required this.maxCount});

  @override
  Widget build(BuildContext context) {
    final fraction = maxCount > 0 ? count / maxCount : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(label, overflow: TextOverflow.ellipsis),
              ),
              Text(Formatters.formatNumber(count),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
