class UserModel {
  final String id;
  final String email;
  final String username;
  final String fullName;
  final String? avatar;
  final String bio;
  final int xp;
  final int level;
  final int xpToNextLevel;
  final int streakCount;
  final int longestStreak;
  final int studyGoalMinutes;
  final List<String> preferredSubjects;
  final bool isEmailVerified;
  final bool notificationEnabled;
  final String? dateJoined;

  const UserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.fullName,
    this.avatar,
    this.bio = '',
    this.xp = 0,
    this.level = 1,
    this.xpToNextLevel = 100,
    this.streakCount = 0,
    this.longestStreak = 0,
    this.studyGoalMinutes = 30,
    this.preferredSubjects = const [],
    this.isEmailVerified = false,
    this.notificationEnabled = true,
    this.dateJoined,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        email: json['email'] as String,
        username: json['username'] as String? ?? '',
        fullName: json['full_name'] as String? ?? '',
        avatar: json['avatar'] as String?,
        bio: json['bio'] as String? ?? '',
        xp: json['xp'] as int? ?? 0,
        level: json['level'] as int? ?? 1,
        xpToNextLevel: json['xp_to_next_level'] as int? ?? 100,
        streakCount: json['streak_count'] as int? ?? 0,
        longestStreak: json['longest_streak'] as int? ?? 0,
        studyGoalMinutes: json['study_goal_minutes'] as int? ?? 30,
        preferredSubjects: (json['preferred_subjects'] as List?)?.cast<String>() ?? [],
        isEmailVerified: json['is_email_verified'] as bool? ?? false,
        notificationEnabled: json['notification_enabled'] as bool? ?? true,
        dateJoined: json['date_joined'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'username': username,
        'full_name': fullName,
        'avatar': avatar,
        'bio': bio,
        'xp': xp,
        'level': level,
        'xp_to_next_level': xpToNextLevel,
        'streak_count': streakCount,
        'longest_streak': longestStreak,
        'study_goal_minutes': studyGoalMinutes,
        'preferred_subjects': preferredSubjects,
        'is_email_verified': isEmailVerified,
        'notification_enabled': notificationEnabled,
        'date_joined': dateJoined,
      };

  String get displayName => fullName.isNotEmpty ? fullName : username;

  UserModel copyWith({
    String? fullName,
    String? username,
    String? avatar,
    String? bio,
    int? xp,
    int? level,
    int? streakCount,
    int? studyGoalMinutes,
    List<String>? preferredSubjects,
    bool? notificationEnabled,
  }) =>
      UserModel(
        id: id,
        email: email,
        username: username ?? this.username,
        fullName: fullName ?? this.fullName,
        avatar: avatar ?? this.avatar,
        bio: bio ?? this.bio,
        xp: xp ?? this.xp,
        level: level ?? this.level,
        xpToNextLevel: xpToNextLevel,
        streakCount: streakCount ?? this.streakCount,
        longestStreak: longestStreak,
        studyGoalMinutes: studyGoalMinutes ?? this.studyGoalMinutes,
        preferredSubjects: preferredSubjects ?? this.preferredSubjects,
        isEmailVerified: isEmailVerified,
        notificationEnabled: notificationEnabled ?? this.notificationEnabled,
        dateJoined: dateJoined,
      );
}
