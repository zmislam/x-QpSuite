import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../models/dashboard_models.dart';

/// A 2×4 grid of KPI metric cards with value, change %, trend arrow, and sparkline.
class KpiGrid extends StatelessWidget {
  final DashboardKpis kpis;
  final List<TrendPoint> trendData;

  const KpiGrid({super.key, required this.kpis, required this.trendData});

  static const _iconMap = <String, IconData>{
    'Followers': Icons.people_outline,
    'Reach': Icons.visibility_outlined,
    'Engagement': Icons.touch_app_outlined,
    'Impressions': Icons.remove_red_eye_outlined,
    'Clicks': Icons.ads_click,
    'Page Views': Icons.web_outlined,
    'Messages': Icons.chat_bubble_outline,
    'Posts': Icons.article_outlined,
  };

  static const _colorMap = <String, Color>{
    'Followers': Color(0xFF1B74E4),
    'Reach': Color(0xFF9C27B0),
    'Engagement': Color(0xFFE91E63),
    'Impressions': Color(0xFFFF9800),
    'Clicks': Color(0xFF00BCD4),
    'Page Views': Color(0xFF4CAF50),
    'Messages': Color(0xFF3F51B5),
    'Posts': Color(0xFF795548),
  };

  /// Extract sparkline data points for each KPI from the trend array.
  List<double> _sparklineFor(String label) {
    if (trendData.isEmpty) return [];
    return trendData.map((t) {
      return switch (label) {
        'Followers' => t.followersTotal.toDouble(),
        'Reach' => t.totalReach.toDouble(),
        'Engagement' => t.totalEngagement.toDouble(),
        'Impressions' => t.totalImpressions.toDouble(),
        'Clicks' => t.totalClicks.toDouble(),
        'Page Views' => t.pageViews.toDouble(),
        'Messages' => t.messagesReceived.toDouble(),
        'Posts' => t.postsPublished.toDouble(),
        _ => 0.0,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = kpis.toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.15,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final (label, kpi) = items[index];
          return _KpiCard(
            label: label,
            kpi: kpi,
            icon: _iconMap[label] ?? Icons.analytics_outlined,
            color: _colorMap[label] ?? AppColors.primary,
            sparklineData: _sparklineFor(label),
          );
        },
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final DashboardKpi kpi;
  final IconData icon;
  final Color color;
  final List<double> sparklineData;

  const _KpiCard({
    required this.label,
    required this.kpi,
    required this.icon,
    required this.color,
    required this.sparklineData,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = kpi.changePct >= 0;
    final trendColor = isPositive ? AppColors.success : AppColors.error;
    final trendIcon = isPositive ? Icons.trending_up : Icons.trending_down;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.dividerLight.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: label + colored icon circle
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 15, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondaryLight,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Value
          Text(
            Formatters.compactNumber(kpi.value),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 2),

          // Trend %
          Row(
            children: [
              Icon(trendIcon, size: 12, color: trendColor),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  '${Formatters.formatPercent(kpi.changePct)} vs prev',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: trendColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const Spacer(),

          // Sparkline mini-chart at bottom
          if (sparklineData.length >= 2)
            SizedBox(
              height: 28,
              child: _Sparkline(data: sparklineData, color: color),
            ),
        ],
      ),
    );
  }
}

/// Minimal sparkline using fl_chart — no axes, no labels, just the trend line.
class _Sparkline extends StatelessWidget {
  final List<double> data;
  final Color color;

  const _Sparkline({required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    for (int i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[i]));
    }

    final values = data.where((v) => v.isFinite).toList();
    if (values.isEmpty) return const SizedBox.shrink();

    final maxY = values.reduce((a, b) => a > b ? a : b);
    final minY = values.reduce((a, b) => a < b ? a : b);
    final range = maxY - minY;
    final yPadding = range.abs() < 0.0001
      ? (maxY == 0 ? 1.0 : maxY.abs() * 0.1)
      : range * 0.1;
    final safeMinY = (minY - yPadding).clamp(0.0, double.infinity);
    final safeMaxY = maxY + yPadding;

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (spots.length - 1).toDouble(),
        minY: safeMinY,
        maxY: safeMaxY <= safeMinY ? safeMinY + 1 : safeMaxY,
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: color,
            barWidth: 1.8,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
    );
  }
}
