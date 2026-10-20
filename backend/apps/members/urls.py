from django.urls import path

from . import views

urlpatterns = [
    path("", views.MemberListView.as_view(), name="members"),
    path("bureau/", views.BureauView.as_view(), name="members-bureau"),
    path("requestable-roles/", views.RequestableRolesView.as_view(), name="requestable-roles"),
    path("<int:pk>/role-requests/", views.RoleRequestView.as_view(), name="member-role-request"),
    path("<int:pk>/", views.MemberDetailView.as_view(), name="member-detail"),
    path("<int:pk>/reset-pin/", views.ResetPinView.as_view(), name="member-reset-pin"),
]
