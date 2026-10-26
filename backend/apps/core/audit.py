from .groups import current_group_id
from .models import AuditLog


def client_ip(request):
    """The caller's address, for rate limits and the audit log.

    Never the left part of X-Forwarded-For: the client writes it, so a
    script could pick a new address per request and walk past every rate
    limit (security check, 2026-10-26). On Render the request comes
    through Cloudflare, which sets CF-Connecting-IP itself
    (CLIENT_IP_HEADER); otherwise the last X-Forwarded-For entry, added
    by the proxy in front of us; otherwise the socket address.
    """
    from django.conf import settings

    if request is None:
        return None
    header = getattr(settings, "CLIENT_IP_HEADER", "")
    if header and request.META.get(header):
        return request.META[header].strip()
    forwarded = request.META.get("HTTP_X_FORWARDED_FOR")
    if forwarded:
        return forwarded.split(",")[-1].strip()
    return request.META.get("REMOTE_ADDR")


def record(action, *, actor=None, obj=None, request=None, detail=None, sensitive=False, refused=False, platform=False):
    """platform=True: an action on the platform itself (groups, super
    admins), not inside the current group."""
    return AuditLog.objects.create(
        actor=actor if actor is not None and actor.is_authenticated else None,
        group_id=None if platform else current_group_id(),
        action=action,
        object_type=obj._meta.model_name if obj is not None else "",
        object_id=str(obj.pk) if obj is not None else "",
        object_repr=str(obj)[:200] if obj is not None else "",
        detail=detail or {},
        sensitive=sensitive,
        refused=refused,
        ip=client_ip(request),
        device=(request.META.get("HTTP_USER_AGENT", "") if request is not None else "")[:200],
    )
