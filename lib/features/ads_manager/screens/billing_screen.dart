/// ============================================================
/// Billing Screen — Cost Breakdown Dashboard
/// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ads_manager_provider.dart';
import '../models/billing_models.dart';
import '../utils/ads_helpers.dart';
import '../widgets/period_selector.dart';
import '../widgets/kpi_card.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  int _days = 30;

  void _changePeriod(int days) {
    setState(() => _days = days);
    context.read<AdsManagerProvider>().fetchCostBreakdown(days: days);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdsManagerProvider>();
    final breakdown = provider.costBreakdown;
    final payment = provider.paymentMethod;
    final loading = provider.costBreakdownLoading;

    final unbilledCents =
        breakdown.accountSummary['current_unbilled_spend_cents'] ?? 0;

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          provider.fetchCostBreakdown(days: _days),
          provider.fetchPaymentMethod(),
        ]);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          PeriodSelector(selected: _days, onChanged: _changePeriod),
          const SizedBox(height: 16),

          // Billing summary
          _BillingSummaryCard(
            payment: payment,
            totalSpent: breakdown.overview.totalSpentCents,
            unbilled: unbilledCents as int,
            loading: loading,
          ),
          const SizedBox(height: 16),

          // KPI row — 2 columns
          Row(
            children: [
              Expanded(
                child: KpiCard(
                  icon: Icons.visibility,
                  label: 'Impressions',
                  value: loading
                      ? '—'
                      : shortNumber(breakdown.overview.impressions),
                  iconColor: const Color(0xFF6366F1),
                  loading: loading,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: KpiCard(
                  icon: Icons.touch_app,
                  label: 'Clicks',
                  value: loading
                      ? '—'
                      : shortNumber(breakdown.overview.clicks),
                  iconColor: const Color(0xFF8B5CF6),
                  loading: loading,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Campaign cost breakdown
          _CostBreakdownTable(
            campaigns: breakdown.campaigns,
            loading: loading,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _BillingSummaryCard extends StatelessWidget {
  final PaymentMethod payment;
  final int totalSpent;
  final int unbilled;
  final bool loading;

  const _BillingSummaryCard({
    required this.payment,
    required this.totalSpent,
    required this.unbilled,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kTealBrand, kTealDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kTealBrand.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'BILLING SUMMARY',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            loading ? '—' : centsToDisplay(totalSpent),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _BillingSummaryItem(
                  label: 'Payment',
                  value: payment.displayName,
                  icon: payment.paymentType == 'wallet'
                      ? Icons.account_balance_wallet
                      : Icons.credit_card,
                ),
              ),
              Expanded(
                child: _BillingSummaryItem(
                  label: 'Unbilled',
                  value: centsToDisplay(unbilled),
                  icon: Icons.receipt_long,
                ),
              ),
              if (payment.walletBalance != null)
                Expanded(
                  child: _BillingSummaryItem(
                    label: 'Wallet',
                    value:
                        '€${payment.walletBalance!.toStringAsFixed(2)}',
                    icon: Icons.account_balance_wallet,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BillingSummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _BillingSummaryItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: Colors.white60),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _CostBreakdownTable extends StatelessWidget {
  final List<CampaignBreakdown> campaigns;
  final bool loading;

  const _CostBreakdownTable({
    required this.campaigns,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sorted = List<CampaignBreakdown>.from(campaigns)
      ..sort((a, b) =>
          b.totalSpentCents.compareTo(a.totalSpentCents));

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
              'Cost by Campaign',
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
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (sorted.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No spend data',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ),
            )
          else
            ...sorted.map((c) => _CostRow(campaign: c)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _CostRow extends StatelessWidget {
  final CampaignBreakdown campaign;
  const _CostRow({required this.campaign});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
            child: Text(
              campaign.name,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${shortNumber(campaign.impressions)} impr',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            centsToDisplay(campaign.totalSpentCents),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: kTealBrand,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
