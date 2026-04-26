/// ============================================================
/// Ads Overview Screen — "At a Glance" Dashboard
/// ============================================================
/// Port of qp-web AdsManagerOverview.jsx — mobile-first design.
/// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ads_manager_provider.dart';
import '../models/billing_models.dart';
import '../utils/ads_helpers.dart';
import '../widgets/kpi_card.dart';
import '../widgets/period_selector.dart';

class AdsOverviewScreen extends StatefulWidget {
  const AdsOverviewScreen({super.key});

  @override
  State<AdsOverviewScreen> createState() => _AdsOverviewScreenState();
}

class _AdsOverviewScreenState extends State<AdsOverviewScreen> {
  int _days = 30;

  void _changePeriod(int days) {
    setState(() => _days = days);
    context.read<AdsManagerProvider>().fetchCostBreakdown(days: days);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdsManagerProvider>();
    final overview = provider.costBreakdown.overview;
    final campaigns = provider.campaigns;
    final payment = provider.paymentMethod;
    final loading =
        provider.campaignsLoading || provider.costBreakdownLoading;

    final unbilledCents = provider
            .costBreakdown.accountSummary['current_unbilled_spend_cents'] ??
        0;

    return RefreshIndicator(
      onRefresh: () => provider.initDashboard(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Period Selector ─────────────────────────────
          PeriodSelector(
            selected: _days,
            onChanged: _changePeriod,
          ),
          const SizedBox(height: 16),

          // ── Account Health Bar ─────────────────────────
          _AccountHealthBar(
            payment: payment,
            unbilledCents: unbilledCents as int,
            activeCampaigns: provider.activeCampaigns,
            totalCampaigns: campaigns.length,
          ),
          const SizedBox(height: 16),

          // ── KPI Cards (2 columns) ──────────────────────
          _KpiSection(overview: overview, days: _days, loading: loading),
          const SizedBox(height: 16),

          // ── Daily Spend Chart ──────────────────────────
          _SpendChartCard(
            dailySpend: provider.costBreakdown.dailySpend,
            loading: loading,
          ),
          const SizedBox(height: 16),

          // ── Campaign Status Summary ────────────────────
          _CampaignStatusCard(
            active: provider.activeCampaigns,
            paused: provider.pausedCampaigns,
            draft: provider.draftCampaigns,
            total: campaigns.length,
            loading: loading,
          ),
          const SizedBox(height: 16),

          // ── Top Campaigns by Spend ─────────────────────
          _TopCampaignsCard(
            campaigns: provider.costBreakdown.campaigns,
            loading: loading,
          ),
          const SizedBox(height: 16),

          // ── Quick Actions ──────────────────────────────
          _QuickActionsGrid(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Account Health Bar — 2x2 grid instead of 4 in a row
// ══════════════════════════════════════════════════════════════

class _AccountHealthBar extends StatelessWidget {
  final PaymentMethod payment;
  final int unbilledCents;
  final int activeCampaigns;
  final int totalCampaigns;

  const _AccountHealthBar({
    required this.payment,
    required this.unbilledCents,
    required this.activeCampaigns,
    required this.totalCampaigns,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _HealthTile(
                icon: Icons.account_balance_wallet,
                iconColor: kTealBrand,
                label: 'QP Wallet',
                value: payment.walletBalance != null
                    ? '€${payment.walletBalance!.toStringAsFixed(2)}'
                    : '—',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _HealthTile(
                icon: Icons.trending_up,
                iconColor: unbilledCents > 0
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFF94A3B8),
                label: 'Unbilled',
                value: centsToDisplay(unbilledCents),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _HealthTile(
                icon: payment.paymentType == 'wallet'
                    ? Icons.account_balance_wallet
                    : Icons.credit_card,
                iconColor: payment.hasPaymentMethod
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
                label: 'Payment',
                value: payment.displayName,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _HealthTile(
                icon: Icons.ads_click,
                iconColor: kTealBrand,
                label: 'Active',
                value: '$activeCampaigns / $totalCampaigns',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HealthTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _HealthTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// KPI Section — 2 columns, properly spaced
// ══════════════════════════════════════════════════════════════

class _KpiSection extends StatelessWidget {
  final CostOverview overview;
  final int days;
  final bool loading;

  const _KpiSection({
    required this.overview,
    required this.days,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final ctr = overview.ctr > 0
        ? '${overview.ctr.toStringAsFixed(2)}%'
        : overview.impressions > 0
            ? '${((overview.clicks / overview.impressions) * 100).toStringAsFixed(2)}%'
            : '0.00%';

    final cpc = overview.cpcCents > 0
        ? centsToDisplay(overview.cpcCents)
        : overview.clicks > 0
            ? centsToDisplay(
                (overview.totalSpentCents / overview.clicks).round())
            : '€0.00';

    final cpm = overview.cpmCents > 0
        ? centsToDisplay(overview.cpmCents)
        : overview.impressions > 0
            ? centsToDisplay(
                ((overview.totalSpentCents / overview.impressions) * 1000)
                    .round())
            : '€0.00';

    return Column(
      children: [
        // Row 1
        Row(
          children: [
            Expanded(
              child: KpiCard(
                icon: Icons.euro,
                label: 'Total Spend',
                value: loading ? '—' : centsToDisplay(overview.totalSpentCents),
                subtitle: '${days}d',
                iconColor: kTealBrand,
                loading: loading,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: KpiCard(
                icon: Icons.visibility,
                label: 'Impressions',
                value: loading ? '—' : shortNumber(overview.impressions),
                iconColor: const Color(0xFF6366F1),
                loading: loading,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Row 2
        Row(
          children: [
            Expanded(
              child: KpiCard(
                icon: Icons.touch_app,
                label: 'Clicks',
                value: loading ? '—' : shortNumber(overview.clicks),
                iconColor: const Color(0xFF8B5CF6),
                loading: loading,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: KpiCard(
                icon: Icons.trending_up,
                label: 'CTR',
                value: loading ? '—' : ctr,
                subtitle: 'Click-through',
                iconColor: const Color(0xFF10B981),
                loading: loading,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Row 3
        Row(
          children: [
            Expanded(
              child: KpiCard(
                icon: Icons.bolt,
                label: 'Avg CPC',
                value: loading ? '—' : cpc,
                subtitle: 'Per click',
                iconColor: const Color(0xFFF59E0B),
                loading: loading,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: KpiCard(
                icon: Icons.bar_chart,
                label: 'Avg CPM',
                value: loading ? '—' : cpm,
                subtitle: 'Per 1K impr',
                iconColor: const Color(0xFFF43F5E),
                loading: loading,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Daily Spend Chart
// ══════════════════════════════════════════════════════════════

class _SpendChartCard extends StatelessWidget {
  final List<DailySpend> dailySpend;
  final bool loading;

  const _SpendChartCard({
    required this.dailySpend,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.15),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily Spend',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(Icons.calendar_today,
                  size: 14, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'How much you spent each day',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 16),
          if (loading)
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
            )
          else if (dailySpend.isEmpty)
            SizedBox(
              height: 100,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.show_chart,
                        size: 28,
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.4)),
                    const SizedBox(height: 6),
                    Text(
                      'No spend data for this period',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 100,
              child: _MiniBarChart(data: dailySpend),
            ),
        ],
      ),
    );
  }
}

class _MiniBarChart extends StatelessWidget {
  final List<DailySpend> data;

  const _MiniBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxVal = data.fold<int>(
        0, (m, d) => d.costCents > m ? d.costCents : m);
    if (maxVal == 0) {
      return Center(
        child: Text(
          'No spend recorded',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: data.map((d) {
        final fraction = d.costCents / maxVal;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Tooltip(
              message:
                  '${formatDateShort(d.date)}\n${centsToDisplay(d.costCents)}',
              child: Container(
                height: (80 * fraction).clamp(3.0, 80.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      kTealBrand.withValues(alpha: 0.6),
                      kTealBrand,
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(3)),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Campaign Status Card
// ══════════════════════════════════════════════════════════════

class _CampaignStatusCard extends StatelessWidget {
  final int active, paused, draft, total;
  final bool loading;

  const _CampaignStatusCard({
    required this.active,
    required this.paused,
    required this.draft,
    required this.total,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.15),
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
          Text(
            'Campaign Status',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _StatusPill(
                  color: const Color(0xFF10B981),
                  label: 'Active',
                  count: active),
              const SizedBox(width: 12),
              _StatusPill(
                  color: const Color(0xFFF59E0B),
                  label: 'Paused',
                  count: paused),
              const SizedBox(width: 12),
              _StatusPill(
                  color: const Color(0xFF94A3B8),
                  label: 'Draft',
                  count: draft),
            ],
          ),
          if (total == 0 && !loading)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'No campaigns yet — create your first one!',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final Color color;
  final String label;
  final int count;

  const _StatusPill({
    required this.color,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Top Campaigns Table
// ══════════════════════════════════════════════════════════════

class _TopCampaignsCard extends StatelessWidget {
  final List<CampaignBreakdown> campaigns;
  final bool loading;

  const _TopCampaignsCard({
    required this.campaigns,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final top5 = List<CampaignBreakdown>.from(campaigns)
      ..sort((a, b) => b.totalSpentCents.compareTo(a.totalSpentCents));
    final display = top5.take(5).toList();

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.15),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Text(
              'Top Campaigns by Spend',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Divider(
            height: 1,
            color: theme.dividerColor.withValues(alpha: 0.15),
          ),
          if (loading)
            ...[1, 2, 3].map((_) => Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ))
          else if (display.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.campaign_outlined,
                        size: 28,
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.5)),
                    const SizedBox(height: 8),
                    Text(
                      'No campaign data yet',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...display.map((c) => _CampaignRow(campaign: c)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _CampaignRow extends StatelessWidget {
  final CampaignBreakdown campaign;
  const _CampaignRow({required this.campaign});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ctr = campaign.impressions > 0
        ? '${((campaign.clicks / campaign.impressions) * 100).toStringAsFixed(1)}%'
        : '—';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor(campaign.status),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  campaign.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (campaign.objective != null)
                  Text(
                    campaign.objective!.replaceAll('_', ' '),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            centsToDisplay(campaign.totalSpentCents),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: kTealBrand,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: Text(
              ctr,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Quick Actions Grid — 2 columns, proper sizing
// ══════════════════════════════════════════════════════════════

class _QuickActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actions = [
      _QuickAction(Icons.campaign, 'Campaigns', 'Create & manage'),
      _QuickAction(Icons.layers, 'Ad Sets', 'Budget & targeting'),
      _QuickAction(Icons.trending_up, 'Performance', 'Analytics'),
      _QuickAction(Icons.credit_card, 'Billing', 'Spend & invoices'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            'Quick Actions',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...List.generate(2, (row) {
          return Padding(
            padding: EdgeInsets.only(bottom: row < 1 ? 10 : 0),
            child: Row(
              children: [
                Expanded(
                  child: _QuickActionTile(action: actions[row * 2]),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickActionTile(action: actions[row * 2 + 1]),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final _QuickAction action;
  const _QuickActionTile({required this.action});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: kTealBrand.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(action.icon, size: 18, color: kTealBrand),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      action.desc,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final String desc;
  const _QuickAction(this.icon, this.label, this.desc);
}
