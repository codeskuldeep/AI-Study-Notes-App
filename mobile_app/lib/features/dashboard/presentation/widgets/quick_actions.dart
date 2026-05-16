import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _QuickActionBtn(
          label: 'Generate\nNotes',
          icon: Icons.auto_awesome_rounded,
          gradient: AppColors.primaryGradient,
          onTap: () => context.push('/generate'),
        ),
        const SizedBox(width: 12),
        _QuickActionBtn(
          label: 'New\nQuiz',
          icon: Icons.quiz_rounded,
          gradient: const LinearGradient(colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)]),
          onTap: () => context.push('/quizzes'),
        ),
        const SizedBox(width: 12),
        _QuickActionBtn(
          label: 'AI\nTutor',
          icon: Icons.smart_toy_rounded,
          gradient: const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF0891B2)]),
          onTap: () => context.push('/ai-tutor'),
        ),
        const SizedBox(width: 12),
        _QuickActionBtn(
          label: 'Flash\nCards',
          icon: Icons.style_rounded,
          gradient: const LinearGradient(colors: [Color(0xFF22C55E), Color(0xFF16A34A)]),
          onTap: () => context.push('/flashcards'),
        ),
      ],
    );
  }
}

class _QuickActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _QuickActionBtn({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 26),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
