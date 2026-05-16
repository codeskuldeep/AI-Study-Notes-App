class AppConstants {
  AppConstants._();

  // Hive boxes
  static const String settingsBox = 'settings';
  static const String cacheBox = 'cache';
  static const String notesBox = 'notes';

  // Hive keys
  static const String themeKey = 'theme_mode';
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  static const String onboardingKey = 'onboarding_done';

  // API
  static const String baseUrl = 'https://ai-study-notes-app.onrender.com/api/v1';
  static const Duration connectTimeout = Duration(seconds: 60);
  static const Duration receiveTimeout = Duration(seconds: 60);

  // Pagination
  static const int defaultPageSize = 20;

  // UI
  static const double borderRadius = 16.0;
  static const double cardRadius = 20.0;
  static const double buttonRadius = 14.0;
  static const double pagePadding = 20.0;
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 600);

  // XP
  static const Map<String, int> xpRewards = {
    'note_generated': 10,
    'quiz_completed': 15,
    'flashcard_reviewed': 5,
    'daily_login': 5,
    'perfect_quiz': 25,
  };

  // Subjects
  static const List<String> subjects = [
    'Mathematics',
    'Physics',
    'Chemistry',
    'Biology',
    'Computer Science',
    'History',
    'Geography',
    'Economics',
    'Literature',
    'Languages',
    'Psychology',
    'Philosophy',
    'Other',
  ];
}
