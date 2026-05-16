import uuid
from django.db import models
from django.conf import settings


class StudySession(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='study_sessions')
    activity_type = models.CharField(max_length=50)
    duration_minutes = models.PositiveIntegerField(default=0)
    subject = models.CharField(max_length=100, blank=True)
    date = models.DateField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'study_sessions'
        ordering = ['-date']


class WeakTopic(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='weak_topics')
    topic = models.CharField(max_length=200)
    subject = models.CharField(max_length=100, blank=True)
    error_count = models.PositiveIntegerField(default=0)
    last_reviewed = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'weak_topics'
        unique_together = ('user', 'topic')
        ordering = ['-error_count']
