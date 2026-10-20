from django.urls import path

from . import views, views_admin

app_name = "backoffice"

urlpatterns = [
    path("", views.dashboard, name="dashboard"),
    path("connexion/", views.login_view, name="login"),
    path("connexion/code/", views.otp_view, name="otp"),
    path("deconnexion/", views.logout_view, name="logout"),
    path("securite/", views_admin.security, name="security"),
    path("utilisateurs/", views.users, name="users"),
    path("utilisateurs/nouveau/", views_admin.user_new, name="user_new"),
    path("utilisateurs/import/", views_admin.users_import, name="users_import"),
    path("utilisateurs/actions/", views_admin.users_bulk, name="users_bulk"),
    path("utilisateurs/export.csv", views_admin.users_export, name="users_export"),
    path("utilisateurs/<int:pk>/", views_admin.user_detail, name="user"),
    path("affectations/", views_admin.assignments, name="assignments"),
    path("affectations/<int:pk>/renouveler/", views_admin.assignment_renew, name="assignment_renew"),
    path("demandes/<int:pk>/", views_admin.role_request_decide, name="role_request"),
    path("roles/", views.roles, name="roles"),
    path("roles/nouveau/", views_admin.role_manage, name="role_new"),
    path("roles/<slug:slug>/", views.roles, name="role"),
    path("roles/<slug:slug>/gerer/", views_admin.role_manage, name="role_manage"),
    path("parametres/", views_admin.settings_view, name="settings"),
    path("journal/", views.audit_log, name="audit"),
    path("journal/export.csv", views_admin.audit_export, name="audit_export"),
]
