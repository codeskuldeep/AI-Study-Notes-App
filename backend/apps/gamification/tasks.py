import logging
from celery import shared_task
from django.db import models

logger = logging.getLogger(__name__)


@shared_task
def check_and_update_streaks():
    from django.utils import timezone
    from apps.authentication.models import User
    from .models import Leaderboard

    yesterday = timezone.now().date() - timezone.timedelta(days=1)
    users_with_broken_streaks = User.objects.filter(
        streak_count__gt=0,
        last_activity_date__lt=yesterday,
    )
    count = users_with_broken_streaks.update(streak_count=0)
    logger.info(f'Reset streaks for {count} users')


@shared_task
def update_leaderboards():
    from apps.authentication.models import User
    from .models import Leaderboard
    from django.utils import timezone

    now = timezone.now()
    week_start = now - timezone.timedelta(days=7)
    month_start = now - timezone.timedelta(days=30)

    from apps.gamification.models import XPTransaction

    for period, start_date in [('weekly', week_start), ('monthly', month_start)]:
        user_xp = (
            XPTransaction.objects
            .filter(created_at__gte=start_date)
            .values('user')
            .annotate(total_xp=models.Sum('xp_earned'))
            .order_by('-total_xp')
        )
        for rank, entry in enumerate(user_xp, start=1):
            Leaderboard.objects.update_or_create(
                user_id=entry['user'],
                period=period,
                defaults={'rank': rank, 'xp': entry['total_xp']},
            )

    alltime_users = User.objects.order_by('-xp')
    for rank, user in enumerate(alltime_users, start=1):
        Leaderboard.objects.update_or_create(
            user=user,
            period='alltime',
            defaults={'rank': rank, 'xp': user.xp},
        )

    logger.info('Leaderboards updated')
