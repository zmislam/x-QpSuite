import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../features/page_switcher/providers/managed_pages_provider.dart';
import '../../../shared/widgets/widgets.dart';
import '../models/insights_models.dart';
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
    final data = provider.postInsights;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Post insights',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: provider.isPostLoading
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: QpLoading(itemCount: 6),
            )
          : provider.postError != null && data == null
              ? ErrorState(message: provider.postError!, onRetry: _load)
              : data == null
                  ? const EmptyState(
                      icon: Icons.insights_outlined,
                      title: 'No insights available',
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: () async => _load(),
                            child: ListView(
                              padding: const EdgeInsets.all(16),
                              children: [
                                // ── Post Summary Card ──
                                _PostSummaryCard(data: data),
                                const SizedBox(height: 16),

                                // ── Overview Section ──
                                _OverviewSection(data: data),
                                const SizedBox(height: 16),

                                // ── Views Section with Chart ──
                                _ViewsSection(data: data),
                                const SizedBox(height: 16),

                                // ── Interactions Section ──
                                _InteractionsSection(data: data),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                        // ── Boost Button ──
                        _BoostButton(),
                      ],
                    ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// ── POST SUMMARY CARD ──
// ═══════════════════════════════════════════════════════

class _PostSummaryCard extends StatelessWidget {
  final PostInsightsData data;
  const _PostSummaryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final dateStr = data.createdAt != null
        ? DateFormat('d MMMM HH:mm').format(DateTime.parse(data.createdAt!))
        : '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Thumbnail placeholder
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.image, color: Colors.grey[400], size: 28),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Post · $dateStr',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 6),
                // Stats row
                Row(
                  children: [
                    Text(
                      '${data.reactions} reactions',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '${data.commentsCount} comments',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '${data.postShares} shares',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey[400]),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// ── OVERVIEW SECTION ──
// ═══════════════════════════════════════════════════════

class _OverviewSection extends StatelessWidget {
  final PostInsightsData data;
  const _OverviewSection({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.info_outline, size: 18, color: Colors.grey[400]),
            ],
          ),
          const SizedBox(height: 16),
          _OverviewRow(
            label: 'Views',
            value: Formatters.formatNumber(data.viewCount),
          ),
          const Divider(height: 24),
          _OverviewRow(
            label: 'Interactions',
            value: Formatters.formatNumber(data.totalInteractions),
          ),
          const Divider(height: 24),
          _OverviewRow(
            label: 'Link clicks',
            value: data.clicks > 0
                ? Formatters.formatNumber(data.clicks)
                : '——',
          ),
          const Divider(height: 24),
          _OverviewRow(
            label: 'Follows',
            value: Formatters.formatNumber(data.uniqueViewers),
          ),
        ],
      ),
    );
  }
}

class _OverviewRow extends StatelessWidget {
  final String label;
  final String value;
  const _OverviewRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 15, color: Colors.black87),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════
// ── VIEWS SECTION WITH CHART ──
// ═══════════════════════════════════════════════════════

class _ViewsSection extends StatelessWidget {
  final PostInsightsData data;
  const _ViewsSection({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text(
                'Views',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.info_outline, size: 18, color: Colors.grey[400]),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            Formatters.formatNumber(data.viewCount),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),

          // Line Chart
          SizedBox(
            height: 180,
            child: _ViewsLineChart(timeline: data.timeline),
          ),
          const SizedBox(height: 12),

          // Legend
          Row(
            children: [
              _LegendDot(
                  color: const Color(0xFF4A1D6A), label: 'Total views'),
              const SizedBox(width: 20),
              _LegendDot(
                  color: const Color(0xFF80CBC4), label: 'Impressions'),
            ],
          ),
          const SizedBox(height: 20),

          // Followers vs Non-followers bar
          _SegmentedBar(
            leftLabel: 'Followers',
            rightLabel: 'Non-followers',
            leftValue: data.gender['male'] ?? 0,
            rightValue: data.gender['female'] ?? 0,
            leftColor: const Color(0xFF00897B),
            rightColor: const Color(0xFF004D40),
          ),
        ],
      ),
    );
  }
}

class _ViewsLineChart extends StatelessWidget {
  final List<PostInsightsTimeline> timeline;
  const _ViewsLineChart({required this.timeline});

  @override
  Widget build(BuildContext context) {
    if (timeline.isEmpty) {
      return const Center(
        child: Text('No timeline data', style: TextStyle(color: Colors.grey)),
      );
    }

    // Build cumulative impression spots
    final spots = <FlSpot>[];
    int cumulative = 0;
    for (int i = 0; i < timeline.length; i++) {
      cumulative += timeline[i].impressions;
      spots.add(FlSpot(i.toDouble(), cumulative.toDouble()));
    }

    final maxY = spots.isEmpty
        ? 100.0
        : spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.1;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY > 0 ? maxY / 3 : 1,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey[200]!,
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  Formatters.compactNumber(value.toInt()),
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: (timeline.length / 4).ceilToDouble().clamp(1, 100),
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= timeline.length) {
                  return const SizedBox.shrink();
                }
                final date = timeline[idx].date;
                final short = date.length >= 10
                    ? '${date.substring(8, 10)}/${date.substring(5, 7)}'
                    : date;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    short,
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  ),
                );
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          // Main views line
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: const Color(0xFF4A1D6A),
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
          // Flat line at bottom (representing secondary metric)
          LineChartBarData(
            spots: List.generate(
              spots.length,
              (i) => FlSpot(i.toDouble(), 0),
            ),
            isCurved: false,
            color: const Color(0xFF80CBC4),
            barWidth: 2,
            dotData: const FlDotData(show: false),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) {
              return spots.map((spot) {
                if (spot.barIndex == 1) return null;
                return LineTooltipItem(
                  '${spot.y.toInt()} views',
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList();
            },
          ),
        ),
        minY: 0,
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}

class _SegmentedBar extends StatelessWidget {
  final String leftLabel;
  final String rightLabel;
  final int leftValue;
  final int rightValue;
  final Color leftColor;
  final Color rightColor;

  const _SegmentedBar({
    required this.leftLabel,
    required this.rightLabel,
    required this.leftValue,
    required this.rightValue,
    required this.leftColor,
    required this.rightColor,
  });

  @override
  Widget build(BuildContext context) {
    final total = leftValue + rightValue;
    final leftPct = total > 0 ? leftValue / total : 0.5;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(leftLabel,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600)),
            Text(rightLabel,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 8,
            child: Row(
              children: [
                Expanded(
                  flex: (leftPct * 100).round().clamp(1, 99),
                  child: Container(color: leftColor),
                ),
                Expanded(
                  flex: ((1 - leftPct) * 100).round().clamp(1, 99),
                  child: Container(color: rightColor),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              Formatters.formatNumber(leftValue),
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              Formatters.formatNumber(rightValue),
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════
// ── INTERACTIONS SECTION ──
// ═══════════════════════════════════════════════════════

class _InteractionsSection extends StatelessWidget {
  final PostInsightsData data;
  const _InteractionsSection({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text(
                'Interactions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.info_outline, size: 18, color: Colors.grey[400]),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            Formatters.formatNumber(data.totalInteractions),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),

          // Breakdown
          _InteractionRow(
              label: 'Reactions',
              value: Formatters.formatNumber(data.reactions)),
          const Divider(height: 24),
          _InteractionRow(
              label: 'Comments',
              value: Formatters.formatNumber(data.commentsCount)),
          const Divider(height: 24),
          _InteractionRow(
              label: 'Shares',
              value: Formatters.formatNumber(data.postShares)),
          const Divider(height: 24),
          _InteractionRow(
              label: 'Saves',
              value: Formatters.formatNumber(data.saves)),
        ],
      ),
    );
  }
}

class _InteractionRow extends StatelessWidget {
  final String label;
  final String value;
  const _InteractionRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 15, color: Colors.black87),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════
// ── BOOST BUTTON ──
// ═══════════════════════════════════════════════════════

class _BoostButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      color: Colors.white,
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: FilledButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Boost feature coming soon'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF0E7490),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: const Text('Boost content'),
        ),
      ),
    );
  }
}
