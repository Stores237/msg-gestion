from rest_framework import exceptions
from rest_framework_simplejwt.authentication import JWTAuthentication

BACKOFFICE_ONLY = "Les comptes super admin s’utilisent uniquement sur le back-office."


class AppJWTAuthentication(JWTAuthentication):
    """The app's token check, plus: a super admin account works only in the
    web back-office, never in the mobile app (owner, 2026-10-23). Also ends
    any app session opened before the account became super admin."""

    def get_user(self, validated_token):
        user = super().get_user(validated_token)
        if user.is_super_admin:
            raise exceptions.PermissionDenied({"detail": BACKOFFICE_ONLY, "code": "backoffice_only"})
        return user
