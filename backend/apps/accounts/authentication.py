from rest_framework import exceptions
from rest_framework_simplejwt.authentication import JWTAuthentication

from apps.core.groups import set_current_group

BACKOFFICE_ONLY = "Les comptes du back-office (super admin, équipes support, IT, intégrations) s’utilisent uniquement sur le back-office."
NOT_IN_GROUP = "Vous n’êtes pas membre de ce groupe."
NO_GROUP = "Ce compte n’appartient encore à aucun groupe."
OTHER_DEVICE = "Votre compte a été ouvert sur un autre téléphone : celui-ci est déconnecté. Reconnectez-vous avec votre code PIN si c’est bien vous."


def other_device():
    return exceptions.AuthenticationFailed({"detail": OTHER_DEVICE, "code": "other_device"})


class AppJWTAuthentication(JWTAuthentication):
    """The app's token check, plus:

    - a super admin account works only in the web back-office, never in the
      mobile app (owner, 2026-10-23); this also ends any app session opened
      before the account became super admin;
    - one phone at a time: a token from a phone signed out by a newer
      sign-in is refused with `other_device` (owner, 2026-10-30);
    - every request works inside one group: the one named in the `X-Group`
      header, which must be one of the member's, or else their first group.
    """

    def authenticate(self, request):
        result = super().authenticate(request)
        if result is None:
            return None
        user, token = result
        groups = user.groups_joined()
        wanted = request.META.get("HTTP_X_GROUP", "").strip()
        if wanted:
            group = groups.filter(pk=int(wanted)).first() if wanted.isdigit() else None
            if group is None:
                raise exceptions.PermissionDenied({"detail": NOT_IN_GROUP, "code": "not_in_group"})
        else:
            group = groups.first()
            if group is None:
                raise exceptions.PermissionDenied({"detail": NO_GROUP, "code": "no_group"})
        set_current_group(group.pk)
        request.group = group
        return user, token

    def get_user(self, validated_token):
        user = super().get_user(validated_token)
        if user.is_platform_account:
            raise exceptions.PermissionDenied({"detail": BACKOFFICE_ONLY, "code": "backoffice_only"})
        from .services import session_ended

        if session_ended(user, validated_token):
            raise other_device()
        return user
