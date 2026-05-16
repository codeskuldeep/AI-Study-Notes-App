from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from .models import User, EmailVerificationToken, PasswordResetToken


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    list_display = ('email', 'username', 'full_name', 'is_email_verified', 'xp', 'streak_count', 'date_joined')
    list_filter = ('is_active', 'is_staff', 'is_email_verified')
    search_fields = ('email', 'username', 'full_name')
    ordering = ('-date_joined',)
    readonly_fields = ('id', 'date_joined', 'last_login')

    fieldsets = (
        (None, {'fields': ('id', 'email', 'password')}),
        ('Personal Info', {'fields': ('username', 'full_name', 'avatar', 'bio')}),
        ('Gamification', {'fields': ('xp', 'level', 'streak_count', 'longest_streak', 'last_activity_date')}),
        ('Preferences', {'fields': ('study_goal_minutes', 'preferred_subjects', 'notification_enabled')}),
        ('Auth', {'fields': ('is_active', 'is_staff', 'is_superuser', 'is_email_verified', 'google_id')}),
        ('Timestamps', {'fields': ('date_joined', 'last_login')}),
    )
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('email', 'password1', 'password2'),
        }),
    )


@admin.register(EmailVerificationToken)
class EmailVerificationTokenAdmin(admin.ModelAdmin):
    list_display = ('user', 'token', 'created_at', 'expires_at')
    readonly_fields = ('token', 'created_at')


@admin.register(PasswordResetToken)
class PasswordResetTokenAdmin(admin.ModelAdmin):
    list_display = ('user', 'is_used', 'created_at', 'expires_at')
    readonly_fields = ('token', 'created_at')
