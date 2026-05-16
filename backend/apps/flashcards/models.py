import uuid
from django.db import models
from django.conf import settings


class FlashcardDeck(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='flashcard_decks')
    title = models.CharField(max_length=200)
    subject = models.CharField(max_length=100, blank=True)
    description = models.TextField(blank=True)
    tags = models.JSONField(default=list, blank=True)
    is_favorite = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'flashcard_decks'
        ordering = ['-created_at']

    def __str__(self):
        return self.title

    @property
    def card_count(self):
        return self.cards.count()


class Flashcard(models.Model):
    DIFFICULTY_CHOICES = [('easy', 'Easy'), ('medium', 'Medium'), ('hard', 'Hard')]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    deck = models.ForeignKey(FlashcardDeck, on_delete=models.CASCADE, related_name='cards')
    front = models.TextField()
    back = models.TextField()
    difficulty = models.CharField(max_length=10, choices=DIFFICULTY_CHOICES, default='medium')
    category = models.CharField(max_length=100, blank=True)
    is_favorite = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'flashcards'
        ordering = ['created_at']

    def __str__(self):
        return self.front[:50]


class FlashcardReview(models.Model):
    RATING_CHOICES = [(1, 'Again'), (2, 'Hard'), (3, 'Good'), (4, 'Easy')]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    flashcard = models.ForeignKey(Flashcard, on_delete=models.CASCADE, related_name='reviews')
    rating = models.PositiveSmallIntegerField(choices=RATING_CHOICES)
    next_review = models.DateTimeField(null=True, blank=True)
    review_count = models.PositiveIntegerField(default=0)
    reviewed_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'flashcard_reviews'
        unique_together = ('user', 'flashcard')
