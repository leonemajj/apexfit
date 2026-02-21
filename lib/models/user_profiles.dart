class UserProfile {
  final String id;
  final String? email;
  final String? username;
  final int? targetCalories;
  final double? targetWeight;
  final int? height;
  final String? gender;
  final String? avatarUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserProfile({
    required this.id,
    this.email,
    this.username,
    this.targetCalories,
    this.targetWeight,
    this.height,
    this.gender,
    this.avatarUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String?,
      username: json['username'] as String?,
      targetCalories: json['target_calories'] as int?,
      targetWeight: (json['target_weight'] as num?)?.toDouble(),
      height: json['height'] as int?,
      gender: json['gender'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  UserProfile copyWith({
    String? username,
    int? targetCalories,
    double? targetWeight,
    int? height,
    String? gender,
    String? avatarUrl,
  }) {
    return UserProfile(
      id: id,
      email: email,
      username: username ?? this.username,
      targetCalories: targetCalories ?? this.targetCalories,
      targetWeight: targetWeight ?? this.targetWeight,
      height: height ?? this.height,
      gender: gender ?? this.gender,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
