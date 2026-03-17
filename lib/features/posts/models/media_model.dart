import 'dart:convert';

class MediaModel {
  String? id;
  String? caption;
  String? media;
  String? videoThumbnail;
  String? post_id;
  String? status;
  String? createdAt;
  String? updatedAt;

  MediaModel({
    this.id,
    this.caption,
    this.media,
    this.videoThumbnail,
    this.post_id,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  /// Whether this media is a video file.
  bool get isVideo {
    if (media == null) return false;
    final ext = media!.split('.').last.toLowerCase();
    return ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(ext);
  }

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'caption': caption,
      'media': media,
      'video_thumbnail': videoThumbnail,
      'post_id': post_id,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory MediaModel.fromMap(Map<String, dynamic> map) {
    return MediaModel(
      id: map['_id'] as String?,
      caption: map['caption'] as String?,
      media: map['media'] as String?,
      videoThumbnail: map['video_thumbnail'] as String?,
      post_id: map['post_id'] as String?,
      status: map['status'] as String?,
      createdAt: map['createdAt'] as String?,
      updatedAt: map['updatedAt'] as String?,
    );
  }

  String toJson() => json.encode(toMap());
}
