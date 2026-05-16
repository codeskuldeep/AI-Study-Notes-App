from rest_framework import serializers
from .models import Badge, UserBadge, XPTransaction, Leaderboard


class BadgeSerializer(serializers.ModelSerializer):
    class Meta:
        model = Badge
        fields = ('id', 'name', 'description', 'icon', 'color', 'xp_reward', 'badge_type')


class UserBadgeSerializer(serializers.ModelSerializer):
    badge = BadgeSerializer(read_only=True)

    class Meta:
        model = UserBadge
        fields = ('id', 'badge', 'earned_at')


class XPTransactionSerializer(serializers.ModelSerializer):
    class Meta:
        model = XPTransaction
        fields = ('id', 'activity', 'xp_earned', 'description', 'created_at')


class LeaderboardSerializer(serializers.ModelSerializer):
    user_name = serializers.CharField(source='user.username', read_only=True)
    avatar = serializers.ImageField(source='user.avatar', read_only=True)
    level = serializers.IntegerField(source='user.level', read_only=True)

    class Meta:
        model = Leaderboard
        fields = ('rank', 'user_name', 'avatar', 'level', 'xp', 'updated_at')
