from django.contrib import admin
from .models import Note


@admin.register(Note)
class NoteAdmin(admin.ModelAdmin):
    list_display = ('title', 'user', 'note_type', 'source_type', 'word_count', 'is_favorite', 'created_at')
    list_filter = ('note_type', 'source_type', 'is_favorite')
    search_fields = ('title', 'topic', 'user__email')
    ordering = ('-created_at',)
    readonly_fields = ('id', 'word_count', 'created_at', 'updated_at')
