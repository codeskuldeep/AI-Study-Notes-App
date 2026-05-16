from rest_framework import serializers
from .models import StudySession, WeakTopic


class StudySessionSerializer(serializers.ModelSerializer):
    class Meta:
        model = StudySession
        fields = ('id', 'activity_type', 'duration_minutes', 'subject', 'date', 'created_at')


class WeakTopicSerializer(serializers.ModelSerializer):
    class Meta:
        model = WeakTopic
        fields = ('id', 'topic', 'subject', 'error_count', 'last_reviewed')
