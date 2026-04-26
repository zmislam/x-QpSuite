/// ============================================================
/// Campaigns Screen — Campaign List + CRUD
/// ============================================================
/// Port of CampaignsTab.jsx from qp-web.
/// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/ads_manager_provider.dart';
import '../models/campaign_models.dart';
import '../utils/ads_helpers.dart';
import '../widgets/status_badge.dart';
import 'ads_manager_shell.dart';

class CampaignsScreen extends StatelessWidget {
  const CampaignsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdsManagerProvider>();
    final campaigns = provider.campaigns;
    final loading = provider.campaignsLoading;
    final theme = Theme.of(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => provider.fetchCampaigns(),
        child: loading && campaigns.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : campaigns.isEmpty
                ? _EmptyState(theme: theme)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: campaigns.length,
                    itemBuilder: (ctx, i) => _CampaignCard(
                      campaign: campaigns[i],
                      onTap: () {
                        provider.fetchAdSets(campaignId: campaigns[i].id);
                        context.findAncestorStateOfType<AdsManagerShellState>()?.switchTab(2);
                      },
                      onToggleStatus: () {
                        final c = campaigns[i];
                        final newStatus =
                            c.status == CampaignStatus.active
                                ? 'Paused'
                                : 'Active';
                        provider.updateCampaign(c.id, {'status': newStatus});
                      },
                    ),
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to create campaign wizard
          context.push('/ads-manager/create-campaign');
        },
        icon: const Icon(Icons.add),
        label: const Text('New Campaign'),
        backgroundColor: kTealBrand,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ThemeData theme;
  const _EmptyState({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.campaign_outlined,
              size: 64, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            'No campaigns yet',
            style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first campaign to start advertising',
            style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () =>
                context.push('/ads-manager/create-campaign'),
            icon: const Icon(Icons.add),
            label: const Text('Create Campaign'),
            style: FilledButton.styleFrom(
              backgroundColor: kTealBrand,
            ),
          ),
        ],
      ),
    );
  }
}

class _CampaignCard extends StatelessWidget {
  final AdCampaign campaign;
  final VoidCallback onTap;
  final VoidCallback onToggleStatus;

  const _CampaignCard({
    required this.campaign,
    required this.onTap,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Objective icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: kTealLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _objectiveIcon(campaign.objective),
                      size: 20,
                      color: kTealBrand,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name + objective
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          campaign.name,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          campaign.objective.label,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AdsStatusBadge(status: campaign.status.apiValue),
                ],
              ),
              const SizedBox(height: 12),
              // Bottom row: actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Admin status
                  if (campaign.adminStatus == AdminStatus.pending)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '⏳ Pending Review',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFD97706),
                        ),
                      ),
                    )
                  else if (campaign.adminStatus == AdminStatus.reject)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '✕ Rejected',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    )
                  else
                    const SizedBox(),
                  // Pause/Resume
                  if (campaign.status == CampaignStatus.active ||
                      campaign.status == CampaignStatus.paused)
                    TextButton.icon(
                      onPressed: onToggleStatus,
                      icon: Icon(
                        campaign.status == CampaignStatus.active
                            ? Icons.pause
                            : Icons.play_arrow,
                        size: 16,
                      ),
                      label: Text(
                        campaign.status == CampaignStatus.active
                            ? 'Pause'
                            : 'Resume',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              ),
              // Created date
              if (campaign.createdAt != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Created ${formatDateFull(campaign.createdAt!.toIso8601String())}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _objectiveIcon(CampaignObjective obj) {
    switch (obj) {
      case CampaignObjective.awareness:
        return Icons.visibility;
      case CampaignObjective.traffic:
        return Icons.open_in_browser;
      case CampaignObjective.engagement:
        return Icons.favorite;
      case CampaignObjective.leads:
        return Icons.contact_mail;
      case CampaignObjective.appPromotion:
        return Icons.phone_android;
      case CampaignObjective.sales:
        return Icons.shopping_cart;
      case CampaignObjective.reach:
        return Icons.people;
      case CampaignObjective.leadGeneration:
        return Icons.assignment;
      case CampaignObjective.messages:
        return Icons.message;
      case CampaignObjective.catalogSales:
        return Icons.storefront;
      case CampaignObjective.storeTraffic:
        return Icons.store;
    }
  }
}
