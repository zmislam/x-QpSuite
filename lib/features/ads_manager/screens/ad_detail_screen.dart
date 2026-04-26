import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/ads_manager_provider.dart';
import '../models/campaign_models.dart';
import '../models/analytics_models.dart';
import '../utils/ads_helpers.dart';
import '../../../core/constants/api_constants.dart';
import '../widgets/status_badge.dart';

class AdDetailScreen extends StatefulWidget {
  final String adId;
  const AdDetailScreen({super.key, required this.adId});

  @override
  State<AdDetailScreen> createState() => _AdDetailScreenState();
}

class _AdDetailScreenState extends State<AdDetailScreen> {
  bool _loading = true;
  String? _error;
  AdAnalyticsResponse? _analytics;
  DemographicBreakdown? _demographics;
  int _days = 7;
  String _chartMetric = 'impressions';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  Future<void> _fetchData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final provider = context.read<AdsManagerProvider>();
      final futures = await Future.wait([
        provider.fetchAdAnalytics(widget.adId, days: _days),
        provider.fetchAdDemographics(widget.adId, days: _days),
      ]);

      if (mounted) {
        setState(() {
          _analytics = futures[0] as AdAnalyticsResponse?;
          _demographics = futures[1] as DemographicBreakdown?;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load ad details.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdsManagerProvider>();
    final ad = provider.ads.firstWhere(
      (a) => a.id == widget.adId,
      orElse: () => Ad(
        id: widget.adId,
        adSetId: '',
        campaignId: '',
        name: 'Unknown Ad',
      ),
    );

    final adSet = provider.adSets.firstWhere(
      (s) => s.id == ad.adSetId,
      orElse: () => AdSet(id: ad.adSetId, campaignId: ad.campaignId, name: 'Unknown AdSet'),
    );

    final campaign = provider.campaigns.firstWhere(
      (c) => c.id == ad.campaignId,
      orElse: () => AdCampaign(id: ad.campaignId, name: 'Unknown Campaign'),
    );

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    String? getValidUrl(String? url1, String? url2) {
      if (url1 != null && url1.trim().isNotEmpty) return ApiConstants.mediaUrl(url1);
      if (url2 != null && url2.trim().isNotEmpty) return ApiConstants.mediaUrl(url2);
      return null;
    }
    
    final creativeImg = getValidUrl(ad.creative.thumbnailUrl, ad.creative.mediaUrl);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : RefreshIndicator(
                  onRefresh: _fetchData,
                  child: CustomScrollView(
                    slivers: [
                      SliverAppBar(
                        expandedHeight: creativeImg != null ? 240.0 : 120.0,
                        pinned: true,
                        leading: IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => context.pop(),
                        ),
                        actions: [
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Center(child: AdsStatusBadge(status: ad.status.apiValue)),
                          ),
                        ],
                        flexibleSpace: FlexibleSpaceBar(
                          titlePadding: const EdgeInsets.only(left: 48, bottom: 16, right: 80),
                          title: Text(
                            ad.name,
                            style: TextStyle(
                              color: creativeImg != null ? Colors.white : colorScheme.onSurface,
                              shadows: creativeImg != null ? const [Shadow(color: Colors.black87, blurRadius: 4)] : [],
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          background: creativeImg != null
                              ? Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    CachedNetworkImage(
                                      imageUrl: creativeImg,
                                      fit: BoxFit.cover,
                                      errorWidget: (c, u, e) => Container(color: colorScheme.surfaceContainerHighest),
                                    ),
                                    Container(
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [Colors.black54, Colors.transparent, Colors.black87],
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : null,
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildHeaderControls(),
                              const SizedBox(height: 16),
                              _buildKpiGrid(),
                              const SizedBox(height: 24),
                              _buildChartSection(theme),
                              const SizedBox(height: 24),
                              _buildSectionCard(
                                title: 'Creative Preview',
                                icon: Icons.palette,
                                theme: theme,
                                child: _buildCreativePreview(ad, theme),
                              ),
                              const SizedBox(height: 24),
                              _buildSectionCard(
                                title: 'Audience Targeting',
                                icon: Icons.group,
                                theme: theme,
                                child: _buildAudienceTargeting(adSet.audience, theme),
                              ),
                              const SizedBox(height: 24),
                              _buildSectionCard(
                                title: 'Placements & Budget',
                                icon: Icons.account_balance_wallet,
                                theme: theme,
                                child: _buildPlacementsAndBudget(adSet, theme),
                              ),
                              const SizedBox(height: 24),
                              _buildSectionCard(
                                title: 'Geographic & Demographic',
                                icon: Icons.map,
                                theme: theme,
                                child: _buildDemographics(theme),
                              ),
                              const SizedBox(height: 24),
                              _buildSectionCard(
                                title: 'Destination & Tracking',
                                icon: Icons.link,
                                theme: theme,
                                child: _buildDestinationTracking(ad, theme),
                              ),
                              const SizedBox(height: 24),
                              _buildSectionCard(
                                title: 'Ad & Campaign Information',
                                icon: Icons.info_outline,
                                theme: theme,
                                child: _buildCampaignInfo(campaign, adSet, ad, theme),
                              ),
                              const SizedBox(height: 48),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required ThemeData theme, required Widget child}) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: kTealBrand),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        DropdownButton<int>(
          value: _days,
          items: const [
            DropdownMenuItem(value: 7, child: Text('Last 7 Days')),
            DropdownMenuItem(value: 14, child: Text('Last 14 Days')),
            DropdownMenuItem(value: 30, child: Text('Last 30 Days')),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() => _days = val);
              _fetchData();
            }
          },
          underline: const SizedBox(),
          icon: const Icon(Icons.keyboard_arrow_down, size: 16),
          style: const TextStyle(fontSize: 13, color: Colors.black87),
        ),
        TextButton.icon(
          onPressed: _fetchData,
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Refresh', style: TextStyle(fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildKpiGrid() {
    final totals = _analytics?.totals ?? const AnalyticsTotals();

    return LayoutBuilder(
      builder: (context, constraints) {
        final safeWidth = (constraints.maxWidth.isFinite && constraints.maxWidth > 0) ? constraints.maxWidth : 400.0;
        final crossAxisCount = safeWidth > 600 ? 4 : 2;
        final cardWidth = (safeWidth - (crossAxisCount - 1) * 12) / crossAxisCount;
        final childAspectRatio = (cardWidth / 80).clamp(0.1, 10.0);

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: childAspectRatio,
          children: [
            _buildStatCard('Impressions', totals.impressions.toString(), Icons.visibility, Colors.blue),
            _buildStatCard('Clicks', totals.clicks.toString(), Icons.mouse, Colors.green),
            _buildStatCard('CTR', '${totals.ctr.toStringAsFixed(2)}%', Icons.percent, Colors.purple),
            _buildStatCard('Spend', centsToDisplay(totals.spendCents), Icons.attach_money, Colors.orange),
            _buildStatCard('CPC', centsToDisplay(totals.cpcCents), Icons.ads_click, Colors.teal),
            _buildStatCard('CPM', centsToDisplay(totals.cpmCents), Icons.layers, Colors.cyan),
            _buildStatCard('Reach', totals.reach.toString(), Icons.people, Colors.indigo),
            _buildStatCard('Reactions', totals.reactions.toString(), Icons.favorite, Colors.red),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection(ThemeData theme) {
    final daily = _analytics?.daily ?? [];

    return _buildSectionCard(
      title: 'Performance Trend',
      icon: Icons.trending_up,
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              DropdownButton<String>(
                value: _chartMetric,
                items: const [
                  DropdownMenuItem(value: 'impressions', child: Text('Impressions')),
                  DropdownMenuItem(value: 'clicks', child: Text('Clicks')),
                  DropdownMenuItem(value: 'cost', child: Text('Cost')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _chartMetric = val);
                },
                underline: const SizedBox(),
                style: const TextStyle(fontSize: 13, color: kTealBrand),
                icon: const Icon(Icons.arrow_drop_down, color: kTealBrand),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (daily.isEmpty)
            Container(
              height: 200,
              alignment: Alignment.center,
              child: const Text('No analytics data yet.'),
            )
          else
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  lineTouchData: LineTouchData(
                    handleBuiltInTouches: true,
                    getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
                      return spotIndexes.map((index) {
                        return TouchedSpotIndicatorData(
                          FlLine(color: kTealBrand, strokeWidth: 2),
                          FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) =>
                                FlDotCirclePainter(radius: 4, color: kTealBrand, strokeWidth: 2, strokeColor: Colors.white),
                          ),
                        );
                      }).toList();
                    },
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (touchedSpot) => theme.colorScheme.surface,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          return LineTooltipItem(
                            spot.y.toStringAsFixed(spot.y == spot.y.toInt() ? 0 : 2),
                            TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (val, meta) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            val.toInt().toString(),
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          if (val.toInt() >= 0 && val.toInt() < daily.length) {
                            final dateStr = daily[val.toInt()].date;
                            final shortDate = dateStr.length >= 10 ? dateStr.substring(5, 10) : dateStr;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                shortDate,
                                style: const TextStyle(fontSize: 9, color: Colors.grey),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: daily.asMap().entries.map((e) {
                        double yVal = 0;
                        if (_chartMetric == 'impressions') {
                          yVal = e.value.impressions.toDouble();
                        } else if (_chartMetric == 'clicks') {
                          yVal = e.value.clicks.toDouble();
                        } else if (_chartMetric == 'cost') {
                          yVal = e.value.spendCents / 100;
                        }
                        return FlSpot(e.key.toDouble(), yVal);
                      }).toList(),
                      isCurved: true,
                      curveSmoothness: 0.35,
                      color: kTealBrand,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            kTealBrand.withValues(alpha: 0.3),
                            kTealBrand.withValues(alpha: 0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCreativePreview(Ad ad, ThemeData theme) {
    final creative = ad.creative;
    final isVideo = ad.format == AdFormat.video || ad.format == AdFormat.reels;
    
    String? getValidUrl(String? url1, String? url2) {
      if (url1 != null && url1.trim().isNotEmpty) return ApiConstants.mediaUrl(url1);
      if (url2 != null && url2.trim().isNotEmpty) return ApiConstants.mediaUrl(url2);
      return null;
    }
    final previewUrl = getValidUrl(creative.thumbnailUrl, creative.mediaUrl);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (previewUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              alignment: Alignment.center,
              children: [
                CachedNetworkImage(
                  imageUrl: previewUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorWidget: (c, u, e) => Container(
                    height: 200,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.broken_image, size: 40),
                  ),
                ),
                if (isVideo)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow, color: Colors.white, size: 40),
                  ),
                if (isVideo)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('Video Ad', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        if (creative.headline != null)
          Text(creative.headline!, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        if (creative.primaryText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(creative.primaryText!, style: theme.textTheme.bodyMedium),
          ),
        if (creative.description != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(creative.description!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
      ],
    );
  }

  Widget _buildAudienceTargeting(Audience audience, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(Icons.public, 'Locations', audience.locations.map((l) => l.name ?? l.key ?? l.type).join(', ')),
        const SizedBox(height: 8),
        _buildInfoRow(Icons.person, 'Age', '${audience.demographics.ageMin} - ${audience.demographics.ageMax}'),
        const SizedBox(height: 8),
        _buildInfoRow(Icons.wc, 'Gender', audience.demographics.genders.join(', ')),
        const SizedBox(height: 16),
        if (audience.includeTargeting.isNotEmpty) ...[
          Text('Included Interests', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: audience.includeTargeting.map((t) => Chip(
              label: Text(t.name ?? t.id ?? 'Unknown', style: const TextStyle(fontSize: 12)),
              backgroundColor: theme.colorScheme.primaryContainer,
              side: BorderSide.none,
            )).toList(),
          ),
          const SizedBox(height: 16),
        ],
        if (audience.excludeTargeting.isNotEmpty) ...[
          Text('Excluded Interests', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: audience.excludeTargeting.map((t) => Chip(
              label: Text(t.name ?? t.id ?? 'Unknown', style: const TextStyle(fontSize: 12)),
              backgroundColor: theme.colorScheme.errorContainer,
              side: BorderSide.none,
            )).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildPlacementsAndBudget(AdSet adSet, ThemeData theme) {
    double spendProgress = 0;
    if (_analytics != null && adSet.dailyBudgetCents > 0) {
      final spend = _analytics!.totals.spendCents;
      final avgDailySpend = spend / (_days > 0 ? _days : 1);
      spendProgress = (avgDailySpend / adSet.dailyBudgetCents).clamp(0.0, 1.0);
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(Icons.layers, 'Placement', adSet.placementType.apiValue),
        if (adSet.placementType == PlacementType.manual && adSet.placements.isNotEmpty) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Text(adSet.placements.join(', '), style: theme.textTheme.bodyMedium),
          ),
        ],
        const SizedBox(height: 16),
        _buildInfoRow(Icons.attach_money, 'Budget Type', adSet.budgetType.apiValue),
        const SizedBox(height: 8),
        _buildInfoRow(Icons.monetization_on, 'Amount', adSet.budgetType == BudgetType.daily ? '${centsToDisplay(adSet.dailyBudgetCents)} / day' : '${centsToDisplay(adSet.lifetimeBudgetCents)} lifetime'),
        const SizedBox(height: 16),
        if (adSet.budgetType == BudgetType.daily) ...[
          Text('Avg Daily Spend vs Limit', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: spendProgress,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            color: spendProgress > 0.9 ? theme.colorScheme.error : kTealBrand,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ],
    );
  }

  Widget _buildDemographics(ThemeData theme) {
    if (_demographics == null) return const Text('No demographic data available.');
    
    if (_demographics!.locations.isEmpty && 
        _demographics!.ageGroups.isEmpty && 
        _demographics!.genders.isEmpty) {
      return const Text('No demographic data available.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_demographics!.locations.isNotEmpty) ...[
          Text('By Location', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._demographics!.locations.take(5).map((a) => _buildDemoRow(a.label, a.impressions, Colors.green)),
          const SizedBox(height: 16),
        ],
        if (_demographics!.ageGroups.isNotEmpty) ...[
          Text('By Age Group', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._demographics!.ageGroups.map((a) => _buildDemoRow(a.label, a.impressions, Colors.blue)),
          const SizedBox(height: 16),
        ],
        if (_demographics!.genders.isNotEmpty) ...[
          Text('By Gender', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._demographics!.genders.map((g) => _buildDemoRow(g.label, g.impressions, Colors.purple)),
        ],
      ],
    );
  }

  Widget _buildDemoRow(String label, int impressions, MaterialColor color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            flex: 3,
            child: LinearProgressIndicator(
              value: _getDemoPercentage(impressions),
              backgroundColor: color.shade100,
              color: color.shade500,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 50,
            child: Text(
              impressions.toString(),
              style: const TextStyle(fontSize: 11, color: Colors.grey),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  double _getDemoPercentage(int impressions) {
    final totals = _analytics?.totals.impressions ?? 1;
    if (totals == 0) return 0;
    return (impressions / totals).clamp(0.0, 1.0);
  }

  Widget _buildDestinationTracking(Ad ad, ThemeData theme) {
    final dest = ad.destination;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(Icons.smart_button, 'Call to Action', ad.callToAction),
        const SizedBox(height: 8),
        _buildInfoRow(Icons.link, 'Type', dest.type),
        if (dest.websiteUrl != null) ...[
          const SizedBox(height: 8),
          _buildInfoRow(Icons.open_in_browser, 'Website URL', dest.websiteUrl!),
        ],
      ],
    );
  }

  Widget _buildCampaignInfo(AdCampaign campaign, AdSet adSet, Ad ad, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(Icons.campaign, 'Campaign Name', campaign.name),
        const SizedBox(height: 8),
        _buildInfoRow(Icons.ads_click, 'AdSet Name', adSet.name),
        const SizedBox(height: 8),
        _buildInfoRow(Icons.track_changes, 'Objective', campaign.objective.label),
        const SizedBox(height: 8),
        _buildInfoRow(Icons.shopping_cart, 'Buying Type', campaign.buyingType),
        const SizedBox(height: 8),
        _buildInfoRow(Icons.admin_panel_settings, 'Admin Status', ad.adminStatus.name.toUpperCase()),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 13)),
        ),
      ],
    );
  }
}
