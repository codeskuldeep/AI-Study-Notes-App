from rest_framework import serializers
from .models import FlashcardDeck, Flashcard, FlashcardReview


class FlashcardSerializer(serializers.ModelSerializer):
    class Meta:
        model = Flashcard
        fields = ('id', 'front', 'back', 'difficulty', 'category', 'is_favorite', 'created_at')
        read_only_fields = ('id', 'created_at')


class FlashcardDeckSerializer(serializers.ModelSerializer):
    card_count = serializers.IntegerField(read_only=True)
    cards = FlashcardSerializer(many=True, read_only=True)

    class Meta:
        model = FlashcardDeck
        fields = ('id', 'title', 'subject', 'description', 'tags', 'is_favorite', 'card_count', 'cards', 'created_at', 'updated_at')
        read_only_fields = ('id', 'card_count', 'created_at', 'updated_at')


class FlashcardDeckListSerializer(serializers.ModelSerializer):
    card_count = serializers.IntegerField(read_only=True)

    class Meta:
        model = FlashcardDeck
        fields = ('id', 'title', 'subject', 'description', 'tags', 'is_favorite', 'card_count', 'created_at')


class GenerateFlashcardsSerializer(serializers.Serializer):
    title = serializers.CharField(max_length=200)
    topic = serializers.CharField(max_length=200, required=False, allow_blank=True)
    subject = serializers.CharField(max_length=100, required=False, allow_blank=True)
    content = serializers.CharField(required=False, allow_blank=True)
    upload_id = serializers.UUIDField(required=False, allow_null=True)
    count = serializers.IntegerField(default=10, min_value=5, max_value=50)


class ReviewFlashcardSerializer(serializers.Serializer):
    rating = serializers.IntegerField(min_value=1, max_value=4)
