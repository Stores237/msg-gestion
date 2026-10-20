from django.urls import path

from . import views

app_name = "backoffice"

urlpatterns = [
    path("", views.dashboard, name="dashboard"),
    path("connexion/", views.login_view, name="login"),
    path("connexion/code/", views.otp_view, name="otp"),
    path("deconnexion/", views.logout_view, name="logout"),
    path("utilisateurs/", views.users, name="users"),
    path("roles/", views.roles, name="roles"),
    path("roles/<slug:slug>/", views.roles, name="role"),
    path("journal/", views.audit_log, name="audit"),
]
