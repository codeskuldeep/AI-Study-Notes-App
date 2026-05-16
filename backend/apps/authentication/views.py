import logging
from rest_framework import generics, status, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.views import TokenRefreshView
from rest_framework_simplejwt.exceptions import TokenError
from drf_spectacular.utils import extend_schema, OpenApiResponse

from core.mixins import SuccessResponseMixin
from .serializers import (
    UserRegistrationSerializer, UserLoginSerializer, UserProfileSerializer,
    UserProfileUpdateSerializer, PasswordChangeSerializer, ForgotPasswordSerializer,
    ResetPasswordSerializer, GoogleAuthSerializer, TokenResponseSerializer,
    FCMTokenUpdateSerializer,
)
from .services import AuthService

logger = logging.getLogger(__name__)


class RegisterView(SuccessResponseMixin, generics.CreateAPIView):
    permission_classes = [permissions.AllowAny]
    serializer_class = UserRegistrationSerializer

    @extend_schema(responses={201: TokenResponseSerializer})
    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = AuthService.create_user(**serializer.validated_data)
        tokens = TokenResponseSerializer.get_tokens_for_user(user)
        return self.created_response(data=tokens, message='Account created successfully.')


class LoginView(SuccessResponseMixin, generics.GenericAPIView):
    permission_classes = [permissions.AllowAny]
    serializer_class = UserLoginSerializer

    def post(self, request):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.validated_data['user']

        if fcm_token := serializer.validated_data.get('fcm_token'):
            user.fcm_token = fcm_token
            user.save(update_fields=['fcm_token'])

        user.update_streak()
        tokens = TokenResponseSerializer.get_tokens_for_user(user)
        return self.success_response(data=tokens, message='Login successful.')


class LogoutView(SuccessResponseMixin, generics.GenericAPIView):
    def post(self, request):
        try:
            refresh_token = request.data.get('refresh')
            if refresh_token:
                token = RefreshToken(refresh_token)
                token.blacklist()
        except TokenError:
            pass
        return self.success_response(message='Logged out successfully.')


class TokenRefreshViewExtended(SuccessResponseMixin, TokenRefreshView):
    pass


class ProfileView(SuccessResponseMixin, generics.RetrieveUpdateAPIView):
    serializer_class = UserProfileSerializer

    def get_object(self):
        return self.request.user

    def get_serializer_class(self):
        if self.request.method in ('PUT', 'PATCH'):
            return UserProfileUpdateSerializer
        return UserProfileSerializer

    def retrieve(self, request, *args, **kwargs):
        serializer = UserProfileSerializer(self.get_object())
        return self.success_response(data=serializer.data)

    def update(self, request, *args, **kwargs):
        partial = kwargs.pop('partial', False)
        serializer = UserProfileUpdateSerializer(
            self.get_object(), data=request.data, partial=partial, context={'request': request}
        )
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return self.success_response(
            data=UserProfileSerializer(self.get_object()).data,
            message='Profile updated successfully.'
        )


class ChangePasswordView(SuccessResponseMixin, generics.GenericAPIView):
    serializer_class = PasswordChangeSerializer

    def post(self, request):
        serializer = self.get_serializer(data=request.data, context={'request': request})
        serializer.is_valid(raise_exception=True)
        request.user.set_password(serializer.validated_data['new_password'])
        request.user.save(update_fields=['password'])
        return self.success_response(message='Password changed successfully.')


class ForgotPasswordView(SuccessResponseMixin, generics.GenericAPIView):
    permission_classes = [permissions.AllowAny]
    serializer_class = ForgotPasswordSerializer

    def post(self, request):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        AuthService.initiate_password_reset(serializer.validated_data['email'])
        return self.success_response(
            message='If this email exists, you will receive a password reset link.'
        )


class ResetPasswordView(SuccessResponseMixin, generics.GenericAPIView):
    permission_classes = [permissions.AllowAny]
    serializer_class = ResetPasswordSerializer

    def post(self, request):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        success = AuthService.reset_password(
            str(serializer.validated_data['token']),
            serializer.validated_data['new_password'],
        )
        if not success:
            return Response(
                {'success': False, 'error': {'message': 'Invalid or expired reset token.'}},
                status=status.HTTP_400_BAD_REQUEST,
            )
        return self.success_response(message='Password reset successfully.')


class VerifyEmailView(SuccessResponseMixin, generics.GenericAPIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request, token):
        success = AuthService.verify_email(str(token))
        if not success:
            return Response(
                {'success': False, 'error': {'message': 'Invalid or expired verification token.'}},
                status=status.HTTP_400_BAD_REQUEST,
            )
        return self.success_response(message='Email verified successfully.')


class GoogleAuthView(SuccessResponseMixin, generics.GenericAPIView):
    permission_classes = [permissions.AllowAny]
    serializer_class = GoogleAuthSerializer

    def post(self, request):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            user = AuthService.google_authenticate(serializer.validated_data['id_token'])
        except ValueError as e:
            return Response(
                {'success': False, 'error': {'message': str(e)}},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if fcm_token := serializer.validated_data.get('fcm_token'):
            user.fcm_token = fcm_token
            user.save(update_fields=['fcm_token'])

        user.update_streak()
        tokens = TokenResponseSerializer.get_tokens_for_user(user)
        return self.success_response(data=tokens, message='Google authentication successful.')


class UpdateFCMTokenView(SuccessResponseMixin, generics.GenericAPIView):
    serializer_class = FCMTokenUpdateSerializer

    def post(self, request):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        request.user.fcm_token = serializer.validated_data['fcm_token']
        request.user.save(update_fields=['fcm_token'])
        return self.success_response(message='FCM token updated.')
