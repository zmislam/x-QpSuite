import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../models/dashboard_models.dart';

/// Full demographics section: Gender donut, Age bars, Top Countries, Top Cities.
/// Renders as a vertical stack of section cards.
class DemographicsSection extends StatelessWidget {
  final DemographicsData demographics;

  const DemographicsSection({super.key, required this.demographics});

  @override
  Widget build(BuildContext context) {
    if (demographics.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        // Row 1: Gender + Age
        if (demographics.gender.total > 0 || demographics.ageGroups.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (demographics.gender.total > 0)
                  Expanded(child: _GenderDonut(gender: demographics.gender)),
                if (demographics.gender.total > 0 && demographics.ageGroups.isNotEmpty)
                  const SizedBox(width: 10),
                if (demographics.ageGroups.isNotEmpty)
                  Expanded(child: _AgeDistribution(ageGroups: demographics.ageGroups)),
              ],
            ),
          ),

        if (demographics.gender.total > 0 || demographics.ageGroups.isNotEmpty)
          const SizedBox(height: 12),

        // Row 2: Countries + Cities
        if (demographics.topCountries.isNotEmpty || demographics.topCities.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (demographics.topCountries.isNotEmpty)
                  Expanded(
                    child: _LocationList(
                      title: 'Top Countries',
                      icon: Icons.public,
                      entries: demographics.topCountries,
                    ),
                  ),
                if (demographics.topCountries.isNotEmpty && demographics.topCities.isNotEmpty)
                  const SizedBox(width: 10),
                if (demographics.topCities.isNotEmpty)
                  Expanded(
                    child: _LocationList(
                      title: 'Top Cities',
                      icon: Icons.location_city,
                      entries: demographics.topCities,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────
// Gender Donut Chart
// ─────────────────────────────────────────

class _GenderDonut extends StatelessWidget {
  final GenderBreakdown gender;

  const _GenderDonut({required this.gender});

  @override
  Widget build(BuildContext context) {
    final total = gender.total;
    if (total == 0) return const SizedBox.shrink();

    final malePct = (gender.male / total * 100);
    final femalePct = (gender.female / total * 100);
    final otherPct = (gender.other / total * 100);

    return Container(
      padding: const EdgeInsets.all(14),
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
          const Text(
            'Gender',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Donut chart
          SizedBox(
            height: 120,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 30,
                sections: [
                  PieChartSectionData(
                    value: gender.male.toDouble(),
                    color: AppColors.chartBlue,
                    title: '${malePct.toStringAsFixed(0)}%',
                    titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                    radius: 24,
                  ),
                  PieChartSectionData(
                    value: gender.female.toDouble(),
                    color: AppColors.chartPink,
                    title: '${femalePct.toStringAsFixed(0)}%',
                    titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                    radius: 24,
                  ),
                  if (gender.other > 0)
                    PieChartSectionData(
                      value: gender.other.toDouble(),
                      color: AppColors.chartGrey,
                      title: '${otherPct.toStringAsFixed(0)}%',
                      titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                      radius: 24,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Legend
          _LegendRow(color: AppColors.chartBlue, label: 'Male', value: '${malePct.toStringAsFixed(1)}%'),
          const SizedBox(height: 4),
          _LegendRow(color: AppColors.chartPink, label: 'Female', value: '${femalePct.toStringAsFixed(1)}%'),
          if (gender.other > 0) ...[
            const SizedBox(height: 4),
            _LegendRow(color: AppColors.chartGrey, label: 'Other', value: '${otherPct.toStringAsFixed(1)}%'),
          ],
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _LegendRow({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ─────────────────────────────────────────
// Age Distribution Bar Chart
// ─────────────────────────────────────────

class _AgeDistribution extends StatelessWidget {
  final List<AgeGroup> ageGroups;

  const _AgeDistribution({required this.ageGroups});

  @override
  Widget build(BuildContext context) {
    if (ageGroups.isEmpty) return const SizedBox.shrink();

    final maxCount = ageGroups.map((e) => e.count).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(14),
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
          const Text(
            'Age Distribution',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Horizontal bars for each age group
          ...ageGroups.map((group) {
            final fraction = maxCount > 0 ? group.count / maxCount : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 42,
                    child: Text(
                      group.range,
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryLight),
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          children: [
                            Container(
                              height: 14,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            Container(
                              height: 14,
                              width: constraints.maxWidth * fraction,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 28,
                    child: Text(
                      Formatters.compactNumber(group.count),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Location List (Countries / Cities)
// ─────────────────────────────────────────

class _LocationList extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<LocationEntry> entries;

  const _LocationList({
    required this.title,
    required this.icon,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    // Show top 5 only
    final displayEntries = entries.take(5).toList();
    final maxCount = displayEntries.isNotEmpty
        ? displayEntries.map((e) => e.count).reduce((a, b) => a > b ? a : b)
        : 1;

    return Container(
      padding: const EdgeInsets.all(14),
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
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),

          ...displayEntries.map((entry) {
            final fraction = maxCount > 0 ? entry.count / maxCount : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          entry.name,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${entry.count}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: fraction,
                      minHeight: 4,
                      backgroundColor: AppColors.surfaceLight,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
