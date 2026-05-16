from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework.decorators import action
from rest_framework.viewsets import ModelViewSet

from core.mixins import SuccessResponseMixin, UserFilterMixin
from core.permissions import IsOwner
from services.ai_service import ai_service
from .models import Quiz, Question, QuizAttempt
from .serializers import (
    QuizSerializer, QuizListSerializer, GenerateQuizSerializer,
    SubmitAttemptSerializer, QuizAttemptSerializer, QuestionWithAnswerSerializer,
)


class QuizViewSet(SuccessResponseMixin, UserFilterMixin, ModelViewSet):
    permission_classes = [IsOwner]

    def get_queryset(self):
        return Quiz.objects.filter(user=self.request.user).prefetch_related('questions')

    def get_serializer_class(self):
        if self.action == 'list':
            return QuizListSerializer
        return QuizSerializer

    def list(self, request, *args, **kwargs):
        queryset = self.filter_queryset(self.get_queryset())
        return self.success_response(data=QuizListSerializer(queryset, many=True).data)

    def retrieve(self, request, *args, **kwargs):
        return self.success_response(
            data=QuizSerializer(self.get_object(), context={'request': request}).data
        )

    def destroy(self, request, *args, **kwargs):
        self.get_object().delete()
        return self.success_response(message='Quiz deleted.')

    @action(detail=False, methods=['post'], url_path='generate')
    def generate(self, request):
        serializer = GenerateQuizSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        content = data.get('content', '')
        if data.get('upload_id'):
            from apps.uploads.models import Upload
            upload = get_object_or_404(Upload, id=data['upload_id'], user=request.user)
            content = upload.extracted_text or content
        if not content:
            content = f"Topic: {data.get('topic', data['title'])}"

        quiz_data = ai_service.generate_quiz(
            content, data.get('topic', ''), data['difficulty'], data['question_count']
        )

        quiz = Quiz.objects.create(
            user=request.user,
            title=data['title'],
            description=quiz_data.get('description', ''),
            subject=data.get('subject', ''),
            topic=data.get('topic', ''),
            difficulty=data['difficulty'],
            time_limit=quiz_data.get('time_limit', 10),
        )

        questions = []
        for i, q in enumerate(quiz_data.get('questions', [])):
            questions.append(Question(
                quiz=quiz,
                question_text=q.get('question', ''),
                question_type=q.get('type', 'mcq'),
                options=q.get('options', []),
                correct_answer=q.get('correct_answer', ''),
                explanation=q.get('explanation', ''),
                difficulty=q.get('difficulty', 'medium'),
                points=q.get('points', 1),
                order=i,
            ))

        Question.objects.bulk_create(questions)
        quiz.total_questions = len(questions)
        quiz.save(update_fields=['total_questions'])

        return self.created_response(
            data=QuizSerializer(quiz, context={'request': request}).data,
            message=f'Quiz generated with {len(questions)} questions.'
        )

    @action(detail=True, methods=['post'], url_path='attempt')
    def submit_attempt(self, request, pk=None):
        quiz = self.get_object()
        serializer = SubmitAttemptSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        answers = serializer.validated_data['answers']
        time_taken = serializer.validated_data['time_taken']
        questions = list(quiz.questions.all())

        score = 0
        max_score = sum(q.points for q in questions)
        graded_answers = {}

        for question in questions:
            qid = str(question.id)
            user_answer = answers.get(qid, '').strip().upper()
            correct = question.correct_answer.strip().upper()
            is_correct = user_answer == correct
            if is_correct:
                score += question.points
            graded_answers[qid] = {
                'user_answer': answers.get(qid, ''),
                'correct_answer': question.correct_answer,
                'is_correct': is_correct,
                'explanation': question.explanation,
            }

        percentage = (score / max_score * 100) if max_score > 0 else 0

        attempt = QuizAttempt.objects.create(
            user=request.user,
            quiz=quiz,
            score=score,
            max_score=max_score,
            percentage=round(percentage, 2),
            time_taken=time_taken,
            is_completed=True,
            answers=graded_answers,
            completed_at=timezone.now(),
        )

        from apps.gamification.services import GamificationService
        xp_type = 'perfect_quiz' if percentage == 100 else 'quiz_completed'
        GamificationService.award_xp(request.user, xp_type)

        from apps.analytics.services import AnalyticsService
        AnalyticsService.record_quiz_attempt(request.user, quiz, score, max_score, time_taken)

        return self.created_response(
            data={
                'attempt': QuizAttemptSerializer(attempt).data,
                'graded_answers': graded_answers,
            },
            message=f'Quiz completed! Score: {score}/{max_score} ({percentage:.1f}%)'
        )

    @action(detail=True, methods=['get'], url_path='history')
    def attempt_history(self, request, pk=None):
        quiz = self.get_object()
        attempts = QuizAttempt.objects.filter(user=request.user, quiz=quiz).order_by('-started_at')
        return self.success_response(data=QuizAttemptSerializer(attempts, many=True).data)
