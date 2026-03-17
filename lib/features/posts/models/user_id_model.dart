import 'dart:convert';

class UserIdModel {
  String? id;
  String? first_name;
  String? last_name;
  String? username;
  String? email;
  String? phone;
  String? profile_pic;
  String? cover_pic;
  String? user_status;
  String? gender;
  String? user_bio;
  String? page_id;
  bool? isProfileVerified;
  bool? isFollowing;
  int? v;

  UserIdModel({
    this.id,
    this.first_name,
    this.last_name,
    this.username,
    this.email,
    this.phone,
    this.profile_pic,
    this.cover_pic,
    this.user_status,
    this.gender,
    this.user_bio,
    this.page_id,
    this.isProfileVerified,
    this.isFollowing,
    this.v,
  });

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'first_name': first_name,
      'last_name': last_name ?? '',
      'username': username,
      'email': email,
      'phone': phone,
      'profile_pic': profile_pic,
      'cover_pic': cover_pic,
      'user_status': user_status,
      'gender': gender,
      'user_bio': user_bio,
      'page_id': page_id,
      'isProfileVerified': isProfileVerified,
      'isFollowing': isFollowing,
      '__v': v,
    };
  }

  factory UserIdModel.fromMap(Map<String, dynamic> map) {
    return UserIdModel(
      id: map['_id'] as String?,
      first_name: map['first_name'] as String?,
      last_name: map['last_name'] as String? ?? '',
      username: map['username'] as String?,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      profile_pic: map['profile_pic'] as String?,
      cover_pic: map['cover_pic'] as String?,
      user_status: map['user_status'] as String?,
      gender: map['gender'] as String?,
      user_bio: map['user_bio'] as String?,
      page_id: map['page_id'] as String?,
      isProfileVerified: map['isProfileVerified'] as bool?,
      isFollowing: map['isFollowing'] as bool?,
      v: map['__v'] as int?,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserIdModel.fromJson(String source) =>
      UserIdModel.fromMap(json.decode(source) as Map<String, dynamic>);

  String get fullName => '${first_name ?? ''} ${last_name ?? ''}'.trim();
}
