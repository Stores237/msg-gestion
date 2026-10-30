from django.urls import path

from apps.members.views import MyPhotoView

from . import views

urlpatterns = [
    path("auth/phone/", views.PhoneLookupView.as_view(), name="auth-phone"),
    path("auth/terms/", views.TermsView.as_view(), name="auth-terms"),
    path("auth/login/", views.PinLoginView.as_view(), name="auth-login"),
    path("auth/refresh/", views.ThrottledTokenRefreshView.as_view(), name="auth-refresh"),
    path("auth/logout/", views.LogoutView.as_view(), name="auth-logout"),
    path("auth/pin/change/", views.ChangePinView.as_view(), name="pin-change"),
    path("auth/finance-code/", views.FinanceCodeView.as_view(), name="finance-code"),
    path("auth/finance-code/check/", views.FinanceCodeCheckView.as_view(), name="finance-code-check"),
    path("auth/pin/forgot/", views.ForgotPinView.as_view(), name="pin-forgot"),
    path("auth/pin/forgot/confirm/", views.ForgotPinConfirmView.as_view(), name="pin-forgot-confirm"),
    path("me/", views.MeView.as_view(), name="me"),
    path("me/preferences/", views.PreferencesView.as_view(), name="me-preferences"),
    path("me/photo/", MyPhotoView.as_view(), name="me-photo"),
]
