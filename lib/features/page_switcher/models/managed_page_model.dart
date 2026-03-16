import '../../../core/constants/api_constants.dart';

class ManagedPageModel {
  final String id;
  final String pageName;
  final String? profilePic;
  final String? category;
  final String role;
  final int followersCount;

  ManagedPageModel({
    required this.id,
    required this.pageName,
    this.profilePic,
    this.category,
    required this.role,
    required this.followersCount,
  });

  String get profilePicUrl => ApiConstants.mediaUrl(profilePic);

  factory ManagedPageModel.fromJson(Map<String, dynamic> json) {
    return ManagedPageModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      pageName: json['page_name'] ?? '',
      profilePic: json['profile_pic'] as String?,
      category: json['category'] as String?,
      role: json['role'] ?? 'owner',
      followersCount: json['followers_count'] ?? 0,
    );
  }
}
