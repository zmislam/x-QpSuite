import 'package:image_picker/image_picker.dart';
import '../../../features/posts/models/post_model.dart';
import '../../../features/posts/models/media_model.dart';

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

/// Local media descriptor for optimistic upload cards.
class PendingUploadMedia {
  final XFile file;
  final bool isVideo;

  const PendingUploadMedia({required this.file, required this.isVideo});

  String get path => file.path;
  String get name => file.name;
}

/// Optimistic content item shown while upload/schedule is processing.
class PendingContentUpload {
  final String id;
  final String pageId;
  final String contentType; // Post | Reel | Story
  final String postMode; // now | schedule
  final String text;
  final List<PendingUploadMedia> media;
  final DateTime createdAt;
  final DateTime? scheduledFor;
  final String status;
  final String? errorMessage;

  const PendingContentUpload({
    required this.id,
    required this.pageId,
    required this.contentType,
    required this.postMode,
    required this.text,
    this.media = const [],
    required this.createdAt,
    this.scheduledFor,
    this.status = 'Queued',
    this.errorMessage,
  });

  bool get isNow => postMode == 'now';
  bool get isSchedule => postMode == 'schedule';
  bool get isFailed => status == 'Failed';
  String get displayText => text;

  PendingContentUpload copyWith({String? status, String? errorMessage}) {
    return PendingContentUpload(
      id: id,
      pageId: pageId,
      contentType: contentType,
      postMode: postMode,
      text: text,
      media: media,
      createdAt: createdAt,
      scheduledFor: scheduledFor,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
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
  final String?
  status; // Scheduled | Publishing | Published | Failed | Cancelled
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
  bool get isStory => contentType == 'Story' || contentType == 'page_story';
  bool get isReel => contentType == 'Reel';
  String get displayText => description ?? text ?? '';

  /// Convert to PostModel for use with EditPostModal
  PostModel toPostModel() {
    return PostModel(
      id: id,
      description: description ?? text,
      post_type: contentType,
      createdAt: createdAt.toIso8601String(),
      media: media
          .map((m) => MediaModel(
                id: m.mediaId,
                media: m.url,
                videoThumbnail: m.thumbnailUrl,
              ))
          .toList(),
      reactionCount: likeCount,
      totalComments: commentCount,
      postShareCount: shareCount,
      view_count: viewCount,
    );
  }

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
    // Story meta — from story_meta object (scheduled) or _story* fields (published stories)
    StoryMeta? storyMeta;
    if (json['story_meta'] is Map) {
      storyMeta = StoryMeta.fromJson(
        json['story_meta'] as Map<String, dynamic>,
      );
    } else if (json['_storyColor'] != null || json['_storyBgImageId'] != null) {
      storyMeta = StoryMeta(
        color: json['_storyColor'],
        textColor: json['_storyTextColor'],
        fontFamily: json['_storyFontFamily'],
        fontSize: (json['_storyFontSize'] is num)
            ? (json['_storyFontSize'] as num).toDouble()
            : null,
        bgImageId: json['_storyBgImageId']?.toString(),
      );
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
      viewCount: json['view_count'] ?? json['viewCount'] ?? 0,
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
      const [
        'mp4',
        'mov',
        'avi',
        'mkv',
        'webm',
      ].any((ext) => url.toLowerCase().endsWith('.$ext'));

  factory ContentMedia.fromJson(Map<String, dynamic> json) {
    final rawType = (json['type'] ?? json['mediaType'] ?? 'image').toString();
    return ContentMedia(
      url: json['url'] ?? json['media'] ?? '',
      type: rawType.toLowerCase(),
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
      published:
          (json['published'] as List?)
              ?.map((e) => ContentItem.fromJson(e))
              .toList() ??
          [],
      scheduled:
          (json['scheduled'] as List?)
              ?.map((e) => ContentItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}
