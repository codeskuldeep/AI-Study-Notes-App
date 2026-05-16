from django.contrib import admin
from .models import StudySession, WeakTopic


@admin.register(StudySession)
class StudySessionAdmin(admin.ModelAdmin):
    list_display = ('user', 'activity_type', 'duration_minutes', 'subject', 'date')


@admin.register(WeakTopic)
class WeakTopicAdmin(admin.ModelAdmin):
    list_display = ('user', 'topic', 'subject', 'error_count')
