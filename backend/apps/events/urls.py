from django.urls import path

from . import views

urlpatterns = [
    path("", views.EventListView.as_view(), name="events"),
    path("<int:pk>/", views.EventDetailView.as_view(), name="event-detail"),
    path("<int:pk>/attendance/", views.AttendanceView.as_view(), name="event-attendance"),
    path("<int:pk>/report/", views.EventReportView.as_view(), name="event-report"),
    path("<int:pk>/excuse/", views.ExcuseView.as_view(), name="event-excuse"),
]
