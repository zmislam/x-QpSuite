// Models for the Insights & Analytics feature.

import '../../../core/constants/api_constants.dart';

class InsightsSummary {
  final int reach;
  final double reachTrend;
  final int impressions;
  final double impressionsTrend;
  final int engagement;
  final double engagementTrend;
  final int pageViews;
  final double pageViewsTrend;
  final int newFollowers;
  final double newFollowersTrend;
  final int postsPublished;
  final int messagesReceived;

  InsightsSummary({
    required this.reach,
    required this.reachTrend,
    required this.impressions,
    required this.impressionsTrend,
    required this.engagement,
    required this.engagementTrend,
    required this.pageViews,
    required this.pageViewsTrend,
    required this.newFollowers,
    required this.newFollowersTrend,
    required this.postsPublished,
    required this.messagesReceived,
  });

  factory InsightsSummary.fromJson(Map<String, dynamic> json) {
    return InsightsSummary(
      reach: json['reach']?['value'] ?? 0,
      reachTrend: (json['reach']?['trend'] ?? 0).toDouble(),
      impressions: json['impressions']?['value'] ?? 0,
      impressionsTrend: (json['impressions']?['trend'] ?? 0).toDouble(),
      engagement: json['engagement']?['value'] ?? 0,
      engagementTrend: (json['engagement']?['trend'] ?? 0).toDouble(),
      pageViews: json['page_views']?['value'] ?? 0,
      pageViewsTrend: (json['page_views']?['trend'] ?? 0).toDouble(),
      newFollowers: json['new_followers']?['value'] ?? 0,
      newFollowersTrend: (json['new_followers']?['trend'] ?? 0).toDouble(),
      postsPublished: json['posts_published'] ?? 0,
      messagesReceived: json['messages_received'] ?? 0,
    );
  }
}

class DailyInsight {
  final String date;
  final int reach;
  final int impressions;
  final int engagement;
  final int clicks;
  final int pageViews;
  final int followersGained;
  final int followersTotal;
  final int postsPublished;
  final int messagesReceived;

  DailyInsight({
    required this.date,
    required this.reach,
    required this.impressions,
    required this.engagement,
    required this.clicks,
    required this.pageViews,
    required this.followersGained,
    required this.followersTotal,
    required this.postsPublished,
    required this.messagesReceived,
  });

  factory DailyInsight.fromJson(Map<String, dynamic> json) {
    return DailyInsight(
      date: json['date'] ?? '',
      reach: json['total_reach'] ?? 0,
      impressions: json['total_impressions'] ?? 0,
      engagement: json['total_engagement'] ?? 0,
      clicks: json['total_clicks'] ?? 0,
      pageViews: json['page_views'] ?? 0,
      followersGained: json['followers_gained'] ?? 0,
      followersTotal: json['followers_total'] ?? 0,
      postsPublished: json['posts_published'] ?? 0,
      messagesReceived: json['messages_received'] ?? 0,
    );
  }

  int valueFor(InsightsMetric metric) {
    switch (metric) {
      case InsightsMetric.reach:
        return reach;
      case InsightsMetric.impressions:
        return impressions;
      case InsightsMetric.engagement:
        return engagement;
      case InsightsMetric.pageViews:
        return pageViews;
    }
  }
}

enum InsightsMetric { reach, impressions, engagement, pageViews }

class InsightsData {
  final InsightsSummary summary;
  final List<DailyInsight> daily;
  final String from;
  final String to;

  InsightsData({
    required this.summary,
    required this.daily,
    required this.from,
    required this.to,
  });

  factory InsightsData.fromJson(Map<String, dynamic> json) {
    return InsightsData(
      summary: InsightsSummary.fromJson(json['summary'] ?? {}),
      daily: (json['daily'] as List? ?? [])
          .map((e) => DailyInsight.fromJson(e))
          .toList(),
      from: json['from'] ?? '',
      to: json['to'] ?? '',
    );
  }
}

// ── Audience ────────────────────────────────────────

class AgeGenderEntry {
  final String ageRange;
  final String gender;
  final int count;

  AgeGenderEntry({
    required this.ageRange,
    required this.gender,
    required this.count,
  });

  factory AgeGenderEntry.fromJson(Map<String, dynamic> json) {
    return AgeGenderEntry(
      ageRange: json['age_range'] ?? json['range'] ?? '',
      gender: json['gender'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}

class CountryEntry {
  final String country;
  final int count;

  CountryEntry({required this.country, required this.count});

  factory CountryEntry.fromJson(Map<String, dynamic> json) {
    return CountryEntry(
      country: json['country'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}

class CityEntry {
  final String city;
  final int count;

  CityEntry({required this.city, required this.count});

  factory CityEntry.fromJson(Map<String, dynamic> json) {
    return CityEntry(
      city: json['city'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}

class AudienceData {
  final int totalFollowers;
  final List<AgeGenderEntry> ageGender;
  final List<CountryEntry> topCountries;
  final List<CityEntry> topCities;

  AudienceData({
    required this.totalFollowers,
    required this.ageGender,
    required this.topCountries,
    required this.topCities,
  });

  factory AudienceData.fromJson(Map<String, dynamic> json) {
    final demographics = json['demographics'] ?? {};
    return AudienceData(
      totalFollowers: json['total_followers'] ?? 0,
      ageGender: (demographics['age_gender'] as List? ?? [])
          .map((e) => AgeGenderEntry.fromJson(e))
          .toList(),
      topCountries: (demographics['top_countries'] as List? ?? [])
          .map((e) => CountryEntry.fromJson(e))
          .toList(),
      topCities: (demographics['top_cities'] as List? ?? [])
          .map((e) => CityEntry.fromJson(e))
          .toList(),
    );
  }

  /// Aggregate gender totals from age_gender entries.
  Map<String, int> get genderBreakdown {
    final result = <String, int>{};
    for (final entry in ageGender) {
      result[entry.gender] = (result[entry.gender] ?? 0) + entry.count;
    }
    return result;
  }

  /// Aggregate age totals from age_gender entries.
  Map<String, int> get ageBreakdown {
    final result = <String, int>{};
    for (final entry in ageGender) {
      result[entry.ageRange] = (result[entry.ageRange] ?? 0) + entry.count;
    }
    return result;
  }
}

// ── Content Performance ─────────────────────────────

class ContentPerformanceItem {
  final String postId;
  final String? thumbnail;
  final bool isVideoThumbnail;
  final String description;
  final int reach;
  final int engagement;
  final int clicks;

  ContentPerformanceItem({
    required this.postId,
    required this.thumbnail,
    this.isVideoThumbnail = false,
    required this.description,
    required this.reach,
    required this.engagement,
    required this.clicks,
  });

  String get thumbnailUrl {
    if (thumbnail == null || thumbnail!.isEmpty) return '';
    if (isVideoThumbnail) return ApiConstants.videoThumbnailUrl(thumbnail);
    return ApiConstants.postMediaUrl(thumbnail);
  }

  factory ContentPerformanceItem.fromJson(Map<String, dynamic> json) {
    final videoThumb = json['media']?[0]?['video_thumbnail'];
    final hasVideoThumb = videoThumb != null && videoThumb.toString().isNotEmpty;
    return ContentPerformanceItem(
      postId: json['_id'] ?? json['id'] ?? '',
      thumbnail: json['thumbnail'] ??
          videoThumb ??
          json['media']?[0]?['url'],
      isVideoThumbnail: hasVideoThumb && json['thumbnail'] == null,
      description: json['description'] ?? '',
      reach: json['reach'] ?? 0,
      engagement: json['engagement'] ?? 0,
      clicks: json['clicks'] ?? 0,
    );
  }
}

// ── Post-Level Insights ─────────────────────────────

class PostInsightsTimeline {
  final String date;
  final int impressions;
  final int engagements;
  final int clicks;

  PostInsightsTimeline({
    required this.date,
    required this.impressions,
    required this.engagements,
    required this.clicks,
  });

  factory PostInsightsTimeline.fromJson(Map<String, dynamic> json) {
    return PostInsightsTimeline(
      date: json['date'] ?? '',
      impressions: json['impressions'] ?? 0,
      engagements: json['engagements'] ?? 0,
      clicks: json['clicks'] ?? 0,
    );
  }
}

class PostInsightsData {
  final String? postId;
  final String? createdAt;

  // Overview
  final int viewCount;
  final int impressions;
  final int uniqueViewers;
  final int clicks;
  final double ctr;
  final int engagements;
  final double engagementRate;
  final int shares;
  final int saves;
  final int reactions;
  final int commentsCount;
  final int postShares;
  final int avgDwellTimeMs;
  final int avgVideoWatchPct;

  // Timeline
  final List<PostInsightsTimeline> timeline;

  // Demographics
  final Map<String, int> gender; // male, female, other
  final List<Map<String, dynamic>> ageGroups;

  // Locations
  final List<Map<String, dynamic>> topCountries;
  final List<Map<String, dynamic>> topCities;

  // Sources
  final List<Map<String, dynamic>> sources;

  PostInsightsData({
    this.postId,
    this.createdAt,
    required this.viewCount,
    required this.impressions,
    required this.uniqueViewers,
    required this.clicks,
    required this.ctr,
    required this.engagements,
    required this.engagementRate,
    required this.shares,
    required this.saves,
    required this.reactions,
    required this.commentsCount,
    required this.postShares,
    required this.avgDwellTimeMs,
    required this.avgVideoWatchPct,
    required this.timeline,
    required this.gender,
    required this.ageGroups,
    required this.topCountries,
    required this.topCities,
    required this.sources,
  });

  /// Total interactions = reactions + comments + shares + saves
  int get totalInteractions => reactions + commentsCount + postShares + saves;

  factory PostInsightsData.fromJson(Map<String, dynamic> json) {
    final overview = json['overview'] ?? {};
    final demographics = json['demographics'] ?? {};
    final locations = json['locations'] ?? {};
    final genderRaw = demographics['gender'] as Map<String, dynamic>? ?? {};
    final ageGroupsRaw = demographics['age_groups'] as List? ?? [];
    final countriesRaw = locations['top_countries'] as List? ?? [];
    final citiesRaw = locations['top_cities'] as List? ?? [];
    final sourcesRaw = json['sources'] as List? ?? [];
    final timelineRaw = json['timeline'] as List? ?? [];

    return PostInsightsData(
      postId: json['post_id'],
      createdAt: json['created_at'],
      viewCount: overview['view_count'] ?? 0,
      impressions: overview['impressions'] ?? 0,
      uniqueViewers: overview['unique_viewers'] ?? 0,
      clicks: overview['clicks'] ?? 0,
      ctr: (overview['ctr'] ?? 0).toDouble(),
      engagements: overview['engagements'] ?? 0,
      engagementRate: (overview['engagement_rate'] ?? 0).toDouble(),
      shares: overview['shares'] ?? 0,
      saves: overview['saves'] ?? 0,
      reactions: overview['reactions'] ?? 0,
      commentsCount: overview['comments'] ?? 0,
      postShares: overview['post_shares'] ?? 0,
      avgDwellTimeMs: overview['avg_dwell_time_ms'] ?? 0,
      avgVideoWatchPct: overview['avg_video_watch_pct'] ?? 0,
      timeline: timelineRaw
          .map((e) => PostInsightsTimeline.fromJson(e as Map<String, dynamic>))
          .toList(),
      gender: genderRaw.map((k, v) => MapEntry(k, (v as num).toInt())),
      ageGroups: ageGroupsRaw
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      topCountries: countriesRaw
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      topCities: citiesRaw
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      sources: sourcesRaw
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
    );
  }
}
