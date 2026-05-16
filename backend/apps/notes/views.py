import logging
from django.shortcuts import get_object_or_404
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework import generics, filters, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.viewsets import ModelViewSet

from core.mixins import SuccessResponseMixin, UserFilterMixin
from core.permissions import IsOwner
from services.ai_service import ai_service
from .models import Note
from .serializers import NoteSerializer, NoteListSerializer, GenerateNoteSerializer, NoteUpdateSerializer


logger = logging.getLogger(__name__)


class NoteViewSet(SuccessResponseMixin, UserFilterMixin, ModelViewSet):
    serializer_class = NoteSerializer
    permission_classes = [IsOwner]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['note_type', 'source_type', 'subject', 'is_favorite']
    search_fields = ['title', 'topic', 'subject', 'tags']
    ordering_fields = ['created_at', 'updated_at', 'title']
    ordering = ['-created_at']

    def get_queryset(self):
        return Note.objects.filter(user=self.request.user)

    def get_serializer_class(self):
        if self.action == 'list':
            return NoteListSerializer
        if self.action in ('update', 'partial_update'):
            return NoteUpdateSerializer
        return NoteSerializer

    def list(self, request, *args, **kwargs):
        queryset = self.filter_queryset(self.get_queryset())
        page = self.paginate_queryset(queryset)
        serializer = NoteListSerializer(page or queryset, many=True)
        if page is not None:
            return self.get_paginated_response(serializer.data)
        return self.success_response(data=serializer.data)

    def retrieve(self, request, *args, **kwargs):
        note = self.get_object()
        return self.success_response(data=NoteSerializer(note).data)

    def destroy(self, request, *args, **kwargs):
        self.get_object().delete()
        return self.success_response(message='Note deleted.')

    @action(detail=False, methods=['post'], url_path='generate')
    def generate(self, request):
        serializer = GenerateNoteSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        content = data.get('content', '')
        if not content and data.get('topic'):
            content = f"Topic: {data['topic']}\nSubject: {data.get('subject', '')}"

        if data.get('upload_id'):
            from apps.uploads.models import Upload
            upload = get_object_or_404(Upload, id=data['upload_id'], user=request.user)
            content = upload.extracted_text or content

        # Create note with placeholder
        note = Note.objects.create(
            user=request.user,
            title=data['title'],
            topic=data.get('topic', ''),
            subject=data.get('subject', ''),
            note_type=data['note_type'],
            source_type=data['source_type'],
            raw_content=content,
            generated_content='Generating...',
            tags=data.get('tags', []),
        )

        generated = ai_service.generate_notes(
            content,
            data['note_type'],
            data.get('topic', ''),
            data.get('level', 'undergraduate')
        )

        note.generated_content = generated
        note.save()

        return self.created_response(
            data=NoteSerializer(note).data,
            message='Note generation started.'
        )

    @action(detail=True, methods=['post'], url_path='toggle-favorite')
    def toggle_favorite(self, request, pk=None):
        note = self.get_object()
        note.is_favorite = not note.is_favorite
        note.save(update_fields=['is_favorite'])
        return self.success_response(
            data={'is_favorite': note.is_favorite},
            message='Favorite updated.'
        )

    @action(detail=True, methods=['get'], url_path='regenerate')
    def regenerate(self, request, pk=None):
        note = self.get_object()

        if not note.raw_content:
            return Response(
                {'error': {'message': 'No source content to regenerate from.'}},
                status=400
            )

        generated = ai_service.generate_notes(
            note.raw_content,
            note.note_type,
            note.topic,
            'undergraduate'
        )

        note.generated_content = generated
        note.save()

        return self.success_response(message='Regeneration completed.')
