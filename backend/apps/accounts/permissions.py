from rest_framework.permissions import BasePermission


def require(resource, action):
    """DRF permission class: the request user's roles grant resource:action."""

    class _Require(BasePermission):
        message = "Votre rôle ne donne pas accès à cette action."

        def has_permission(self, request, view):
            return bool(request.user and request.user.is_authenticated and request.user.can(resource, action))

    _Require.__name__ = f"Require_{resource}_{action}".replace(".", "_")
    return _Require
