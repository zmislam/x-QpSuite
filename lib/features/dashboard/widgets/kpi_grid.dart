import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../models/dashboard_models.dart';

/// A 2×4 grid of KPI metric cards with value, change %, and trend arrow.
class KpiGrid extends StatelessWidget {
  final DashboardKpis kpis;

  const KpiGrid({super.key, required this.kpis});

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
          childAspectRatio: 1.5,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final (label, kpi) = items[index];
          return _KpiCard(
            label: label,
            kpi: kpi,
            icon: _iconMap[label] ?? Icons.analytics_outlined,
            color: _colorMap[label] ?? AppColors.primary,
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

  const _KpiCard({
    required this.label,
    required this.kpi,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = kpi.changePct >= 0;
    final trendColor = isPositive ? AppColors.success : AppColors.error;
    final trendIcon = isPositive ? Icons.trending_up : Icons.trending_down;

    return Container(
      padding: const EdgeInsets.all(12),
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
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondaryLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            Formatters.compactNumber(kpi.value),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(trendIcon, size: 12, color: trendColor),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  '${Formatters.formatPercent(kpi.changePct)} vs last period',
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
        ],
      ),
    );
  }
}
