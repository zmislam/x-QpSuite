/// Story styling metadata for text-only stories.
class StoryMeta {
  final String? color;
  final String? textColor;
  final String? fontFamily;
  final double? fontSize;
  final String? textAlignment;
  final String? bgImageId;

  StoryMeta({
    this.color,
    this.textColor,
    this.fontFamily,
    this.fontSize,
    this.textAlignment,
    this.bgImageId,
  });

  factory StoryMeta.fromJson(Map<String, dynamic> json) {
    return StoryMeta(
      color: json['color'],
      textColor: json['text_color'],
      fontFamily: json['font_family'],
      fontSize: (json['font_size'] as num?)?.toDouble(),
      textAlignment: json['text_alignment'],
      bgImageId: json['bg_image_id']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (color != null) 'color': color,
      if (textColor != null) 'text_color': textColor,
      if (fontFamily != null) 'font_family': fontFamily,
      if (fontSize != null) 'font_size': fontSize,
      if (textAlignment != null) 'text_alignment': textAlignment,
      if (bgImageId != null) 'bg_image_id': bgImageId,
    };
  }
}

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
  final StoryMeta? storyMeta;

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
    this.storyMeta,
  });

  bool get isPublished => source == 'published';
  bool get isScheduled => source == 'scheduled';
  bool get isFailed => status == 'Failed';
  bool get isCancelled => status == 'Cancelled';
  bool get isPublishing => status == 'Publishing';
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
    // Story meta
    StoryMeta? storyMeta;
    if (json['story_meta'] is Map) {
      storyMeta =
          StoryMeta.fromJson(json['story_meta'] as Map<String, dynamic>);
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
      storyMeta: storyMeta,
    );
  }
}

class ContentMedia {
  final String url;
  final String type; // image | video
  final String? thumbnailUrl;
  final String? mediaId;
  final String? mediaBaseDir; // e.g. 'reels', 'story', null for posts

  ContentMedia({
    required this.url,
    required this.type,
    this.thumbnailUrl,
    this.mediaId,
    this.mediaBaseDir,
  });

  bool get isVideo =>
      type == 'video' ||
      const ['mp4', 'mov', 'avi', 'mkv', 'webm']
          .any((ext) => url.toLowerCase().endsWith('.$ext'));

  factory ContentMedia.fromJson(Map<String, dynamic> json) {
    return ContentMedia(
      url: json['url'] ?? json['media'] ?? '',
      type: json['type'] ?? (json['mediaType'] ?? 'image'),
      thumbnailUrl: json['thumbnail_url'] ?? json['video_thumbnail'],
      mediaId: json['_id'] ?? json['post_id'],
      mediaBaseDir: json['_mediaBaseDir'],
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
