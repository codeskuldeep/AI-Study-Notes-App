import logging
from rest_framework.views import exception_handler
from rest_framework.response import Response
from rest_framework import status

logger = logging.getLogger(__name__)


def custom_exception_handler(exc, context):
    response = exception_handler(exc, context)

    if response is not None:
        error_data = {
            'success': False,
            'error': {
                'code': response.status_code,
                'message': _get_error_message(response),
                'details': response.data,
            }
        }
        response.data = error_data
    else:
        logger.exception('Unhandled exception', exc_info=exc)
        response = Response(
            {
                'success': False,
                'error': {
                    'code': status.HTTP_500_INTERNAL_SERVER_ERROR,
                    'message': 'An unexpected error occurred.',
                    'details': {},
                }
            },
            status=status.HTTP_500_INTERNAL_SERVER_ERROR,
        )

    return response


def _get_error_message(response):
    if isinstance(response.data, dict):
        if 'detail' in response.data:
            return str(response.data['detail'])
        if 'non_field_errors' in response.data:
            return str(response.data['non_field_errors'][0])
    if isinstance(response.data, list) and response.data:
        return str(response.data[0])
    return 'An error occurred.'


class ServiceException(Exception):
    def __init__(self, message, code='service_error', status_code=400):
        self.message = message
        self.code = code
        self.status_code = status_code
        super().__init__(message)


class AIServiceException(ServiceException):
    def __init__(self, message='AI service temporarily unavailable'):
        super().__init__(message, code='ai_service_error', status_code=503)


class OCRServiceException(ServiceException):
    def __init__(self, message='OCR processing failed'):
        super().__init__(message, code='ocr_error', status_code=422)


class QuotaExceededException(ServiceException):
    def __init__(self, message='Daily generation quota exceeded'):
        super().__init__(message, code='quota_exceeded', status_code=429)
