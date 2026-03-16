import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../features/page_switcher/providers/managed_pages_provider.dart';
import '../../../shared/widgets/kpi_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/page_switcher.dart';
import '../../../shared/widgets/qp_loading.dart';
import '../models/dashboard_models.dart';
import '../providers/dashboard_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDashboard());
  }

  void _loadDashboard() {
    final pageId =
        context.read<ManagedPagesProvider>().activePageId;
    if (pageId != null) {
      context.read<DashboardProvider>().fetchDashboard(pageId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashProvider = context.watch<DashboardProvider>();
    final pagesProvider = context.watch<ManagedPagesProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const PageSwitcher(),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboard,
          ),
        ],
      ),
      body: _buildBody(dashProvider, pagesProvider),
    );
  }

  Widget _buildBody(
      DashboardProvider dash, ManagedPagesProvider pages) {
    if (pages.activePage == null) {
      return const EmptyState(
        icon: Icons.business,
        title: 'No pages found',
        subtitle: 'Create a page to get started with QP Suite.',
      );
    }

    if (dash.isLoading && dash.data == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: QpLoading(itemCount: 5, height: 100),
      );
    }

    if (dash.error != null && dash.data == null) {
      return ErrorState(
        message: dash.error!,
        onRetry: _loadDashboard,
      );
    }

    final data = dash.data;
    if (data == null) {
      return const EmptyState(
        icon: Icons.dashboard,
        title: 'No data yet',
        subtitle: 'Start posting content to see your dashboard.',
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadDashboard(),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // ── Period Toggle ──
          _PeriodToggle(
            selected: dash.period,
            onChanged: (days) {
              dash.setPeriod(days, pages.activePageId!);
            },
          ),
          const SizedBox(height: 12),

          // ── KPI Grid ──
          _KpiGrid(kpis: data.kpis),
          const SizedBox(height: 20),

          // ── Trend Chart ──
          _TrendChart(
            trend: data.trend,
            metric: dash.selectedMetric,
            onMetricChanged: dash.setSelectedMetric,
          ),
          const SizedBox(height: 20),

          // ── Top Posts ──
          if (data.topPosts.isNotEmpty) ...[
            _SectionHeader(title: 'Top Performing Posts'),
            const SizedBox(height: 8),
            ...data.topPosts.map((p) => _TopPostTile(post: p)),
            const SizedBox(height: 20),
          ],

          // ── Recent Activity ──
          if (data.recentActivity.isNotEmpty) ...[
            _SectionHeader(title: 'Recent Activity'),
            const SizedBox(height: 8),
            ...data.recentActivity.map((a) => _ActivityTile(activity: a)),
            const SizedBox(height: 20),
          ],

          // ── Onboarding ──
          if (!data.onboarding.isComplete)
            _OnboardingCard(onboarding: data.onboarding),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─── Period Toggle ─────────────────────────────────

class _PeriodToggle extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const _PeriodToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const periods = [7, 14, 30, 0];
    const labels = ['7d', '14d', '30d', 'All'];

    return Row(
      children: List.generate(periods.length, (i) {
        final isActive = periods[i] == selected;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(labels[i]),
            selected: isActive,
            onSelected: (_) => onChanged(periods[i]),
          ),
        );
      }),
    );
  }
}

// ─── KPI Grid ──────────────────────────────────────

class _KpiGrid extends StatelessWidget {
  final DashboardKpis kpis;
  const _KpiGrid({required this.kpis});

  @override
  Widget build(BuildContext context) {
    final items = kpis.toList();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.6,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final (label, kpi) = items[i];
        return KpiCard(
          label: label,
          value: kpi.value,
          trendPercent: kpi.changePct,
        );
      },
    );
  }
}

// ─── Trend Chart ───────────────────────────────────

class _TrendChart extends StatelessWidget {
  final List<TrendPoint> trend;
  final TrendMetric metric;
  final ValueChanged<TrendMetric> onMetricChanged;

  const _TrendChart({
    required this.trend,
    required this.metric,
    required this.onMetricChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (trend.isEmpty) {
      return const SizedBox.shrink();
    }

    final spots = trend.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.valueFor(metric).toDouble());
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Trend', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            // Metric selector
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: TrendMetric.values.map((m) {
                  final isActive = m == metric;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(m.name[0].toUpperCase() + m.name.substring(1)),
                      selected: isActive,
                      onSelected: (_) => onMetricChanged(m),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, _) => Text(
                          Formatters.compactNumber(value),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: (trend.length / 5).ceilToDouble().clamp(1, 100),
                        getTitlesWidget: (value, _) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= trend.length) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            Formatters.formatShortDate(trend[idx].date),
                            style: const TextStyle(fontSize: 9),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(),
                    topTitles: const AxisTitles(),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 2.5,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primary.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Top Post Tile ─────────────────────────────────

class _TopPostTile extends StatelessWidget {
  final TopPost post;
  const _TopPostTile({required this.post});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Thumbnail
            if (post.image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  post.image!,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 56,
                    height: 56,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, size: 24),
                  ),
                ),
              )
            else
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.article, color: AppColors.primary),
              ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.description.length > 120
                        ? '${post.description.substring(0, 120)}…'
                        : post.description,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${Formatters.compactNumber(post.engagement)} engagements  ·  ${Formatters.compactNumber(post.views)} views',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Activity Tile ─────────────────────────────────

class _ActivityTile extends StatelessWidget {
  final RecentActivity activity;
  const _ActivityTile({required this.activity});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    IconData icon;
    switch (activity.type) {
      case 'reaction':
        icon = Icons.favorite;
        break;
      case 'comment':
        icon = Icons.chat_bubble;
        break;
      case 'new_follower':
        icon = Icons.person_add;
        break;
      default:
        icon = Icons.notifications;
    }

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 18,
        backgroundImage: activity.userPic != null
            ? NetworkImage(activity.userPic!)
            : null,
        child: activity.userPic == null ? Icon(icon, size: 18) : null,
      ),
      title: Text(activity.message, style: theme.textTheme.bodyMedium),
      subtitle: Text(
        Formatters.formatTimeAgo(activity.createdAt),
        style: theme.textTheme.bodySmall,
      ),
    );
  }
}

// ─── Onboarding Card ───────────────────────────────

class _OnboardingCard extends StatelessWidget {
  final OnboardingProgress onboarding;
  const _OnboardingCard({required this.onboarding});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = onboarding.completed / onboarding.total;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Get Started', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 4),
            Text(
              '${onboarding.completed} of ${onboarding.total} steps completed',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            _step('Connect social accounts', onboarding.connectedSocial),
            _step('Create your first post', onboarding.createdPost),
            _step('Reply to a message', onboarding.repliedMessage),
            _step('Grow your audience', onboarding.grewAudience),
          ],
        ),
      ),
    );
  }

  Widget _step(String label, bool done) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.circle_outlined,
            size: 20,
            color: done ? AppColors.success : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              decoration: done ? TextDecoration.lineThrough : null,
              color: done ? Colors.grey : null,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Header ────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }
}
