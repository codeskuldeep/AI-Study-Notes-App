from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView, SpectacularRedocView

urlpatterns = [
    path('admin/', admin.site.urls),

    # API v1
    path('api/v1/auth/', include('apps.authentication.urls')),
    path('api/v1/notes/', include('apps.notes.urls')),
    path('api/v1/uploads/', include('apps.uploads.urls')),
    path('api/v1/quizzes/', include('apps.quizzes.urls')),
    path('api/v1/flashcards/', include('apps.flashcards.urls')),
    path('api/v1/ai-tutor/', include('apps.ai_tutor.urls')),
    path('api/v1/analytics/', include('apps.analytics.urls')),
    path('api/v1/gamification/', include('apps.gamification.urls')),
    path('api/v1/notifications/', include('apps.notifications.urls')),

    # Social auth
    path('social-auth/', include('social_django.urls', namespace='social')),

    # API Schema
    path('api/schema/', SpectacularAPIView.as_view(), name='schema'),
    path('api/docs/', SpectacularSwaggerView.as_view(url_name='schema'), name='swagger-ui'),
    path('api/redoc/', SpectacularRedocView.as_view(url_name='schema'), name='redoc'),

    # Health check
    path('health/', include('health_check.urls')),
]

if settings.DEBUG:
    try:
        import debug_toolbar
        urlpatterns = [path('__debug__/', include(debug_toolbar.urls))] + urlpatterns
    except ImportError:
        pass
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
