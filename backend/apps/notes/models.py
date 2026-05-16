import uuid
from django.db import models
from django.conf import settings


class Note(models.Model):
    NOTE_TYPES = [
        ('summary', 'Summary'),
        ('detailed', 'Detailed'),
        ('revision', 'Revision'),
        ('bullet', 'Bullet Points'),
    ]

    SOURCE_TYPES = [
        ('topic', 'Topic Input'),
        ('pdf', 'PDF Upload'),
        ('image', 'Image Upload'),
        ('text', 'Text Input'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='notes')
    title = models.CharField(max_length=300)
    topic = models.CharField(max_length=200, blank=True)
    subject = models.CharField(max_length=100, blank=True)
    note_type = models.CharField(max_length=20, choices=NOTE_TYPES, default='summary')
    source_type = models.CharField(max_length=20, choices=SOURCE_TYPES, default='topic')

    raw_content = models.TextField(blank=True)
    generated_content = models.TextField()

    is_favorite = models.BooleanField(default=False)
    is_shared = models.BooleanField(default=False)
    tags = models.JSONField(default=list, blank=True)
    word_count = models.PositiveIntegerField(default=0)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'notes'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user', '-created_at']),
            models.Index(fields=['user', 'subject']),
            models.Index(fields=['user', 'is_favorite']),
        ]

    def __str__(self):
        return f"{self.title} ({self.user.email})"

    def save(self, *args, **kwargs):
        if self.generated_content:
            self.word_count = len(self.generated_content.split())
        super().save(*args, **kwargs)


class NoteView(models.Model):
    note = models.ForeignKey(Note, on_delete=models.CASCADE, related_name='views')
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    viewed_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'note_views'
        unique_together = ('note', 'user')
