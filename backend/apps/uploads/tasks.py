import logging
from celery import shared_task
from django.utils import timezone

logger = logging.getLogger(__name__)


@shared_task(bind=True, max_retries=2)
def process_upload(self, upload_id: str):
    from .models import Upload
    from services.ocr_service import ocr_service

    try:
        upload = Upload.objects.get(id=upload_id)
        upload.status = 'processing'
        upload.save(update_fields=['status'])

        file_path = upload.file.path
        text = ocr_service.extract_text(file_path, upload.file_type)

        upload.extracted_text = text
        upload.status = 'completed'
        upload.processed_at = timezone.now()
        upload.save(update_fields=['extracted_text', 'status', 'processed_at'])
        logger.info(f'Upload {upload_id} processed successfully')
        return {'status': 'success', 'upload_id': upload_id, 'text_length': len(text)}
    except Exception as exc:
        logger.error(f'Upload processing failed for {upload_id}: {exc}')
        try:
            upload = Upload.objects.get(id=upload_id)
            upload.status = 'failed'
            upload.error_message = str(exc)
            upload.save(update_fields=['status', 'error_message'])
        except Upload.DoesNotExist:
            pass
        raise self.retry(exc=exc)
