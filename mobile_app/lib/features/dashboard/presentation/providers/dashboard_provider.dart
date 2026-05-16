import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';

class DashboardStats {
  final int notesCreated;
  final int quizzesCompleted;
  final double avgQuizScore;
  final int flashcardsReviewed;
  final int studyMinutesWeek;
  final int goalMinutes;
  final int goalProgress;
  final List<Map<String, dynamic>> weakTopics;

  const DashboardStats({
    required this.notesCreated,
    required this.quizzesCompleted,
    required this.avgQuizScore,
    required this.flashcardsReviewed,
    required this.studyMinutesWeek,
    required this.goalMinutes,
    required this.goalProgress,
    required this.weakTopics,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      notesCreated: json['notes']?['total'] ?? 0,
      quizzesCompleted: json['quizzes']?['completed'] ?? 0,
      avgQuizScore: (json['quizzes']?['avg_score'] ?? 0).toDouble(),
      flashcardsReviewed: json['flashcards']?['reviewed_this_week'] ?? 0,
      studyMinutesWeek: json['study']?['minutes_this_week'] ?? 0,
      goalMinutes: json['study']?['goal_minutes'] ?? 30,
      goalProgress: json['study']?['goal_progress'] ?? 0,
      weakTopics: (json['weak_topics'] as List?)?.cast<Map<String, dynamic>>() ?? [],
    );
  }
}

class DashboardState {
  final bool isLoading;
  final String? error;
  final DashboardStats? stats;
  final List<Map<String, dynamic>> recentNotes;

  const DashboardState({
    this.isLoading = false,
    this.error,
    this.stats,
    this.recentNotes = const [],
  });

  DashboardState copyWith({
    bool? isLoading,
    String? error,
    DashboardStats? stats,
    List<Map<String, dynamic>>? recentNotes,
  }) =>
      DashboardState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        stats: stats ?? this.stats,
        recentNotes: recentNotes ?? this.recentNotes,
      );
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  DashboardNotifier() : super(const DashboardState());

  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiClient.instance.get('/analytics/dashboard/');
      final data = response.data['data'];
      final stats = DashboardStats.fromJson(data);
      final recentNotes = (data['notes']['recent'] as List).cast<Map<String, dynamic>>();
      state = state.copyWith(isLoading: false, stats: stats, recentNotes: recentNotes);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load dashboard');
    }
  }
}

final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>(
  (ref) => DashboardNotifier(),
);
