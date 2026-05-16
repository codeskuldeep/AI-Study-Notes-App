import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/dashboard_provider.dart';

class StatsGrid extends StatelessWidget {
  final DashboardStats stats;

  const StatsGrid({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _StatCard(
          label: 'Notes Created',
          value: '${stats.notesCreated}',
          icon: Icons.description_rounded,
          color: AppColors.primary,
        ),
        _StatCard(
          label: 'Quizzes Done',
          value: '${stats.quizzesCompleted}',
          icon: Icons.quiz_rounded,
          color: AppColors.secondary,
        ),
        _StatCard(
          label: 'Avg Score',
          value: '${stats.avgQuizScore.toStringAsFixed(0)}%',
          icon: Icons.score_rounded,
          color: AppColors.success,
        ),
        _StatCard(
          label: 'Cards Reviewed',
          value: '${stats.flashcardsReviewed}',
          icon: Icons.style_rounded,
          color: AppColors.warning,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
