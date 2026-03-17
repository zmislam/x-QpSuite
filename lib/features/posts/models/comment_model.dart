import 'user_id_model.dart';

// ─────────────────────────────────────────────
// COMMENT MODEL
// ─────────────────────────────────────────────

class CommentModel {
  String? id;
  String? comment_name;
  String? post_id;
  String? post_single_item_id;
  UserIdModel? user_id;
  String? comment_type;
  bool? comment_edited;
  String? image_or_video;
  String? link;
  String? status;
  String? createdAt;
  String? updatedAt;
  List<CommentReaction>? comment_reactions;
  List<CommentReply>? replies;
  List<CommentFiles>? comment_files;
  int? v;
  String? key;

  CommentModel({
    this.id,
    this.comment_name,
    this.post_id,
    this.post_single_item_id,
    this.user_id,
    this.comment_type,
    this.comment_edited,
    this.image_or_video,
    this.link,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.comment_reactions,
    this.replies,
    this.comment_files,
    this.v,
    this.key,
  });

  CommentModel copyWith({
    String? id,
    String? comment_name,
    String? post_id,
    UserIdModel? user_id,
    List<CommentReaction>? comment_reactions,
    List<CommentReply>? replies,
    List<CommentFiles>? comment_files,
    String? key,
  }) {
    return CommentModel(
      id: id ?? this.id,
      comment_name: comment_name ?? this.comment_name,
      post_id: post_id ?? this.post_id,
      post_single_item_id: post_single_item_id,
      user_id: user_id ?? this.user_id,
      comment_type: comment_type,
      comment_edited: comment_edited,
      image_or_video: image_or_video,
      link: link,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      comment_reactions: comment_reactions ?? this.comment_reactions,
      replies: replies ?? this.replies,
      comment_files: comment_files ?? this.comment_files,
      v: v,
      key: key ?? this.key,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'comment_name': comment_name,
      'post_id': post_id,
      'post_single_item_id': post_single_item_id,
      'user_id': user_id?.toMap(),
      'comment_type': comment_type,
      'comment_edited': comment_edited,
      'image_or_video': image_or_video,
      'link': link,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'comment_reactions': comment_reactions?.map((e) => e.toMap()).toList(),
      'replies': replies?.map((e) => e.toMap()).toList(),
      'comment_files': comment_files?.map((e) => e.toMap()).toList(),
      '__v': v,
      'key': key,
    };
  }

  factory CommentModel.fromMap(Map<String, dynamic> map) {
    return CommentModel(
      id: map['_id'],
      comment_name: map['comment_name'],
      post_id: map['post_id'],
      post_single_item_id: map['post_single_item_id'],
      user_id: map['user_id'] is Map<String, dynamic>
          ? UserIdModel.fromMap(map['user_id'])
          : null,
      comment_type: map['comment_type'],
      comment_edited: map['comment_edited'],
      image_or_video: map['image_or_video'],
      link: map['link'],
      status: map['status'],
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
      comment_reactions: map['comment_reactions'] != null
          ? List<CommentReaction>.from(
              map['comment_reactions'].map((x) => CommentReaction.fromMap(x)))
          : null,
      replies: map['replies'] != null
          ? List<CommentReply>.from(
              map['replies'].map((x) => CommentReply.fromMap(x)))
          : null,
      comment_files: map['comment_files'] != null
          ? List<CommentFiles>.from(
              map['comment_files'].map((x) => CommentFiles.fromMap(x)))
          : null,
      v: map['__v'],
      key: map['key'],
    );
  }
}

// ─────────────────────────────────────────────
// COMMENT REACTION
// ─────────────────────────────────────────────

class CommentReaction {
  String? id;
  String? post_id;
  String? user_id;
  String? comment_id;
  String? comment_replies_id;
  String? reaction_type;
  int? v;
  String? key;

  CommentReaction({
    this.id,
    this.post_id,
    this.user_id,
    this.comment_id,
    this.comment_replies_id,
    this.reaction_type,
    this.v,
    this.key,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'post_id': post_id,
      'user_id': user_id,
      'comment_id': comment_id,
      'comment_replies_id': comment_replies_id,
      'reaction_type': reaction_type,
      'v': v,
      'key': key,
    };
  }

  factory CommentReaction.fromMap(Map<String, dynamic> map) {
    return CommentReaction(
      id: map['id'],
      post_id: map['post_id'],
      user_id: map['user_id'],
      comment_id: map['comment_id'],
      comment_replies_id: map['comment_replies_id'],
      reaction_type: map['reaction_type'],
      v: map['v'],
      key: map['key'],
    );
  }
}

// ─────────────────────────────────────────────
// COMMENT REPLY
// ─────────────────────────────────────────────

class CommentReply {
  String? id;
  String? comment_id;
  UserIdModel? replies_user_id;
  String? post_id;
  String? replies_comment_name;
  String? comment_type;
  bool? comment_edited;
  String? image_or_video;
  String? status;
  String? createdAt;
  String? updatedAt;
  List<CommentReaction>? replies_comment_reactions;
  int? v;
  String? key;

  CommentReply({
    this.id,
    this.comment_id,
    this.replies_user_id,
    this.post_id,
    this.replies_comment_name,
    this.comment_type,
    this.comment_edited,
    this.image_or_video,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.replies_comment_reactions,
    this.v,
    this.key,
  });

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'comment_id': comment_id,
      'replies_user_id': replies_user_id?.toMap(),
      'post_id': post_id,
      'replies_comment_name': replies_comment_name,
      'comment_type': comment_type,
      'comment_edited': comment_edited,
      'image_or_video': image_or_video,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'replies_comment_reactions':
          replies_comment_reactions?.map((e) => e.toMap()).toList(),
      'v': v,
      'key': key,
    };
  }

  factory CommentReply.fromMap(Map<String, dynamic> map) {
    return CommentReply(
      id: map['_id'],
      comment_id: map['comment_id'],
      replies_user_id: map['replies_user_id'] != null
          ? UserIdModel.fromMap(map['replies_user_id'])
          : null,
      post_id: map['post_id'],
      replies_comment_name: map['replies_comment_name'],
      comment_type: map['comment_type'],
      comment_edited: map['comment_edited'],
      image_or_video: map['image_or_video'],
      status: map['status'],
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
      replies_comment_reactions: map['replies_comment_reactions'] != null
          ? List<CommentReaction>.from(map['replies_comment_reactions']
              .map((x) => CommentReaction.fromMap(x)))
          : null,
      v: map['v'],
      key: map['key'],
    );
  }
}

// ─────────────────────────────────────────────
// COMMENT FILES
// ─────────────────────────────────────────────

class CommentFiles {
  String? id;
  String? file;
  String? key;

  CommentFiles({this.id, this.file, this.key});

  Map<String, dynamic> toMap() {
    return {'_id': id, 'file': file, 'key': key};
  }

  factory CommentFiles.fromMap(Map<String, dynamic> map) {
    return CommentFiles(
      id: map['_id'],
      file: map['file'],
      key: map['key'],
    );
  }
}
