from django.urls import path
from . import views

urlpatterns = [
    path('stats/', views.StatsView.as_view(), name='gamification-stats'),
    path('badges/', views.BadgesView.as_view(), name='badges'),
    path('xp-history/', views.XPHistoryView.as_view(), name='xp-history'),
    path('leaderboard/', views.LeaderboardView.as_view(), name='leaderboard'),
]
