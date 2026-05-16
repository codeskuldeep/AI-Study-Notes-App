import uuid
from django.db import models
from django.conf import settings


class Badge(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=100, unique=True)
    description = models.TextField()
    icon = models.CharField(max_length=50, blank=True)
    color = models.CharField(max_length=7, default='#6C63FF')
    xp_reward = models.PositiveIntegerField(default=0)
    badge_type = models.CharField(max_length=50, blank=True)
    threshold = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'badges'

    def __str__(self):
        return self.name


class UserBadge(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='badges')
    badge = models.ForeignKey(Badge, on_delete=models.CASCADE)
    earned_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'user_badges'
        unique_together = ('user', 'badge')


class XPTransaction(models.Model):
    ACTIVITY_CHOICES = [
        ('note_generated', 'Note Generated'),
        ('quiz_completed', 'Quiz Completed'),
        ('perfect_quiz', 'Perfect Quiz'),
        ('flashcard_reviewed', 'Flashcard Reviewed'),
        ('daily_login', 'Daily Login'),
        ('streak_7_days', '7-Day Streak'),
        ('streak_30_days', '30-Day Streak'),
        ('badge_earned', 'Badge Earned'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='xp_transactions')
    activity = models.CharField(max_length=50, choices=ACTIVITY_CHOICES)
    xp_earned = models.IntegerField()
    description = models.CharField(max_length=200, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'xp_transactions'
        ordering = ['-created_at']


class Leaderboard(models.Model):
    PERIOD_CHOICES = [('weekly', 'Weekly'), ('monthly', 'Monthly'), ('alltime', 'All Time')]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    period = models.CharField(max_length=10, choices=PERIOD_CHOICES)
    rank = models.PositiveIntegerField()
    xp = models.PositiveIntegerField()
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'leaderboards'
        unique_together = ('user', 'period')
        ordering = ['rank']
