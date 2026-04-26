/// ============================================================
/// Ads Manager V2 — Analytics Models
/// ============================================================
/// Matches /api/campaigns-v2/analytics endpoint responses.
/// ============================================================

class CampaignAnalytics {
  final String campaignId;
  final AnalyticsTotals totals;
  final List<DailyAnalytics> daily;

  const CampaignAnalytics({
    required this.campaignId,
    this.totals = const AnalyticsTotals(),
    this.daily = const [],
  });

  factory CampaignAnalytics.fromJson(Map<String, dynamic>? json) {
    if (json == null) return CampaignAnalytics(campaignId: '');
    final data = json['data'] ?? json;
    return CampaignAnalytics(
      campaignId: data['campaign_id'] ?? '',
      totals: AnalyticsTotals.fromJson(data['totals'] ?? data),
      daily: (data['daily'] as List?)
              ?.map((e) => DailyAnalytics.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class AdAnalyticsResponse {
  final String adId;
  final AnalyticsTotals totals;
  final List<DailyAnalytics> daily;

  const AdAnalyticsResponse({
    required this.adId,
    this.totals = const AnalyticsTotals(),
    this.daily = const [],
  });

  factory AdAnalyticsResponse.fromJson(Map<String, dynamic>? json) {
    if (json == null) return AdAnalyticsResponse(adId: '');
    final data = json['data'] ?? json;
    return AdAnalyticsResponse(
      adId: data['ad_id'] ?? '',
      totals: AnalyticsTotals.fromJson(data['totals'] ?? data),
      daily: (data['daily'] as List?)
              ?.map((e) => DailyAnalytics.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class AnalyticsTotals {
  final int impressions;
  final int clicks;
  final int reach;
  final int spendCents;
  final double ctr;
  final int cpcCents;
  final int cpmCents;
  final int reactions;
  final int comments;
  final int shares;
  final int videoViews;

  const AnalyticsTotals({
    this.impressions = 0,
    this.clicks = 0,
    this.reach = 0,
    this.spendCents = 0,
    this.ctr = 0,
    this.cpcCents = 0,
    this.cpmCents = 0,
    this.reactions = 0,
    this.comments = 0,
    this.shares = 0,
    this.videoViews = 0,
  });

  factory AnalyticsTotals.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AnalyticsTotals();
    return AnalyticsTotals(
      impressions: json['impressions'] ?? 0,
      clicks: json['clicks'] ?? 0,
      reach: json['reach'] ?? 0,
      spendCents: json['spend_cents'] ?? json['total_spent_cents'] ?? 0,
      ctr: (json['ctr'] as num?)?.toDouble() ?? 0,
      cpcCents: json['cpc_cents'] ?? 0,
      cpmCents: json['cpm_cents'] ?? 0,
      reactions: json['reactions'] ?? 0,
      comments: json['comments'] ?? 0,
      shares: json['shares'] ?? 0,
      videoViews: json['video_views'] ?? json['watch_10sec'] ?? 0,
    );
  }
}

class DailyAnalytics {
  final String date;
  final int impressions;
  final int clicks;
  final int reach;
  final int spendCents;

  const DailyAnalytics({
    required this.date,
    this.impressions = 0,
    this.clicks = 0,
    this.reach = 0,
    this.spendCents = 0,
  });

  factory DailyAnalytics.fromJson(Map<String, dynamic> json) {
    return DailyAnalytics(
      date: json['date'] ?? json['_id'] ?? '',
      impressions: json['impressions'] ?? 0,
      clicks: json['clicks'] ?? 0,
      reach: json['reach'] ?? 0,
      spendCents: json['spend_cents'] ?? json['cost_cents'] ?? 0,
    );
  }
}

class DemographicBreakdown {
  final List<DemographicSegment> ageGroups;
  final List<DemographicSegment> genders;
  final List<DemographicSegment> locations;

  const DemographicBreakdown({
    this.ageGroups = const [],
    this.genders = const [],
    this.locations = const [],
  });

  factory DemographicBreakdown.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DemographicBreakdown();
    final data = json['data'] ?? json;
    final demoData = data['demographics'] ?? data;
    return DemographicBreakdown(
      ageGroups: _parseSegments(demoData['age_group'] ?? demoData['age'] ?? demoData['age_groups']),
      genders: _parseSegments(demoData['gender'] ?? demoData['genders']),
      locations: _parseSegments(demoData['country'] ?? demoData['region'] ?? demoData['city'] ?? demoData['location'] ?? demoData['locations']),
    );
  }

  static List<DemographicSegment> _parseSegments(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) {
      return raw.map((e) => DemographicSegment.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    }
    return [];
  }
}

class DemographicSegment {
  final String label;
  final int impressions;
  final int clicks;
  final int spendCents;
  final double percentage;

  const DemographicSegment({
    required this.label,
    this.impressions = 0,
    this.clicks = 0,
    this.spendCents = 0,
    this.percentage = 0,
  });

  factory DemographicSegment.fromJson(Map<String, dynamic> json) {
    return DemographicSegment(
      label: json['label'] ?? json['value'] ?? json['_id'] ?? '',
      impressions: json['impressions'] ?? 0,
      clicks: json['clicks'] ?? 0,
      spendCents: json['spend_cents'] ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
    );
  }
}
