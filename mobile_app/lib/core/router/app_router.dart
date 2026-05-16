import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/notes/presentation/screens/notes_list_screen.dart';
import '../../features/notes/presentation/screens/note_detail_screen.dart';
import '../../features/notes/presentation/screens/generate_note_screen.dart';
import '../../features/flashcards/presentation/screens/flashcard_decks_screen.dart';
import '../../features/flashcards/presentation/screens/flashcard_study_screen.dart';
import '../../features/quiz/presentation/screens/quiz_list_screen.dart';
import '../../features/quiz/presentation/screens/quiz_screen.dart';
import '../../features/quiz/presentation/screens/quiz_result_screen.dart';
import '../../features/ai_tutor/presentation/screens/ai_tutor_screen.dart';
import '../../features/gamification/presentation/screens/leaderboard_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../shared/providers/auth_provider.dart';
import '../shell/main_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggedIn = authState.isLoggedIn;
      final isOnboarded = authState.isOnboarded;
      final path = state.uri.path;

      final authRoutes = ['/login', '/register', '/forgot-password', '/onboarding'];
      final isAuthRoute = authRoutes.any((r) => path.startsWith(r));

      if (path == '/splash') return null;

      if (!isOnboarded) {
        return isAuthRoute ? null : '/onboarding';
      }

      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }

      if (isLoggedIn && isAuthRoute) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (ctx, _) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (ctx, _) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (ctx, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (ctx, _) => const RegisterScreen()),
      GoRoute(path: '/forgot-password', builder: (ctx, _) => const ForgotPasswordScreen()),

      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/dashboard', builder: (ctx, _) => const DashboardScreen()),
          GoRoute(
            path: '/notes',
            builder: (ctx, _) => const NotesListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (ctx, state) => NoteDetailScreen(noteId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(path: '/generate', builder: (ctx, _) => const GenerateNoteScreen()),
          GoRoute(
            path: '/flashcards',
            builder: (ctx, _) => const FlashcardDecksScreen(),
            routes: [
              GoRoute(
                path: ':id/study',
                builder: (ctx, state) => FlashcardStudyScreen(deckId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/quizzes',
            builder: (ctx, _) => const QuizListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (ctx, state) => QuizScreen(quizId: state.pathParameters['id']!),
              ),
              GoRoute(
                path: ':id/result',
                builder: (ctx, state) => QuizResultScreen(
                  quizId: state.pathParameters['id']!,
                  attemptData: state.extra as Map<String, dynamic>? ?? {},
                ),
              ),
            ],
          ),
          GoRoute(path: '/ai-tutor', builder: (ctx, _) => const AiTutorScreen()),
          GoRoute(path: '/leaderboard', builder: (ctx, _) => const LeaderboardScreen()),
          GoRoute(path: '/profile', builder: (ctx, _) => const ProfileScreen()),
        ],
      ),
    ],
  );
});
