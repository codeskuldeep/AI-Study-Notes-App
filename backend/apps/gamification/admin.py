from django.contrib import admin
from .models import Badge, UserBadge, XPTransaction, Leaderboard


@admin.register(Badge)
class BadgeAdmin(admin.ModelAdmin):
    list_display = ('name', 'badge_type', 'xp_reward', 'threshold')


@admin.register(UserBadge)
class UserBadgeAdmin(admin.ModelAdmin):
    list_display = ('user', 'badge', 'earned_at')


@admin.register(XPTransaction)
class XPTransactionAdmin(admin.ModelAdmin):
    list_display = ('user', 'activity', 'xp_earned', 'created_at')
    list_filter = ('activity',)
