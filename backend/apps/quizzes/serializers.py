from rest_framework import serializers
from .models import Quiz, Question, QuizAttempt


class QuestionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Question
        fields = ('id', 'question_text', 'question_type', 'options', 'difficulty', 'points', 'order')
        read_only_fields = ('id',)


class QuestionWithAnswerSerializer(serializers.ModelSerializer):
    class Meta:
        model = Question
        fields = ('id', 'question_text', 'question_type', 'options', 'correct_answer', 'explanation', 'difficulty', 'points', 'order')
        read_only_fields = ('id',)


class QuizSerializer(serializers.ModelSerializer):
    questions = QuestionSerializer(many=True, read_only=True)
    attempt_count = serializers.SerializerMethodField()

    class Meta:
        model = Quiz
        fields = ('id', 'title', 'description', 'subject', 'topic', 'difficulty', 'time_limit', 'total_questions', 'is_favorite', 'questions', 'attempt_count', 'created_at')
        read_only_fields = ('id', 'total_questions', 'created_at')

    def get_attempt_count(self, obj):
        return obj.attempts.filter(user=self.context['request'].user).count()


class QuizListSerializer(serializers.ModelSerializer):
    class Meta:
        model = Quiz
        fields = ('id', 'title', 'subject', 'topic', 'difficulty', 'time_limit', 'total_questions', 'is_favorite', 'created_at')


class GenerateQuizSerializer(serializers.Serializer):
    title = serializers.CharField(max_length=200)
    topic = serializers.CharField(max_length=200, required=False, allow_blank=True)
    subject = serializers.CharField(max_length=100, required=False, allow_blank=True)
    content = serializers.CharField(required=False, allow_blank=True)
    upload_id = serializers.UUIDField(required=False, allow_null=True)
    difficulty = serializers.ChoiceField(choices=['easy', 'medium', 'hard', 'mixed'], default='medium')
    question_count = serializers.IntegerField(default=10, min_value=5, max_value=30)


class SubmitAttemptSerializer(serializers.Serializer):
    answers = serializers.DictField(child=serializers.CharField())
    time_taken = serializers.IntegerField(min_value=0)


class QuizAttemptSerializer(serializers.ModelSerializer):
    class Meta:
        model = QuizAttempt
        fields = ('id', 'quiz', 'score', 'max_score', 'percentage', 'time_taken', 'is_completed', 'answers', 'started_at', 'completed_at')
        read_only_fields = fields
