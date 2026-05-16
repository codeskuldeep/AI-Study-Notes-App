import logging
import requests
from celery import shared_task
from django.conf import settings

logger = logging.getLogger(__name__)


def send_fcm_notification(fcm_token: str, title: str, body: str, data: dict = None):
    if not fcm_token or not settings.FCM_SERVER_KEY:
        return False
    try:
        response = requests.post(
            'https://fcm.googleapis.com/fcm/send',
            headers={
                'Authorization': f'key={settings.FCM_SERVER_KEY}',
                'Content-Type': 'application/json',
            },
            json={
                'to': fcm_token,
                'notification': {'title': title, 'body': body},
                'data': data or {},
            },
            timeout=10,
        )
        return response.status_code == 200
    except Exception as e:
        logger.error(f'FCM send failed: {e}')
        return False


@shared_task
def send_daily_reminders():
    from apps.authentication.models import User
    from .models import Notification
    from django.utils import timezone

    today = timezone.now().date()
    users = User.objects.filter(
        notification_enabled=True,
        fcm_token__gt='',
    ).exclude(last_activity_date=today)

    count = 0
    for user in users:
        title = 'Time to Study! 📚'
        body = f"Don't forget to study today! Keep your {user.streak_count}-day streak alive."
        notif = Notification.objects.create(
            user=user,
            notification_type='daily_reminder',
            title=title,
            body=body,
        )
        send_fcm_notification(user.fcm_token, title, body)
        count += 1

    logger.info(f'Sent daily reminders to {count} users')
    return count


@shared_task
def send_streak_warning(user_id: str):
    from apps.authentication.models import User
    from .models import Notification

    try:
        user = User.objects.get(id=user_id)
        if user.streak_count > 0:
            title = 'Streak at risk! 🔥'
            body = f'Study today to maintain your {user.streak_count}-day streak!'
            Notification.objects.create(
                user=user, notification_type='streak_reminder', title=title, body=body
            )
            send_fcm_notification(user.fcm_token, title, body)
    except Exception as e:
        logger.error(f'Streak warning failed: {e}')
