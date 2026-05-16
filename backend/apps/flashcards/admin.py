from django.contrib import admin
from .models import FlashcardDeck, Flashcard, FlashcardReview


@admin.register(FlashcardDeck)
class FlashcardDeckAdmin(admin.ModelAdmin):
    list_display = ('title', 'user', 'subject', 'card_count', 'created_at')
    search_fields = ('title', 'user__email')


@admin.register(Flashcard)
class FlashcardAdmin(admin.ModelAdmin):
    list_display = ('front', 'deck', 'difficulty', 'is_favorite')
    list_filter = ('difficulty',)
