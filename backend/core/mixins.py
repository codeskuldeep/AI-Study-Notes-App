from rest_framework.response import Response
from rest_framework import status


class SuccessResponseMixin:
    def success_response(self, data=None, message='Success', status_code=status.HTTP_200_OK, **kwargs):
        response_data = {'success': True, 'message': message}
        if data is not None:
            response_data['data'] = data
        response_data.update(kwargs)
        return Response(response_data, status=status_code)

    def created_response(self, data=None, message='Created successfully'):
        return self.success_response(data, message, status.HTTP_201_CREATED)


class UserFilterMixin:
    def get_queryset(self):
        return super().get_queryset().filter(user=self.request.user)
