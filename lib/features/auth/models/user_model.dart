class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String? username;
  final String? email;
  final String? profilePic;
  final String? coverPic;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.username,
    this.email,
    this.profilePic,
    this.coverPic,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      firstName: json['first_name'] ?? json['firstName'] ?? '',
      lastName: json['last_name'] ?? json['lastName'] ?? '',
      username: json['username'] as String?,
      email: json['email'] as String?,
      profilePic: json['profile_pic'] ?? json['profile_picture'] as String?,
      coverPic: json['cover_pic'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'first_name': firstName,
        'last_name': lastName,
        'username': username,
        'email': email,
        'profile_pic': profilePic,
        'cover_pic': coverPic,
      };
}
