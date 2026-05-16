from datetime import timedelta
from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework import generics
from rest_framework.decorators import action
from rest_framework.viewsets import ModelViewSet

from core.mixins import SuccessResponseMixin, UserFilterMixin
from core.permissions import IsOwner
from services.ai_service import ai_service
from .models import FlashcardDeck, Flashcard, FlashcardReview
from .serializers import (
    FlashcardDeckSerializer, FlashcardDeckListSerializer, FlashcardSerializer,
    GenerateFlashcardsSerializer, ReviewFlashcardSerializer,
)


SPACED_REPETITION_INTERVALS = {1: 1, 2: 3, 3: 7, 4: 14}  # days per rating


class FlashcardDeckViewSet(SuccessResponseMixin, UserFilterMixin, ModelViewSet):
    permission_classes = [IsOwner]

    def get_queryset(self):
        return FlashcardDeck.objects.filter(user=self.request.user).prefetch_related('cards')

    def get_serializer_class(self):
        if self.action == 'list':
            return FlashcardDeckListSerializer
        return FlashcardDeckSerializer

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    def list(self, request, *args, **kwargs):
        queryset = self.get_queryset()
        return self.success_response(data=FlashcardDeckListSerializer(queryset, many=True).data)

    def retrieve(self, request, *args, **kwargs):
        return self.success_response(data=FlashcardDeckSerializer(self.get_object()).data)

    def destroy(self, request, *args, **kwargs):
        self.get_object().delete()
        return self.success_response(message='Deck deleted.')

    @action(detail=False, methods=['post'], url_path='generate')
    def generate(self, request):
        serializer = GenerateFlashcardsSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        content = data.get('content', '')
        if data.get('upload_id'):
            from apps.uploads.models import Upload
            upload = get_object_or_404(Upload, id=data['upload_id'], user=request.user)
            content = upload.extracted_text or content

        if not content:
            content = f"Topic: {data.get('topic', data['title'])}"

        flashcard_data = ai_service.generate_flashcards(
            content, data.get('topic', ''), data['count']
        )

        deck = FlashcardDeck.objects.create(
            user=request.user,
            title=data['title'],
            subject=data.get('subject', ''),
        )

        cards = [
            Flashcard(
                deck=deck,
                front=card.get('front', ''),
                back=card.get('back', ''),
                difficulty=card.get('difficulty', 'medium'),
                category=card.get('category', ''),
            )
            for card in flashcard_data if card.get('front') and card.get('back')
        ]
        Flashcard.objects.bulk_create(cards)

        from apps.gamification.services import GamificationService
        GamificationService.award_xp(request.user, 'note_generated')

        return self.created_response(
            data=FlashcardDeckSerializer(deck).data,
            message=f'Generated {len(cards)} flashcards.'
        )

    @action(detail=True, methods=['post'], url_path='cards/(?P<card_id>[^/.]+)/review/')
    def review_card(self, request, pk=None, card_id=None):
        deck = self.get_object()
        card = get_object_or_404(Flashcard, id=card_id, deck=deck)

        serializer = ReviewFlashcardSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        rating = serializer.validated_data['rating']

        interval_days = SPACED_REPETITION_INTERVALS.get(rating, 1)
        next_review = timezone.now() + timedelta(days=interval_days)

        review, created = FlashcardReview.objects.update_or_create(
            user=request.user,
            flashcard=card,
            defaults={'rating': rating, 'next_review': next_review},
        )
        if not created:
            review.review_count += 1
            review.save(update_fields=['review_count'])

        from apps.gamification.services import GamificationService
        GamificationService.award_xp(request.user, 'flashcard_reviewed')

        return self.success_response(
            data={'next_review': next_review, 'review_count': review.review_count},
            message='Review recorded.'
        )

    @action(detail=True, methods=['get'], url_path='due-cards')
    def due_cards(self, request, pk=None):
        deck = self.get_object()
        now = timezone.now()
        due = deck.cards.exclude(
            reviews__user=request.user,
            reviews__next_review__gt=now
        )
        return self.success_response(data=FlashcardSerializer(due, many=True).data)
