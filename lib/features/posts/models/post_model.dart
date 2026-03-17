import 'dart:convert';

import 'comment_model.dart';
import 'media_model.dart';
import 'reaction_model.dart';
import 'user_id_model.dart';

// ─────────────────────────────────────────────
// PAGE ID (embedded in post)
// ─────────────────────────────────────────────

class PostPageId {
  String? id;
  String? pageName;
  String? bio;
  String? website;
  String? profilePic;
  String? coverPic;
  String? pageUserName;
  int? v;

  PostPageId({
    this.id,
    this.pageName,
    this.bio,
    this.website,
    this.profilePic,
    this.coverPic,
    this.pageUserName,
    this.v,
  });

  factory PostPageId.fromJson(Map<String, dynamic> json) => PostPageId(
        id: json['_id'],
        pageName: json['page_name'],
        bio: json['bio'],
        website: json['website'],
        profilePic: json['profile_pic'],
        coverPic: json['cover_pic'],
        pageUserName: json['page_user_name'],
        v: json['__v'],
      );

  factory PostPageId.empty() => PostPageId(
        id: '',
        pageName: '',
        bio: '',
        website: '',
        profilePic: '',
        coverPic: '',
        pageUserName: '',
        v: 0,
      );

  Map<String, dynamic> toJson() => {
        '_id': id,
        'page_name': pageName,
        'bio': bio,
        'website': website,
        'profile_pic': profilePic,
        'cover_pic': coverPic,
        'page_user_name': pageUserName,
        '__v': v,
      };
}

// ─────────────────────────────────────────────
// GROUP ID (embedded in post)
// ─────────────────────────────────────────────

class PostGroupId {
  String? id;
  String? groupName;
  String? groupPrivacy;
  String? groupCoverPic;

  PostGroupId({this.id, this.groupName, this.groupPrivacy, this.groupCoverPic});

  factory PostGroupId.fromJson(Map<String, dynamic> json) => PostGroupId(
        id: json['_id'],
        groupName: json['group_name'],
        groupPrivacy: json['group_privacy'],
        groupCoverPic: json['group_cover_pic'],
      );

  factory PostGroupId.empty() =>
      PostGroupId(id: '', groupName: '', groupPrivacy: '', groupCoverPic: '');

  Map<String, dynamic> toJson() => {
        '_id': id,
        'group_name': groupName,
        'group_privacy': groupPrivacy,
        'group_cover_pic': groupCoverPic,
      };
}

// ─────────────────────────────────────────────
// POST MODEL
// ─────────────────────────────────────────────

class PostModel {
  String? id;
  String? description;
  String? post_type;
  UserIdModel? user_id;
  PostGroupId groupId;
  String? post_privacy;
  PostPageId page_id;
  String? post_background_color;
  String? status;
  bool? is_hidden;
  bool? pinPost;
  bool? isBookMarked;
  String? createdAt;
  String? updatedAt;
  String? url;
  List<MediaModel>? media;
  String? layout_type;
  List<CommentModel>? comments;
  int? totalComments;
  int? reactionCount;
  int? postShareCount;
  int? view_count;
  List<ReactionCountModel>? reactionTypeCountsByPost;
  Map<String, dynamic>? reactionSummary;
  String? key;
  String? whyShown;
  int? dislikeCount;

  PostModel({
    this.id,
    this.description,
    this.post_type,
    this.user_id,
    PostGroupId? groupId,
    this.post_privacy,
    PostPageId? page_id,
    this.post_background_color,
    this.status,
    this.is_hidden,
    this.pinPost,
    this.isBookMarked,
    this.createdAt,
    this.updatedAt,
    this.url,
    this.media,
    this.layout_type,
    this.comments,
    this.totalComments,
    this.reactionCount,
    this.postShareCount,
    this.view_count,
    this.reactionTypeCountsByPost,
    this.reactionSummary,
    this.key,
    this.whyShown,
    this.dislikeCount,
  })  : groupId = groupId ?? PostGroupId.empty(),
        page_id = page_id ?? PostPageId.empty();

  factory PostModel.fromMap(Map<String, dynamic> map) {
    return PostModel(
      id: map['_id'],
      description: map['description'],
      post_type: map['post_type'],
      user_id:
          map['user_id'] != null && map['user_id'] is Map<String, dynamic>
              ? UserIdModel.fromMap(map['user_id'])
              : null,
      groupId: map['group_id'] != null
          ? PostGroupId.fromJson(map['group_id'])
          : PostGroupId.empty(),
      post_privacy: map['post_privacy'],
      page_id: map['page_id'] != null && map['page_id'] is Map<String, dynamic>
          ? PostPageId.fromJson(map['page_id'])
          : PostPageId.empty(),
      post_background_color: map['post_background_color'],
      status: map['status'],
      is_hidden: map['is_hidden'],
      pinPost: map['pin_post'],
      isBookMarked: map['isBookMarked'],
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
      url: map['url'],
      layout_type: map['layout_type'],
      media: map['media'] != null
          ? List<MediaModel>.from(
              map['media'].map((x) => MediaModel.fromMap(x)))
          : null,
      comments: map['comments'] != null
          ? List<CommentModel>.from(
              map['comments'].map((x) => CommentModel.fromMap(x)))
          : null,
      totalComments: map['totalComments'],
      reactionCount: map['reactionCount'],
      postShareCount: map['postShareCount'],
      view_count: map['view_count'],
      reactionTypeCountsByPost: map['reactionTypeCountsByPost'] != null
          ? List<ReactionCountModel>.from(map['reactionTypeCountsByPost']
              .map((x) => ReactionCountModel.fromMap(x)))
          : null,
      reactionSummary: map['reactionSummary'] != null
          ? Map<String, dynamic>.from(map['reactionSummary'])
          : null,
      key: map['key'],
      whyShown: map['_why_shown'],
      dislikeCount: map['dislikeCount'],
    );
  }

  factory PostModel.fromJson(String source) =>
      PostModel.fromMap(json.decode(source));
}
