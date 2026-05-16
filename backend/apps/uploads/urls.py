from django.urls import path
from . import views

urlpatterns = [
    path('', views.UploadListCreateView.as_view(), name='upload-list-create'),
    path('<uuid:pk>/', views.UploadDetailView.as_view(), name='upload-detail'),
]
