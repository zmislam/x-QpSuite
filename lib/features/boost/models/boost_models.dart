class BoostedPost {
  final String id;
  final String? postDescription;
  final String? postThumbnail;
  final String status; // Draft | Paused | Active | Completed | Archived | Rejected
  final int dailyBudgetCents;
  final int durationDays;
  final int reach;
  final int impressions;
  final int clicks;
  final int spendCents;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime createdAt;

  BoostedPost({
    required this.id,
    this.postDescription,
    this.postThumbnail,
    required this.status,
    required this.dailyBudgetCents,
    required this.durationDays,
    required this.reach,
    required this.impressions,
    required this.clicks,
    required this.spendCents,
    this.startDate,
    this.endDate,
    required this.createdAt,
  });

  factory BoostedPost.fromJson(Map<String, dynamic> json) {
    return BoostedPost(
      id: json['_id'] ?? json['id'] ?? '',
      postDescription: json['post_description'] ?? json['name'],
      postThumbnail: json['post_thumbnail'],
      status: json['status'] ?? 'Draft',
      dailyBudgetCents: json['daily_budget_cents'] ?? 0,
      durationDays: json['duration_days'] ?? 0,
      reach: json['reach'] ?? json['metrics']?['reach'] ?? 0,
      impressions:
          json['impressions'] ?? json['metrics']?['impressions'] ?? 0,
      clicks: json['clicks'] ?? json['metrics']?['clicks'] ?? 0,
      spendCents:
          json['spend_cents'] ?? json['metrics']?['spend_cents'] ?? 0,
      startDate: DateTime.tryParse(json['start_date'] ?? ''),
      endDate: DateTime.tryParse(json['end_date'] ?? ''),
      createdAt:
          DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  String get formattedBudget =>
      '\$${(dailyBudgetCents / 100).toStringAsFixed(2)}/day';

  String get formattedSpend =>
      '\$${(spendCents / 100).toStringAsFixed(2)}';
}
