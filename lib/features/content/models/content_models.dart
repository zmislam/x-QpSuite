class ContentItem {
  final String id;
  final String source; // "published" | "scheduled"
  final String? description;
  final String? text;
  final String contentType; // Post | Reel | Story
  final List<ContentMedia> media;
  final DateTime createdAt;
  final DateTime? scheduledFor;
  final String? status; // Scheduled | Publishing | Published | Failed | Cancelled
  final String? failureReason;
  final String? timezone;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final int viewCount;
  final bool isBoosted;
  final String? authorName;
  final String? authorPic;

  ContentItem({
    required this.id,
    required this.source,
    this.description,
    this.text,
    this.contentType = 'Post',
    this.media = const [],
    required this.createdAt,
    this.scheduledFor,
    this.status,
    this.failureReason,
    this.timezone,
    this.likeCount = 0,
    this.commentCount = 0,
    this.shareCount = 0,
    this.viewCount = 0,
    this.isBoosted = false,
    this.authorName,
    this.authorPic,
  });

  bool get isPublished => source == 'published';
  bool get isScheduled => source == 'scheduled';
  bool get isFailed => status == 'Failed';
  String get displayText => description ?? text ?? '';

  factory ContentItem.fromJson(Map<String, dynamic> json) {
    // Determine source
    final source = json['_source'] ?? 'published';
    // Parse media
    List<ContentMedia> media = [];
    if (json['media'] is List) {
      media = (json['media'] as List)
          .map((e) => ContentMedia.fromJson(e))
          .toList();
    }
    // Author info
    String? authorName;
    String? authorPic;
    if (json['user_id'] is Map) {
      final u = json['user_id'] as Map<String, dynamic>;
      authorName = '${u['first_name'] ?? ''} ${u['last_name'] ?? ''}'.trim();
      authorPic = u['profile_pic'];
    }

    return ContentItem(
      id: json['_id'] ?? '',
      source: source,
      description: json['description'],
      text: json['text'],
      contentType: json['content_type'] ?? json['post_type'] ?? 'Post',
      media: media,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      scheduledFor: json['scheduled_for'] != null
          ? DateTime.tryParse(json['scheduled_for'])
          : null,
      status: json['status'],
      failureReason: json['failure_reason'],
      timezone: json['timezone'],
      likeCount: json['like_count'] ?? json['reactionCount'] ?? 0,
      commentCount: json['comment_count'] ?? json['totalComments'] ?? 0,
      shareCount: json['share_count'] ?? json['postShareCount'] ?? 0,
      viewCount: json['view_count'] ?? 0,
      isBoosted: json['is_boosted'] ?? false,
      authorName: authorName,
      authorPic: authorPic,
    );
  }
}

class ContentMedia {
  final String url;
  final String type; // image | video
  final String? thumbnailUrl;
  final String? mediaId;

  ContentMedia({
    required this.url,
    required this.type,
    this.thumbnailUrl,
    this.mediaId,
  });

  factory ContentMedia.fromJson(Map<String, dynamic> json) {
    return ContentMedia(
      url: json['url'] ?? json['media'] ?? '',
      type: json['type'] ?? 'image',
      thumbnailUrl: json['thumbnail_url'] ?? json['video_thumbnail'],
      mediaId: json['_id'] ?? json['post_id'],
    );
  }
}

class CalendarDay {
  final String date;
  final List<ContentItem> published;
  final List<ContentItem> scheduled;

  CalendarDay({
    required this.date,
    this.published = const [],
    this.scheduled = const [],
  });

  int get totalCount => published.length + scheduled.length;

  factory CalendarDay.fromJson(String date, Map<String, dynamic> json) {
    return CalendarDay(
      date: date,
      published: (json['published'] as List?)
              ?.map((e) => ContentItem.fromJson(e))
              .toList() ??
          [],
      scheduled: (json['scheduled'] as List?)
              ?.map((e) => ContentItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}
