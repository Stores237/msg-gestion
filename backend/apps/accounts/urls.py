from django.urls import path

from . import views

urlpatterns = [
    path("auth/phone/", views.PhoneLookupView.as_view(), name="auth-phone"),
    path("auth/login/", views.PinLoginView.as_view(), name="auth-login"),
    path("auth/refresh/", views.ThrottledTokenRefreshView.as_view(), name="auth-refresh"),
    path("auth/logout/", views.LogoutView.as_view(), name="auth-logout"),
    path("auth/pin/change/", views.ChangePinView.as_view(), name="pin-change"),
    path("auth/pin/forgot/", views.ForgotPinView.as_view(), name="pin-forgot"),
    path("auth/pin/forgot/confirm/", views.ForgotPinConfirmView.as_view(), name="pin-forgot-confirm"),
    path("me/", views.MeView.as_view(), name="me"),
]
