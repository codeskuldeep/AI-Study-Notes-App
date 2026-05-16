from rest_framework import generics
from core.mixins import SuccessResponseMixin
from .models import Notification
from .serializers import NotificationSerializer


class NotificationListView(SuccessResponseMixin, generics.GenericAPIView):
    def get(self, request):
        notifs = Notification.objects.filter(user=request.user)
        unread_count = notifs.filter(is_read=False).count()
        return self.success_response(data={
            'notifications': NotificationSerializer(notifs[:50], many=True).data,
            'unread_count': unread_count,
        })


class MarkAllReadView(SuccessResponseMixin, generics.GenericAPIView):
    def post(self, request):
        Notification.objects.filter(user=request.user, is_read=False).update(is_read=True)
        return self.success_response(message='All notifications marked as read.')


class MarkReadView(SuccessResponseMixin, generics.GenericAPIView):
    def post(self, request, pk):
        Notification.objects.filter(id=pk, user=request.user).update(is_read=True)
        return self.success_response(message='Notification marked as read.')
