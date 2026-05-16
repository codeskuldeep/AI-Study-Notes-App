from django.urls import path
from . import views

urlpatterns = [
    path('dashboard/', views.DashboardView.as_view(), name='dashboard'),
    path('study-history/', views.StudyHistoryView.as_view(), name='study-history'),
    path('weak-topics/', views.WeakTopicsView.as_view(), name='weak-topics'),
]
