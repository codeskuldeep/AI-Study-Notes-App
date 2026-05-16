import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

class QuizResultScreen extends StatefulWidget {
  final String quizId;
  final Map<String, dynamic> attemptData;

  const QuizResultScreen({super.key, required this.quizId, required this.attemptData});

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
    final attempt = widget.attemptData['attempt'] as Map<String, dynamic>? ?? {};
    final percentage = (attempt['percentage'] as num?)?.toDouble() ?? 0;
    if (percentage >= 70) {
      _confetti.play();
    }
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final attempt = widget.attemptData['attempt'] as Map<String, dynamic>? ?? {};
    final percentage = (attempt['percentage'] as num?)?.toDouble() ?? 0;
    final score = attempt['score'] as int? ?? 0;
    final maxScore = attempt['max_score'] as int? ?? 0;
    final timeTaken = attempt['time_taken'] as int? ?? 0;
    final isPassed = percentage >= 60;

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _ScoreCircle(percentage: percentage, isPassed: isPassed)
                      .animate()
                      .scale(duration: 700.ms, curve: Curves.elasticOut),
                  const SizedBox(height: 24),
                  Text(
                    isPassed ? '🎉 Great job!' : 'Keep practicing!',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ).animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: 8),
                  Text(
                    isPassed
                        ? 'You passed this quiz!'
                        : 'You can do better. Review and try again.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 400.ms),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      _StatCard(label: 'Score', value: '$score/$maxScore', icon: Icons.score_rounded, color: AppColors.primary),
                      const SizedBox(width: 12),
                      _StatCard(
                        label: 'Time',
                        value: '${(timeTaken ~/ 60).toString().padLeft(2, '0')}:${(timeTaken % 60).toString().padLeft(2, '0')}',
                        icon: Icons.timer_rounded,
                        color: AppColors.secondary,
                      ),
                    ],
                  ).animate().slideY(begin: 0.2, duration: 400.ms, delay: 500.ms).fadeIn(),
                  const SizedBox(height: 32),
                  if (widget.attemptData['graded_answers'] != null)
                    _AnswerReview(gradedAnswers: widget.attemptData['graded_answers'] as Map<String, dynamic>)
                        .animate().fadeIn(delay: 600.ms),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.go('/quizzes'),
                          icon: const Icon(Icons.list_rounded),
                          label: const Text('All Quizzes'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => context.go('/quizzes/${widget.quizId}'),
                          icon: const Icon(Icons.replay_rounded),
                          label: const Text('Try Again'),
                        ),
                      ),
                    ],
                  ).animate().slideY(begin: 0.3, duration: 400.ms, delay: 700.ms).fadeIn(),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 30,
              colors: const [AppColors.primary, AppColors.secondary, AppColors.warning, AppColors.success],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreCircle extends StatelessWidget {
  final double percentage;
  final bool isPassed;

  const _ScoreCircle({required this.percentage, required this.isPassed});

  @override
  Widget build(BuildContext context) {
    final color = isPassed ? AppColors.success : AppColors.error;

    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 160,
            height: 160,
            child: CircularProgressIndicator(
              value: percentage / 100,
              strokeWidth: 12,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                isPassed ? 'PASSED' : 'FAILED',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _AnswerReview extends StatelessWidget {
  final Map<String, dynamic> gradedAnswers;

  const _AnswerReview({required this.gradedAnswers});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Answer Review', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        ...gradedAnswers.values.map((answer) {
          final a = answer as Map<String, dynamic>;
          final isCorrect = a['is_correct'] as bool? ?? false;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (isCorrect ? AppColors.success : AppColors.error).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (isCorrect ? AppColors.success : AppColors.error).withOpacity(0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: isCorrect ? AppColors.success : AppColors.error,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isCorrect) ...[
                        Text(
                          'Correct: ${a['correct_answer']}',
                          style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                      ],
                      if (a['explanation'] != null && a['explanation'].toString().isNotEmpty)
                        Text(a['explanation'], style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.5)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
