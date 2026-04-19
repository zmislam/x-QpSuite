class DashboardKpi {
  final num value;
  final num change;
  final double changePct;

  const DashboardKpi({
    required this.value,
    required this.change,
    required this.changePct,
  });

  factory DashboardKpi.fromJson(Map<String, dynamic> json) {
    return DashboardKpi(
      value: json['value'] ?? 0,
      change: json['change'] ?? 0,
      changePct: (json['change_pct'] ?? 0).toDouble(),
    );
  }

  static DashboardKpi zero() => const DashboardKpi(value: 0, change: 0, changePct: 0);
}

/// Page info returned inside the dashboard response.
class DashboardPageInfo {
  final String id;
  final String pageName;
  final String? profilePic;
  final String? coverPic;
  final String? category;

  DashboardPageInfo({
    required this.id,
    required this.pageName,
    this.profilePic,
    this.coverPic,
    this.category,
  });

  factory DashboardPageInfo.fromJson(Map<String, dynamic> json) {
    final cat = json['category'];
    return DashboardPageInfo(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      pageName: json['page_name'] ?? '',
      profilePic: json['profile_pic'] as String?,
      coverPic: json['cover_pic'] as String?,
      category: cat is List ? (cat).join(', ') : cat as String?,
    );
  }
}

class DashboardKpis {
  final DashboardKpi followers;
  final DashboardKpi reach;
  final DashboardKpi engagement;
  final DashboardKpi impressions;
  final DashboardKpi clicks;
  final DashboardKpi pageViews;
  final DashboardKpi messages;
  final DashboardKpi postsPublished;

  const DashboardKpis({
    required this.followers,
    required this.reach,
    required this.engagement,
    required this.impressions,
    required this.clicks,
    required this.pageViews,
    required this.messages,
    required this.postsPublished,
  });

  factory DashboardKpis.fromJson(Map<String, dynamic> json) {
    return DashboardKpis(
      followers: _kpi(json, 'followers'),
      reach: _kpi(json, 'reach'),
      engagement: _kpi(json, 'engagement'),
      impressions: _kpi(json, 'impressions'),
      clicks: _kpi(json, 'clicks'),
      pageViews: _kpi(json, 'page_views'),
      messages: _kpi(json, 'messages'),
      postsPublished: _kpi(json, 'posts_published'),
    );
  }

  static DashboardKpi _kpi(Map<String, dynamic> json, String key) {
    if (json[key] is Map<String, dynamic>) {
      return DashboardKpi.fromJson(json[key]);
    }
    return DashboardKpi.zero();
  }

  List<(String, DashboardKpi)> toList() => [
        ('Followers', followers),
        ('Reach', reach),
        ('Engagement', engagement),
        ('Impressions', impressions),
        ('Clicks', clicks),
        ('Page Views', pageViews),
        ('Messages', messages),
        ('Posts', postsPublished),
      ];
}

class TrendPoint {
  final DateTime date;
  final num totalReach;
  final num totalEngagement;
  final num totalImpressions;
  final num totalClicks;
  final num pageViews;
  final num followersGained;
  final num followersTotal;
  final num postsPublished;
  final num messagesReceived;

  TrendPoint({
    required this.date,
    required this.totalReach,
    required this.totalEngagement,
    required this.totalImpressions,
    required this.totalClicks,
    required this.pageViews,
    required this.followersGained,
    required this.followersTotal,
    required this.postsPublished,
    required this.messagesReceived,
  });

  factory TrendPoint.fromJson(Map<String, dynamic> json) {
    return TrendPoint(
      date: DateTime.parse(json['date']),
      totalReach: json['total_reach'] ?? 0,
      totalEngagement: json['total_engagement'] ?? 0,
      totalImpressions: json['total_impressions'] ?? 0,
      totalClicks: json['total_clicks'] ?? 0,
      pageViews: json['page_views'] ?? 0,
      followersGained: json['followers_gained'] ?? 0,
      followersTotal: json['followers_total'] ?? 0,
      postsPublished: json['posts_published'] ?? 0,
      messagesReceived: json['messages_received'] ?? 0,
    );
  }

  num valueFor(TrendMetric metric) => switch (metric) {
        TrendMetric.reach => totalReach,
        TrendMetric.engagement => totalEngagement,
        TrendMetric.impressions => totalImpressions,
        TrendMetric.followers => followersTotal,
      };
}

enum TrendMetric { reach, engagement, impressions, followers }

class TopPost {
  final String id;
  final String description;
  final String? image;
  final List<String> media;
  final int likes;
  final int comments;
  final int shares;
  final int engagement;
  final int views;
  final String type;
  final DateTime date;

  TopPost({
    required this.id,
    required this.description,
    this.image,
    this.media = const [],
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.engagement = 0,
    this.views = 0,
    this.type = 'text',
    required this.date,
  });

  factory TopPost.fromJson(Map<String, dynamic> json) {
    return TopPost(
      id: json['_id'] ?? '',
      description: json['description'] ?? '',
      image: json['image'],
      media: (json['media'] as List?)?.map((e) => e.toString()).toList() ?? [],
      likes: json['likes'] ?? 0,
      comments: json['comments'] ?? 0,
      shares: json['shares'] ?? 0,
      engagement: json['engagement'] ?? 0,
      views: json['views'] ?? 0,
      type: json['type'] ?? 'text',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
    );
  }
}

class RecentActivity {
  final String id;
  final String type; // reaction | comment | new_follower
  final String message;
  final DateTime createdAt;
  final String? postId;
  final String? userPic;

  RecentActivity({
    required this.id,
    required this.type,
    required this.message,
    required this.createdAt,
    this.postId,
    this.userPic,
  });

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      id: json['_id'] ?? '',
      type: json['type'] ?? '',
      message: json['message'] ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      postId: json['post_id'],
      userPic: json['user_pic'],
    );
  }
}

class OnboardingProgress {
  final bool connectedSocial;
  final bool createdPost;
  final bool repliedMessage;
  final bool grewAudience;
  final int completed;
  final int total;

  OnboardingProgress({
    this.connectedSocial = false,
    this.createdPost = false,
    this.repliedMessage = false,
    this.grewAudience = false,
    this.completed = 0,
    this.total = 4,
  });

  bool get isComplete => completed >= total;

  factory OnboardingProgress.fromJson(Map<String, dynamic> json) {
    final steps = json['steps'] as Map<String, dynamic>? ?? {};
    return OnboardingProgress(
      connectedSocial: steps['connected_social'] ?? false,
      createdPost: steps['created_post'] ?? false,
      repliedMessage: steps['replied_message'] ?? false,
      grewAudience: steps['grew_audience'] ?? false,
      completed: json['completed'] ?? 0,
      total: json['total'] ?? 4,
    );
  }
}

/// Demographics data returned from the dashboard endpoint.
class DemographicsData {
  final GenderBreakdown gender;
  final List<AgeGroup> ageGroups;
  final List<LocationEntry> topCountries;
  final List<LocationEntry> topCities;

  const DemographicsData({
    required this.gender,
    required this.ageGroups,
    required this.topCountries,
    required this.topCities,
  });

  factory DemographicsData.fromJson(Map<String, dynamic> json) {
    final genderJson = json['gender'] as Map<String, dynamic>? ?? {};
    return DemographicsData(
      gender: GenderBreakdown.fromJson(genderJson),
      ageGroups: (json['age_groups'] as List?)
              ?.map((e) => AgeGroup.fromJson(e))
              .toList() ??
          [],
      topCountries: (json['top_countries'] as List?)
              ?.map((e) => LocationEntry.fromJson(e))
              .toList() ??
          [],
      topCities: (json['top_cities'] as List?)
              ?.map((e) => LocationEntry.fromJson(e))
              .toList() ??
          [],
    );
  }

  static DemographicsData empty() => DemographicsData(
        gender: GenderBreakdown(male: 0, female: 0, other: 0),
        ageGroups: const [],
        topCountries: const [],
        topCities: const [],
      );

  bool get isEmpty =>
      gender.total == 0 &&
      ageGroups.isEmpty &&
      topCountries.isEmpty &&
      topCities.isEmpty;
}

class GenderBreakdown {
  final int male;
  final int female;
  final int other;

  const GenderBreakdown({
    required this.male,
    required this.female,
    required this.other,
  });

  int get total => male + female + other;

  factory GenderBreakdown.fromJson(Map<String, dynamic> json) {
    return GenderBreakdown(
      male: (json['male'] ?? 0) as int,
      female: (json['female'] ?? 0) as int,
      other: (json['other'] ?? 0) as int,
    );
  }
}

class AgeGroup {
  final String range;
  final int count;

  const AgeGroup({required this.range, required this.count});

  factory AgeGroup.fromJson(Map<String, dynamic> json) {
    return AgeGroup(
      range: json['range'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}

class LocationEntry {
  final String name;
  final int count;

  const LocationEntry({required this.name, required this.count});

  factory LocationEntry.fromJson(Map<String, dynamic> json) {
    // API returns either 'country' or 'city' key
    return LocationEntry(
      name: json['country'] ?? json['city'] ?? json['name'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}

class DashboardData {
  final DashboardPageInfo? pageInfo;
  final DashboardKpis kpis;
  final List<TrendPoint> trend;
  final DemographicsData demographics;
  final List<TopPost> topPosts;
  final List<RecentActivity> recentActivity;
  final List<TodoItem> todos;
  final OnboardingProgress onboarding;

  DashboardData({
    this.pageInfo,
    required this.kpis,
    required this.trend,
    required this.demographics,
    required this.topPosts,
    required this.recentActivity,
    required this.todos,
    required this.onboarding,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      pageInfo: json['page'] != null
          ? DashboardPageInfo.fromJson(json['page'])
          : null,
      kpis: DashboardKpis.fromJson(json['kpis'] ?? {}),
      trend: (json['insights_trend'] as List?)
              ?.map((e) => TrendPoint.fromJson(e))
              .toList() ??
          [],
      demographics: json['demographics'] != null
          ? DemographicsData.fromJson(json['demographics'])
          : DemographicsData.empty(),
      topPosts: (json['top_posts'] as List?)
              ?.map((e) => TopPost.fromJson(e))
              .toList() ??
          [],
      recentActivity: (json['recent_activity'] as List?)
              ?.map((e) => RecentActivity.fromJson(e))
              .toList() ??
          [],
      todos: (json['todos'] as List?)
              ?.map((e) => TodoItem.fromJson(e))
              .toList() ??
          [],
      onboarding:
          OnboardingProgress.fromJson(json['onboarding'] ?? {}),
    );
  }
}

/// A to-do item from the dashboard.
class TodoItem {
  final String id;
  final String type;
  final String title;
  final int count;

  TodoItem({
    required this.id,
    required this.type,
    required this.title,
    this.count = 0,
  });

  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}
