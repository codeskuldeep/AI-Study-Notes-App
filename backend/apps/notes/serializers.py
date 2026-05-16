from rest_framework import serializers
from .models import Note


class NoteSerializer(serializers.ModelSerializer):
    class Meta:
        model = Note
        fields = (
            'id', 'title', 'topic', 'subject', 'note_type', 'source_type',
            'generated_content', 'is_favorite', 'is_shared', 'tags',
            'word_count', 'created_at', 'updated_at',
        )
        read_only_fields = ('id', 'word_count', 'created_at', 'updated_at')


class NoteListSerializer(serializers.ModelSerializer):
    class Meta:
        model = Note
        fields = ('id', 'title', 'topic', 'subject', 'note_type', 'source_type', 'is_favorite', 'word_count', 'created_at')


class GenerateNoteSerializer(serializers.Serializer):
    NOTE_TYPES = [('summary', 'Summary'), ('detailed', 'Detailed'), ('revision', 'Revision'), ('bullet', 'Bullet')]
    SOURCE_TYPES = [('topic', 'Topic'), ('text', 'Text'), ('pdf', 'PDF'), ('image', 'Image')]

    title = serializers.CharField(max_length=300)
    topic = serializers.CharField(max_length=200, required=False, allow_blank=True)
    subject = serializers.CharField(max_length=100, required=False, allow_blank=True)
    note_type = serializers.ChoiceField(choices=NOTE_TYPES, default='summary')
    source_type = serializers.ChoiceField(choices=SOURCE_TYPES, default='topic')
    content = serializers.CharField(required=False, allow_blank=True)
    upload_id = serializers.UUIDField(required=False, allow_null=True)
    level = serializers.CharField(default='undergraduate', required=False)
    tags = serializers.ListField(child=serializers.CharField(), required=False, default=list)

    def validate(self, attrs):
        source_type = attrs.get('source_type', 'topic')
        content = attrs.get('content', '')
        upload_id = attrs.get('upload_id')

        if source_type in ('topic',) and not attrs.get('topic') and not content:
            raise serializers.ValidationError('Topic or content is required.')
        if source_type in ('pdf', 'image') and not upload_id:
            raise serializers.ValidationError('upload_id is required for file-based notes.')
        return attrs


class NoteUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Note
        fields = ('title', 'topic', 'subject', 'generated_content', 'is_favorite', 'is_shared', 'tags')
