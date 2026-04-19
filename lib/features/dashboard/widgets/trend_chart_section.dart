import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../models/dashboard_models.dart';

/// Area chart showing overlaid performance metrics (Reach, Engagement, Impressions)
/// with metric selector chips. Also includes a Follower Growth chart below.
class TrendChartSection extends StatelessWidget {
  final List<TrendPoint> trendData;
  final TrendMetric selectedMetric;
  final ValueChanged<TrendMetric> onMetricChanged;

  const TrendChartSection({
    super.key,
    required this.trendData,
    required this.selectedMetric,
    required this.onMetricChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Performance Trends Card ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.dividerLight.withValues(alpha: 0.4)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.trending_up_rounded, size: 20, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Text(
                      'Performance Trends',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Last ${trendData.length} days',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                ),
                const SizedBox(height: 14),

                // Metric selector chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: TrendMetric.values.map((m) {
                      final selected = m == selectedMetric;
                      final chipColor = _metricColor(m);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(_metricLabel(m)),
                          selected: selected,
                          onSelected: (_) => onMetricChanged(m),
                          selectedColor: chipColor,
                          backgroundColor: AppColors.surfaceLight,
                          labelStyle: TextStyle(
                            color: selected ? Colors.white : AppColors.textSecondaryLight,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          side: BorderSide.none,
                          showCheckmark: false,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // Area Chart
                SizedBox(
                  height: 200,
                  child: trendData.isEmpty
                      ? const Center(
                          child: Text(
                            'No trend data available',
                            style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
                          ),
                        )
                      : _buildAreaChart(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Follower Growth Card ──
          if (trendData.length >= 2)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.dividerLight.withValues(alpha: 0.4)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.people_rounded, size: 20, color: AppColors.success),
                      SizedBox(width: 8),
                      Text(
                        'Follower Growth',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Legend
                  Row(
                    children: [
                      _ChartLegend(color: AppColors.primary, label: 'Total Followers'),
                      const SizedBox(width: 16),
                      _ChartLegend(color: AppColors.success, label: 'New Followers', dashed: true),
                    ],
                  ),
                  const SizedBox(height: 14),

                  SizedBox(height: 160, child: _buildFollowerChart()),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Area chart with highlighted selected metric and faded others ──
  Widget _buildAreaChart() {
    final color = _metricColor(selectedMetric);

    // Build spots for the selected metric
    final spots = <FlSpot>[];
    for (int i = 0; i < trendData.length; i++) {
      spots.add(FlSpot(i.toDouble(), trendData[i].valueFor(selectedMetric).toDouble()));
    }

    final values = spots.map((s) => s.y).toList();
    final axis = _resolveYAxis(values, divisions: 4);

    // Build faded lines for other metrics
    final otherLines = <LineChartBarData>[];
    for (final m in TrendMetric.values) {
      if (m == selectedMetric) continue;
      final otherSpots = <FlSpot>[];
      for (int i = 0; i < trendData.length; i++) {
        otherSpots.add(FlSpot(i.toDouble(), trendData[i].valueFor(m).toDouble()));
      }
      otherLines.add(LineChartBarData(
        spots: otherSpots,
        isCurved: true,
        curveSmoothness: 0.3,
        color: _metricColor(m).withValues(alpha: 0.2),
        barWidth: 1.5,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: false),
      ));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: axis.interval,
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppColors.dividerLight.withValues(alpha: 0.4),
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
                if (idx < 0 || idx >= trendData.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    DateFormat('d/M').format(trendData[idx].date),
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryLight),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        clipData: FlClipData.all(),
        minX: 0,
        maxX: (spots.length - 1).toDouble().clamp(0, double.infinity),
        minY: axis.minY,
        maxY: axis.maxY,
        lineBarsData: [
          // Other metrics (faded lines behind)
          ...otherLines,
          // Selected metric (prominent area chart)
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: color,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                radius: 3,
                color: Colors.white,
                strokeWidth: 2,
                strokeColor: color,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withValues(alpha: 0.2),
                  color.withValues(alpha: 0.02),
                ],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          getTouchedSpotIndicator: (barData, spotIndexes) => spotIndexes
              .map(
                (_) => TouchedSpotIndicatorData(
                  const FlLine(color: Colors.transparent, strokeWidth: 0),
                  const FlDotData(show: false),
                ),
              )
              .toList(),
          touchTooltipData: LineTouchTooltipData(
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final idx = spot.x.toInt();
                final dateStr = idx >= 0 && idx < trendData.length
                    ? DateFormat('MMM d').format(trendData[idx].date)
                    : '';
                return LineTooltipItem(
                  '$dateStr\n${spot.y.toInt()}',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  // ── Follower Growth chart: total line (solid) + new followers (dashed) ──
  Widget _buildFollowerChart() {
    final totalSpots = <FlSpot>[];
    final newSpots = <FlSpot>[];
    for (int i = 0; i < trendData.length; i++) {
      totalSpots.add(FlSpot(i.toDouble(), trendData[i].followersTotal.toDouble()));
      newSpots.add(FlSpot(i.toDouble(), trendData[i].followersGained.toDouble()));
    }

    final allValues = [...totalSpots.map((s) => s.y), ...newSpots.map((s) => s.y)];
    final axis = _resolveYAxis(allValues, divisions: 3);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: axis.interval,
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppColors.dividerLight.withValues(alpha: 0.4),
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
                if (idx < 0 || idx >= trendData.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    DateFormat('d/M').format(trendData[idx].date),
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryLight),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        clipData: FlClipData.all(),
        minX: 0,
        maxX: (trendData.length - 1).toDouble().clamp(0, double.infinity),
        minY: axis.minY,
        maxY: axis.maxY,
        lineBarsData: [
          // Total followers (solid blue)
          LineChartBarData(
            spots: totalSpots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: AppColors.primary,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary.withValues(alpha: 0.12),
                  AppColors.primary.withValues(alpha: 0.01),
                ],
              ),
            ),
          ),
          // New followers (dashed green)
          LineChartBarData(
            spots: newSpots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: AppColors.success,
            barWidth: 2,
            isStrokeCapRound: true,
            dashArray: [6, 4],
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          getTouchedSpotIndicator: (barData, spotIndexes) => spotIndexes
              .map(
                (_) => TouchedSpotIndicatorData(
                  const FlLine(color: Colors.transparent, strokeWidth: 0),
                  const FlDotData(show: false),
                ),
              )
              .toList(),
          touchTooltipData: LineTouchTooltipData(
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final idx = spot.x.toInt();
                final dateStr = idx >= 0 && idx < trendData.length
                    ? DateFormat('MMM d').format(trendData[idx].date)
                    : '';
                final isTotal = spot.barIndex == 0;
                return LineTooltipItem(
                  '${isTotal ? "Total" : "New"}: ${spot.y.toInt()}\n$dateStr',
                  TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Color _metricColor(TrendMetric m) => switch (m) {
        TrendMetric.reach => AppColors.chartBlue,
        TrendMetric.engagement => AppColors.chartPink,
        TrendMetric.impressions => AppColors.chartOrange,
        TrendMetric.followers => AppColors.chartGreen,
      };

  ({double minY, double maxY, double interval}) _resolveYAxis(
    List<double> values, {
    required int divisions,
  }) {
    if (values.isEmpty) {
      return (minY: 0, maxY: 1, interval: 1);
    }

    final maxRaw = values.reduce((a, b) => a > b ? a : b);
    final minRaw = values.reduce((a, b) => a < b ? a : b);
    final range = (maxRaw - minRaw).abs();

    if (range < 0.0001) {
      final bump = maxRaw == 0 ? 1.0 : maxRaw.abs() * 0.1;
      final safeMin = (minRaw - bump).clamp(0.0, double.infinity);
      final safeMax = maxRaw + bump;
      final interval = (safeMax - safeMin) / divisions;
      return (
        minY: safeMin,
        maxY: safeMax <= safeMin ? safeMin + 1 : safeMax,
        interval: interval > 0 ? interval : 1,
      );
    }

    final paddedMin = (minRaw - (range * 0.15)).clamp(0.0, double.infinity);
    final paddedMax = maxRaw + (range * 0.15);
    final interval = (paddedMax - paddedMin) / divisions;

    return (
      minY: paddedMin,
      maxY: paddedMax <= paddedMin ? paddedMin + 1 : paddedMax,
      interval: interval > 0 ? interval : 1,
    );
  }

  String _metricLabel(TrendMetric m) => switch (m) {
        TrendMetric.reach => 'Reach',
        TrendMetric.engagement => 'Engagement',
        TrendMetric.impressions => 'Impressions',
        TrendMetric.followers => 'Followers',
      };
}

class _ChartLegend extends StatelessWidget {
  final Color color;
  final String label;
  final bool dashed;

  const _ChartLegend({required this.color, required this.label, this.dashed = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (dashed)
          // Dashed line indicator
          SizedBox(
            width: 16,
            height: 2,
            child: CustomPaint(painter: _DashedLinePainter(color: color)),
          )
        else
          Container(width: 16, height: 3, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
      ],
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    const dashWidth = 3.0;
    const dashSpace = 2.0;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, size.height / 2), Offset(startX + dashWidth, size.height / 2), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
