import logging
from celery import shared_task
from django.conf import settings

logger = logging.getLogger(__name__)


@shared_task(bind=True, max_retries=3, default_retry_delay=60)
def generate_note_async(self, note_id: str, content: str, note_type: str, topic: str, level: str):
    from .models import Note
    from services.ai_service import ai_service

    try:
        note = Note.objects.get(id=note_id)
        generated = ai_service.generate_notes(content, note_type, topic, level)
        note.generated_content = generated
        note.raw_content = content
        note.save(update_fields=['generated_content', 'raw_content', 'word_count'])

        # Award XP
        from apps.gamification.services import GamificationService
        GamificationService.award_xp(note.user, 'note_generated')

        logger.info(f'Note {note_id} generated successfully')
        return {'status': 'success', 'note_id': note_id}
    except Exception as exc:
        logger.error(f'Note generation failed for {note_id}: {exc}')
        raise self.retry(exc=exc)
