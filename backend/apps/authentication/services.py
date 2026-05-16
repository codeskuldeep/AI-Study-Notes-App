import logging
import uuid
from datetime import timedelta

from django.conf import settings
from django.core.mail import send_mail
from django.utils import timezone
from google.oauth2 import id_token
from google.auth.transport import requests as google_requests

from .models import User, EmailVerificationToken, PasswordResetToken

logger = logging.getLogger(__name__)


class AuthService:
    @staticmethod
    def create_user(email: str, full_name: str, username: str, password: str) -> User:
        if not username:
            base = email.split('@')[0]
            username = base
            counter = 1
            while User.objects.filter(username=username).exists():
                username = f"{base}{counter}"
                counter += 1

        user = User.objects.create_user(
            email=email,
            full_name=full_name,
            username=username,
            password=password,
        )
        AuthService.send_verification_email(user)
        return user

    @staticmethod
    def send_verification_email(user: User):
        token, _ = EmailVerificationToken.objects.update_or_create(
            user=user,
            defaults={
                'token': uuid.uuid4(),
                'expires_at': timezone.now() + timedelta(hours=24),
            }
        )
        verification_url = f"{settings.FRONTEND_URL}/verify-email/{token.token}"
        try:
            send_mail(
                subject='Verify your AI Study Notes account',
                message=f'Click here to verify your email: {verification_url}',
                from_email=settings.DEFAULT_FROM_EMAIL,
                recipient_list=[user.email],
                fail_silently=True,
            )
        except Exception as e:
            logger.warning(f'Failed to send verification email to {user.email}: {e}')

    @staticmethod
    def verify_email(token_str: str) -> bool:
        try:
            token = EmailVerificationToken.objects.select_related('user').get(token=token_str)
            if not token.is_valid():
                return False
            token.user.is_email_verified = True
            token.user.save(update_fields=['is_email_verified'])
            token.delete()
            return True
        except EmailVerificationToken.DoesNotExist:
            return False

    @staticmethod
    def initiate_password_reset(email: str):
        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            return  # Silently ignore - don't reveal if email exists

        token = PasswordResetToken.objects.create(
            user=user,
            expires_at=timezone.now() + timedelta(hours=2),
        )
        reset_url = f"{settings.FRONTEND_URL}/reset-password/{token.token}"
        try:
            send_mail(
                subject='Reset your AI Study Notes password',
                message=f'Click here to reset your password: {reset_url}\n\nThis link expires in 2 hours.',
                from_email=settings.DEFAULT_FROM_EMAIL,
                recipient_list=[user.email],
                fail_silently=True,
            )
        except Exception as e:
            logger.warning(f'Failed to send password reset email: {e}')

    @staticmethod
    def reset_password(token_str: str, new_password: str) -> bool:
        try:
            token = PasswordResetToken.objects.select_related('user').get(token=token_str)
            if not token.is_valid():
                return False
            token.user.set_password(new_password)
            token.user.save(update_fields=['password'])
            token.is_used = True
            token.save(update_fields=['is_used'])
            return True
        except PasswordResetToken.DoesNotExist:
            return False

    @staticmethod
    def google_authenticate(id_token_str: str) -> User:
        try:
            id_info = id_token.verify_oauth2_token(
                id_token_str,
                google_requests.Request(),
                settings.SOCIAL_AUTH_GOOGLE_OAUTH2_KEY,
            )
        except ValueError as e:
            raise ValueError(f'Invalid Google token: {e}')

        google_id = id_info['sub']
        email = id_info.get('email', '')
        full_name = id_info.get('name', '')

        user = User.objects.filter(google_id=google_id).first()
        if user:
            return user

        user = User.objects.filter(email=email).first()
        if user:
            user.google_id = google_id
            user.is_email_verified = True
            user.save(update_fields=['google_id', 'is_email_verified'])
            return user

        base_username = email.split('@')[0]
        username = base_username
        counter = 1
        while User.objects.filter(username=username).exists():
            username = f"{base_username}{counter}"
            counter += 1

        user = User.objects.create_user(
            email=email,
            full_name=full_name,
            username=username,
            google_id=google_id,
            is_email_verified=True,
        )
        return user
