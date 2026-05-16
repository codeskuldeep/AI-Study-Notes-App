from django.contrib import admin
from .models import Upload


@admin.register(Upload)
class UploadAdmin(admin.ModelAdmin):
    list_display = ('original_filename', 'user', 'file_type', 'status', 'file_size', 'created_at')
    list_filter = ('file_type', 'status')
    search_fields = ('original_filename', 'user__email')
    readonly_fields = ('id', 'created_at', 'processed_at')
