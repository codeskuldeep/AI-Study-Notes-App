from django.contrib import admin
from .models import Quiz, Question, QuizAttempt


@admin.register(Quiz)
class QuizAdmin(admin.ModelAdmin):
    list_display = ('title', 'user', 'difficulty', 'total_questions', 'created_at')
    list_filter = ('difficulty',)
    search_fields = ('title', 'user__email')


@admin.register(QuizAttempt)
class QuizAttemptAdmin(admin.ModelAdmin):
    list_display = ('user', 'quiz', 'score', 'max_score', 'percentage', 'started_at')
    list_filter = ('is_completed',)
