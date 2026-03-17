import 'dart:convert';

import 'user_id_model.dart';

class ReactionModel {
  String? id;
  String? reaction_type;
  UserIdModel? user_id;
  String? post_id;
  String? post_single_item_id;
  String? status;
  String? createdAt;
  String? updatedAt;
  int? v;

  ReactionModel({
    this.id,
    this.reaction_type,
    this.user_id,
    this.post_id,
    this.post_single_item_id,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'reaction_type': reaction_type,
      'user_id': user_id?.toMap(),
      'post_id': post_id,
      'post_single_item_id': post_single_item_id,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      '__v': v,
    };
  }

  factory ReactionModel.fromMap(Map<String, dynamic> map) {
    return ReactionModel(
      id: map['_id'] as String?,
      reaction_type: map['reaction_type'] as String?,
      user_id: map['user_id'] != null
          ? (map['user_id'] is Map<String, dynamic>
              ? UserIdModel.fromMap(map['user_id'])
              : null)
          : null,
      post_id: map['post_id'] as String?,
      post_single_item_id: map['post_single_item_id'] as String?,
      status: map['status'] as String?,
      createdAt: map['createdAt'] as String?,
      updatedAt: map['updatedAt'] as String?,
      v: map['__v'] as int?,
    );
  }

  String toJson() => json.encode(toMap());

  factory ReactionModel.fromJson(String source) =>
      ReactionModel.fromMap(json.decode(source) as Map<String, dynamic>);
}

/// Lightweight reaction count model used in reactionTypeCountsByPost
class ReactionCountModel {
  int? count;
  String? post_id;
  String? reaction_type;
  String? user_id;

  ReactionCountModel({
    this.count,
    this.post_id,
    this.reaction_type,
    this.user_id,
  });

  factory ReactionCountModel.fromMap(Map<String, dynamic> map) {
    return ReactionCountModel(
      count: map['count'] as int?,
      post_id: map['post_id'] as String?,
      reaction_type: map['reaction_type'] as String?,
      user_id: map['user_id'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'count': count,
      'post_id': post_id,
      'reaction_type': reaction_type,
      'user_id': user_id,
    };
  }
}
