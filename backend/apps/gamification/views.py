from rest_framework import generics
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from core.mixins import SuccessResponseMixin
from .models import Badge, UserBadge, XPTransaction, Leaderboard
from .serializers import BadgeSerializer, UserBadgeSerializer, XPTransactionSerializer, LeaderboardSerializer
from .services import GamificationService


class StatsView(SuccessResponseMixin, generics.GenericAPIView):
    def get(self, request):
        stats = GamificationService.get_user_stats(request.user)
        return self.success_response(data=stats)


class BadgesView(SuccessResponseMixin, generics.GenericAPIView):
    def get(self, request):
        earned = UserBadge.objects.filter(user=request.user).select_related('badge')
        all_badges = Badge.objects.all()
        earned_ids = set(earned.values_list('badge_id', flat=True))

        return self.success_response(data={
            'earned': UserBadgeSerializer(earned, many=True).data,
            'all': BadgeSerializer(all_badges, many=True).data,
            'earned_count': len(earned_ids),
            'total_count': all_badges.count(),
        })


class XPHistoryView(SuccessResponseMixin, generics.ListAPIView):
    serializer_class = XPTransactionSerializer

    def get_queryset(self):
        return XPTransaction.objects.filter(user=self.request.user)

    def list(self, request, *args, **kwargs):
        return self.success_response(
            data=XPTransactionSerializer(self.get_queryset()[:50], many=True).data
        )


class LeaderboardView(SuccessResponseMixin, generics.GenericAPIView):
    def get(self, request):
        period = request.query_params.get('period', 'weekly')
        leaderboard = Leaderboard.objects.filter(period=period).select_related('user')[:100]
        user_rank = Leaderboard.objects.filter(user=request.user, period=period).first()

        return self.success_response(data={
            'leaderboard': LeaderboardSerializer(leaderboard, many=True).data,
            'my_rank': user_rank.rank if user_rank else None,
            'my_xp': user_rank.xp if user_rank else request.user.xp,
        })
