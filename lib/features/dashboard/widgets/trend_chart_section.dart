import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../models/dashboard_models.dart';

/// Line chart showing selected KPI trend over the selected period.
class TrendChartSection extends StatelessWidget {
  final List<TrendPoint> trendData;
  final TrendMetric selectedMetric;
  final int period;
  final ValueChanged<TrendMetric> onMetricChanged;
  final ValueChanged<int> onPeriodChanged;

  const TrendChartSection({
    super.key,
    required this.trendData,
    required this.selectedMetric,
    required this.period,
    required this.onMetricChanged,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'Performance Trend',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),

          // Metric selector chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: TrendMetric.values.map((m) {
                final selected = m == selectedMetric;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_metricLabel(m)),
                    selected: selected,
                    onSelected: (_) => onMetricChanged(m),
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surfaceLight,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : AppColors.textSecondaryLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    side: BorderSide.none,
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Period toggle
          Row(
            children: [7, 14, 30].map((d) {
              final selected = d == period;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: InkWell(
                  onTap: () => onPeriodChanged(d),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: selected ? AppColors.primary : AppColors.dividerLight,
                      ),
                    ),
                    child: Text(
                      '${d}d',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected ? AppColors.primary : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Chart
          SizedBox(
            height: 200,
            child: trendData.isEmpty
                ? const Center(
                    child: Text(
                      'No trend data available',
                      style: TextStyle(
                        color: AppColors.textSecondaryLight,
                        fontSize: 13,
                      ),
                    ),
                  )
                : _buildChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    final spots = <FlSpot>[];
    for (int i = 0; i < trendData.length; i++) {
      spots.add(FlSpot(i.toDouble(), trendData[i].valueFor(selectedMetric).toDouble()));
    }

    final maxY = spots.isEmpty
        ? 10.0
        : spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.15;
    final minY = spots.isEmpty
        ? 0.0
        : spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) * 0.85;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY > 0 ? (maxY - minY) / 4 : 1,
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppColors.dividerLight.withValues(alpha: 0.5),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: (trendData.length / 5).ceilToDouble().clamp(1, 10),
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= trendData.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    DateFormat('d/M').format(trendData[idx].date),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (spots.length - 1).toDouble().clamp(0, double.infinity),
        minY: minY.clamp(0, double.infinity),
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: AppColors.primary,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                radius: 3,
                color: Colors.white,
                strokeWidth: 2,
                strokeColor: AppColors.primary,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary.withValues(alpha: 0.15),
                  AppColors.primary.withValues(alpha: 0.02),
                ],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final idx = spot.x.toInt();
                final dateStr = idx >= 0 && idx < trendData.length
                    ? DateFormat('MMM d').format(trendData[idx].date)
                    : '';
                return LineTooltipItem(
                  '$dateStr\n${spot.y.toInt()}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  String _metricLabel(TrendMetric m) => switch (m) {
        TrendMetric.reach => 'Reach',
        TrendMetric.engagement => 'Engagement',
        TrendMetric.impressions => 'Impressions',
        TrendMetric.followers => 'Followers',
      };
}
