from django.shortcuts import get_object_or_404
from rest_framework.decorators import action
from rest_framework.viewsets import ModelViewSet

from core.mixins import SuccessResponseMixin, UserFilterMixin
from core.permissions import IsOwner
from services.ai_service import ai_service
from .models import ChatSession, ChatMessage
from .serializers import (
    ChatSessionSerializer, ChatSessionListSerializer,
    SendMessageSerializer, CreateSessionSerializer,
)


class ChatSessionViewSet(SuccessResponseMixin, UserFilterMixin, ModelViewSet):
    permission_classes = [IsOwner]

    def get_queryset(self):
        return ChatSession.objects.filter(user=self.request.user).prefetch_related('messages')

    def get_serializer_class(self):
        if self.action == 'list':
            return ChatSessionListSerializer
        return ChatSessionSerializer

    def list(self, request, *args, **kwargs):
        return self.success_response(
            data=ChatSessionListSerializer(self.get_queryset(), many=True).data
        )

    def retrieve(self, request, *args, **kwargs):
        return self.success_response(data=ChatSessionSerializer(self.get_object()).data)

    def create(self, request, *args, **kwargs):
        serializer = CreateSessionSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        note = None
        if data.get('note_id'):
            from apps.notes.models import Note
            note = get_object_or_404(Note, id=data['note_id'], user=request.user)

        session = ChatSession.objects.create(
            user=request.user,
            title=data['title'],
            note=note,
        )
        return self.created_response(
            data=ChatSessionSerializer(session).data,
            message='Chat session created.'
        )

    def destroy(self, request, *args, **kwargs):
        self.get_object().delete()
        return self.success_response(message='Session deleted.')

    @action(detail=True, methods=['post'], url_path='send')
    def send_message(self, request, pk=None):
        session = self.get_object()
        serializer = SendMessageSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        user_message = serializer.validated_data['message']

        context = ''
        if session.note:
            context = session.note.generated_content[:3000]

        recent_messages = session.messages.order_by('-created_at')[:10]
        conversation_history = '\n'.join([
            f"{msg.role.capitalize()}: {msg.content}"
            for msg in reversed(list(recent_messages))
        ])
        if conversation_history:
            context = f"Previous conversation:\n{conversation_history}\n\nNote content:\n{context}"

        ChatMessage.objects.create(session=session, role='user', content=user_message)

        ai_response = ai_service.get_tutor_response(user_message, context)

        assistant_message = ChatMessage.objects.create(
            session=session, role='assistant', content=ai_response
        )

        if not session.title or session.title == 'New Chat':
            session.title = user_message[:50]
            session.save(update_fields=['title', 'updated_at'])

        return self.success_response(
            data={
                'session_id': str(session.id),
                'message': {'id': str(assistant_message.id), 'role': 'assistant', 'content': ai_response},
            }
        )
