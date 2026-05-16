from rest_framework import generics
from core.mixins import SuccessResponseMixin
from .services import AnalyticsService
from .models import StudySession, WeakTopic
from .serializers import StudySessionSerializer, WeakTopicSerializer


class DashboardView(SuccessResponseMixin, generics.GenericAPIView):
    def get(self, request):
        stats = AnalyticsService.get_dashboard_stats(request.user)
        return self.success_response(data=stats)


class StudyHistoryView(SuccessResponseMixin, generics.ListAPIView):
    serializer_class = StudySessionSerializer

    def get_queryset(self):
        return StudySession.objects.filter(user=self.request.user)

    def list(self, request, *args, **kwargs):
        return self.success_response(
            data=StudySessionSerializer(self.get_queryset()[:30], many=True).data
        )


class WeakTopicsView(SuccessResponseMixin, generics.GenericAPIView):
    def get(self, request):
        topics = WeakTopic.objects.filter(user=request.user)
        return self.success_response(data=WeakTopicSerializer(topics, many=True).data)
