import logging
from django.conf import settings
from .models import Badge, UserBadge, XPTransaction

logger = logging.getLogger(__name__)


class GamificationService:
    @staticmethod
    def award_xp(user, activity: str) -> int:
        xp_rewards = getattr(settings, 'XP_REWARDS', {})
        xp = xp_rewards.get(activity, 0)
        if xp <= 0:
            return 0

        XPTransaction.objects.create(user=user, activity=activity, xp_earned=xp)
        user.add_xp(xp)
        GamificationService.check_badges(user)
        return xp

    @staticmethod
    def check_badges(user):
        from apps.notes.models import Note
        from apps.quizzes.models import QuizAttempt
        from apps.flashcards.models import FlashcardReview

        badge_checks = {
            'first_note': Note.objects.filter(user=user).count() >= 1,
            'note_master': Note.objects.filter(user=user).count() >= 50,
            'quiz_ace': QuizAttempt.objects.filter(user=user, is_completed=True).count() >= 10,
            'flashcard_warrior': FlashcardReview.objects.filter(user=user).count() >= 100,
            'streak_champion': user.streak_count >= 30,
            'week_streak': user.streak_count >= 7,
        }

        for badge_type, condition in badge_checks.items():
            if condition:
                try:
                    badge = Badge.objects.get(badge_type=badge_type)
                    _, created = UserBadge.objects.get_or_create(user=user, badge=badge)
                    if created:
                        user.add_xp(badge.xp_reward)
                        logger.info(f'Badge {badge.name} awarded to {user.email}')
                except Badge.DoesNotExist:
                    pass

    @staticmethod
    def get_user_stats(user) -> dict:
        from apps.notes.models import Note
        from apps.quizzes.models import QuizAttempt
        from apps.flashcards.models import FlashcardReview

        notes_count = Note.objects.filter(user=user).count()
        quizzes_count = QuizAttempt.objects.filter(user=user, is_completed=True).count()
        flashcards_reviewed = FlashcardReview.objects.filter(user=user).count()
        badges_count = UserBadge.objects.filter(user=user).count()

        avg_quiz_score = 0
        attempts = QuizAttempt.objects.filter(user=user, is_completed=True)
        if attempts.exists():
            avg_quiz_score = sum(a.percentage for a in attempts) / attempts.count()

        return {
            'xp': user.xp,
            'level': user.level,
            'xp_to_next_level': user.xp_to_next_level,
            'streak': user.streak_count,
            'longest_streak': user.longest_streak,
            'notes_created': notes_count,
            'quizzes_completed': quizzes_count,
            'flashcards_reviewed': flashcards_reviewed,
            'badges_earned': badges_count,
            'avg_quiz_score': round(avg_quiz_score, 1),
        }
