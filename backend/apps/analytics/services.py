import logging
from django.utils import timezone
from django.db.models import Sum, Avg, Count

logger = logging.getLogger(__name__)


class AnalyticsService:
    @staticmethod
    def record_quiz_attempt(user, quiz, score, max_score, time_taken):
        from .models import StudySession, WeakTopic
        from apps.quizzes.models import QuizAttempt

        date = timezone.now().date()
        StudySession.objects.create(
            user=user,
            activity_type='quiz',
            duration_minutes=time_taken // 60,
            subject=quiz.subject or quiz.topic,
            date=date,
        )

        # Identify weak topics from wrong answers
        percentage = (score / max_score * 100) if max_score > 0 else 0
        if percentage < 70 and quiz.topic:
            WeakTopic.objects.update_or_create(
                user=user,
                topic=quiz.topic,
                defaults={'subject': quiz.subject or ''},
            )
            WeakTopic.objects.filter(user=user, topic=quiz.topic).update(
                error_count=WeakTopic.objects.get(user=user, topic=quiz.topic).error_count + 1
            )

    @staticmethod
    def get_dashboard_stats(user) -> dict:
        from apps.notes.models import Note
        from apps.quizzes.models import QuizAttempt
        from apps.flashcards.models import FlashcardDeck, FlashcardReview
        from .models import StudySession, WeakTopic

        now = timezone.now()
        week_ago = now - timezone.timedelta(days=7)
        month_ago = now - timezone.timedelta(days=30)

        notes_count = Note.objects.filter(user=user).count()
        recent_notes = Note.objects.filter(user=user).order_by('-created_at')[:5]

        quizzes_completed = QuizAttempt.objects.filter(user=user, is_completed=True).count()
        avg_score = QuizAttempt.objects.filter(
            user=user, is_completed=True
        ).aggregate(avg=Avg('percentage'))['avg'] or 0

        flashcard_decks = FlashcardDeck.objects.filter(user=user).count()
        flashcards_reviewed_week = FlashcardReview.objects.filter(
            user=user, reviewed_at__gte=week_ago
        ).count()

        study_minutes_week = StudySession.objects.filter(
            user=user, date__gte=week_ago.date()
        ).aggregate(total=Sum('duration_minutes'))['total'] or 0

        weak_topics = WeakTopic.objects.filter(user=user)[:5]

        from apps.gamification.services import GamificationService
        gamification_stats = GamificationService.get_user_stats(user)

        from apps.notes.serializers import NoteListSerializer
        from apps.analytics.serializers import WeakTopicSerializer

        return {
            'notes': {
                'total': notes_count,
                'recent': NoteListSerializer(recent_notes, many=True).data,
            },
            'quizzes': {
                'completed': quizzes_completed,
                'avg_score': round(avg_score, 1),
            },
            'flashcards': {
                'decks': flashcard_decks,
                'reviewed_this_week': flashcards_reviewed_week,
            },
            'study': {
                'minutes_this_week': study_minutes_week,
                'goal_minutes': user.study_goal_minutes,
                'goal_progress': min(100, round(study_minutes_week / max(user.study_goal_minutes * 7, 1) * 100)),
            },
            'weak_topics': WeakTopicSerializer(weak_topics, many=True).data,
            'gamification': gamification_stats,
        }
