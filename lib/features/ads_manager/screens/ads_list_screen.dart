/// ============================================================
/// Ads List Screen — List individual ads
/// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_constants.dart';
import '../providers/ads_manager_provider.dart';
import '../models/campaign_models.dart';
import '../utils/ads_helpers.dart';
import '../widgets/status_badge.dart';

class AdsListScreen extends StatefulWidget {
  const AdsListScreen({super.key});

  @override
  State<AdsListScreen> createState() => _AdsListScreenState();
}

class _AdsListScreenState extends State<AdsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdsManagerProvider>().fetchAds();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdsManagerProvider>();
    final ads = provider.ads;
    final loading = provider.adsLoading;
    final theme = Theme.of(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () =>
            provider.fetchAds(adSetId: provider.selectedAdSetId),
        child: loading && ads.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ads.isEmpty
                ? ListView(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image_outlined,
                                  size: 56,
                                  color: theme.colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.4)),
                              const SizedBox(height: 12),
                              Text(
                                'No ads yet',
                                style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Ads are created within ad sets',
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
                    itemCount: ads.length,
                    itemBuilder: (ctx, i) => _AdCard(
                      ad: ads[i],
                      onTap: () => context.push('/ads-manager/ad/${ads[i].id}'),
                    ),
                  ),
      ),
    );
  }
}

class _AdCard extends StatelessWidget {
  final Ad ad;
  final VoidCallback? onTap;
  const _AdCard({required this.ad, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.dividerColor.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            // Creative thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ad.creative.mediaUrl != null &&
                      ad.creative.mediaUrl!.isNotEmpty
                  ? Image.network(
                      ad.creative.thumbnailUrl ??
                          ApiConstants.mediaUrl(ad.creative.mediaUrl!),
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      errorBuilder: (_, e, s) => _placeholderThumb(theme),
                    )
                  : _placeholderThumb(theme),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ad.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      AdsStatusBadge(
                          status: ad.status.apiValue, fontSize: 9),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          ad.format.label,
                          style: const TextStyle(fontSize: 9),
                        ),
                      ),
                    ],
                  ),
                  if (ad.creative.headline != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      ad.creative.headline!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // CTA badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: kTealBrand.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                ad.callToAction.replaceAll('_', ' '),
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: kTealBrand,
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _placeholderThumb(ThemeData theme) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.image_outlined,
          size: 22,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
    );
  }
}
