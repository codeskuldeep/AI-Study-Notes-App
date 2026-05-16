import os
from rest_framework import generics, status
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework.response import Response

from core.mixins import SuccessResponseMixin, UserFilterMixin
from core.permissions import IsOwner
from .models import Upload
from .serializers import UploadSerializer, UploadCreateSerializer, UploadDetailSerializer
from .tasks import process_upload


class UploadListCreateView(SuccessResponseMixin, generics.ListCreateAPIView):
    parser_classes = [MultiPartParser, FormParser]

    def get_queryset(self):
        return Upload.objects.filter(user=self.request.user)

    def get_serializer_class(self):
        if self.request.method == 'POST':
            return UploadCreateSerializer
        return UploadSerializer

    def list(self, request, *args, **kwargs):
        queryset = self.get_queryset()
        return self.success_response(data=UploadSerializer(queryset, many=True).data)

    def create(self, request, *args, **kwargs):
        serializer = UploadCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        file = serializer.validated_data['file']
        ext = file.name.rsplit('.', 1)[-1].lower()
        file_type = 'pdf' if ext == 'pdf' else 'image'

        upload = Upload.objects.create(
            user=request.user,
            file=file,
            original_filename=file.name,
            file_type=file_type,
            file_size=file.size,
            mime_type=file.content_type or '',
        )

        process_upload.delay(str(upload.id))

        return self.created_response(
            data=UploadSerializer(upload).data,
            message='File uploaded. Text extraction started.'
        )


class UploadDetailView(SuccessResponseMixin, generics.RetrieveDestroyAPIView):
    permission_classes = [IsOwner]

    def get_queryset(self):
        return Upload.objects.filter(user=self.request.user)

    def retrieve(self, request, *args, **kwargs):
        upload = self.get_object()
        return self.success_response(data=UploadDetailSerializer(upload).data)

    def destroy(self, request, *args, **kwargs):
        upload = self.get_object()
        if upload.file and os.path.exists(upload.file.path):
            os.remove(upload.file.path)
        upload.delete()
        return self.success_response(message='Upload deleted.')
