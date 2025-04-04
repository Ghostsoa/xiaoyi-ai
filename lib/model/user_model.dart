class UserModel {
  final int id;
  final String email;
  final String username;
  final String? avatar;
  final int gender;
  final int role;
  final int status;
  final String token;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    this.avatar,
    required this.gender,
    required this.role,
    required this.status,
    required this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final userData = json['user'] as Map<String, dynamic>;
    return UserModel(
      id: userData['id'] as int,
      email: userData['email'] as String,
      username: userData['username'] as String,
      avatar: userData['avatar'] as String?,
      gender: userData['gender'] as int,
      role: userData['role'] as int,
      status: userData['status'] as int,
      token: json['token'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': {
        'id': id,
        'email': email,
        'username': username,
        'avatar': avatar,
        'gender': gender,
        'role': role,
        'status': status,
      },
      'token': token,
    };
  }

  UserModel copyWith({
    int? id,
    String? email,
    String? username,
    String? avatar,
    int? gender,
    int? role,
    int? status,
    String? token,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      avatar: avatar ?? this.avatar,
      gender: gender ?? this.gender,
      role: role ?? this.role,
      status: status ?? this.status,
      token: token ?? this.token,
    );
  }

  /// 获取头像URL
  String get avatarUrl => avatar ?? '';

  /// 获取显示用的头像URL（如果没有头像则返回空字符串）
  String get displayAvatarUrl => avatarUrl;

  /// 是否有头像
  bool get hasAvatar => avatar != null && avatar!.isNotEmpty;
}
