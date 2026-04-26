/// ============================================================
/// Ad Sets Screen — List ad sets, filter by campaign
/// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ads_manager_provider.dart';
import '../models/campaign_models.dart';
import '../utils/ads_helpers.dart';
import '../widgets/status_badge.dart';
import 'ads_manager_shell.dart';

class AdSetsScreen extends StatefulWidget {
  const AdSetsScreen({super.key});

  @override
  State<AdSetsScreen> createState() => _AdSetsScreenState();
}

class _AdSetsScreenState extends State<AdSetsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdsManagerProvider>().fetchAdSets();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdsManagerProvider>();
    final adSets = provider.adSets;
    final loading = provider.adSetsLoading;
    final theme = Theme.of(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => provider.fetchAdSets(
            campaignId: provider.selectedCampaignId),
        child: loading && adSets.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : adSets.isEmpty
                ? ListView(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.layers_outlined,
                                  size: 56,
                                  color: theme.colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.4)),
                              const SizedBox(height: 12),
                              Text(
                                'No ad sets yet',
                                style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Create a campaign first, then add ad sets',
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: adSets.length,
                    itemBuilder: (ctx, i) =>
                        _AdSetCard(
                          adSet: adSets[i],
                          onTap: () {
                            provider.fetchAds(adSetId: adSets[i].id);
                            context.findAncestorStateOfType<AdsManagerShellState>()?.switchTab(3);
                          },
                        ),
                  ),
      ),
    );
  }
}

class _AdSetCard extends StatelessWidget {
  final AdSet adSet;
  final VoidCallback? onTap;
  const _AdSetCard({required this.adSet, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final budgetDisplay = adSet.budgetType == BudgetType.daily
        ? '${centsToDisplay(adSet.dailyBudgetCents)}/day'
        : '${centsToDisplay(adSet.lifetimeBudgetCents)} lifetime';

    final locCount = adSet.audience.locations.length;
    final ageRange =
        '${adSet.audience.demographics.ageMin}–${adSet.audience.demographics.ageMax}';
    final targetingParts = <String>[
      if (locCount > 0) '$locCount loc.',
      'Age $ageRange',
      if (adSet.audience.includeTargeting.isNotEmpty)
        '${adSet.audience.includeTargeting.length} interest${adSet.audience.includeTargeting.length > 1 ? 's' : ''}',
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.dividerColor.withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    adSet.name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AdsStatusBadge(status: adSet.status.apiValue),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.euro, size: 13,
                    color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  budgetDisplay,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: kTealBrand,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 14),
                Icon(Icons.schedule, size: 13,
                    color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    adSet.startDate != null
                        ? formatDateShort(adSet.startDate!.toIso8601String())
                        : 'Not scheduled',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              targetingParts.join(' • '),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.devices, size: 11,
                    color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  adSet.placementType == PlacementType.automatic
                      ? 'Auto placements'
                      : adSet.placements.join(', '),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }
}
