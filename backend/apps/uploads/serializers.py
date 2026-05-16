from rest_framework import serializers
from django.conf import settings
from .models import Upload


class UploadSerializer(serializers.ModelSerializer):
    class Meta:
        model = Upload
        fields = ('id', 'original_filename', 'file_type', 'file_size', 'status', 'page_count', 'created_at', 'processed_at')
        read_only_fields = ('id', 'status', 'page_count', 'created_at', 'processed_at')


class UploadCreateSerializer(serializers.Serializer):
    file = serializers.FileField()

    def validate_file(self, value):
        ext = value.name.rsplit('.', 1)[-1].lower()
        allowed = ['pdf', 'png', 'jpg', 'jpeg', 'webp', 'heic']
        if ext not in allowed:
            raise serializers.ValidationError(f'Unsupported file type. Allowed: {", ".join(allowed)}')
        max_size = getattr(settings, 'MAX_UPLOAD_SIZE', 10 * 1024 * 1024)
        if value.size > max_size:
            raise serializers.ValidationError(f'File too large. Max size: {max_size // 1024 // 1024}MB')
        return value


class UploadDetailSerializer(serializers.ModelSerializer):
    class Meta:
        model = Upload
        fields = ('id', 'original_filename', 'file_type', 'file_size', 'mime_type',
                  'status', 'extracted_text', 'page_count', 'created_at', 'processed_at')
        read_only_fields = fields
