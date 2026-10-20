from django.urls import path

from . import views

urlpatterns = [
    path("", views.AnnouncementListView.as_view(), name="announcements"),
    path("<int:pk>/", views.AnnouncementDetailView.as_view(), name="announcement-detail"),
    path("<int:pk>/read/", views.MarkReadView.as_view(), name="announcement-read"),
    path("<int:pk>/reads/", views.ReadReceiptsView.as_view(), name="announcement-reads"),
    path("<int:pk>/attachments/", views.AttachmentUploadView.as_view(), name="announcement-attachments"),
    path("<int:pk>/attachments/<int:att_pk>/", views.AttachmentDeleteView.as_view(), name="announcement-attachment"),
]
