from django.urls import path

from . import views

urlpatterns = [
    path("", views.MemberListView.as_view(), name="members"),
    path("bureau/", views.BureauView.as_view(), name="members-bureau"),
    path("<int:pk>/", views.MemberDetailView.as_view(), name="member-detail"),
    path("<int:pk>/reset-pin/", views.ResetPinView.as_view(), name="member-reset-pin"),
]
