from django.urls import path

from . import views

urlpatterns = [
    path("auth/phone/", views.PhoneLookupView.as_view(), name="auth-phone"),
    path("auth/login/", views.PinLoginView.as_view(), name="auth-login"),
    path("auth/refresh/", views.ThrottledTokenRefreshView.as_view(), name="auth-refresh"),
    path("auth/logout/", views.LogoutView.as_view(), name="auth-logout"),
    path("me/", views.MeView.as_view(), name="me"),
]
