from .models import AuditLog


def client_ip(request):
    if request is None:
        return None
    forwarded = request.META.get("HTTP_X_FORWARDED_FOR")
    if forwarded:
        return forwarded.split(",")[0].strip()
    return request.META.get("REMOTE_ADDR")


def record(action, *, actor=None, obj=None, request=None, detail=None, sensitive=False, refused=False):
    return AuditLog.objects.create(
        actor=actor if actor is not None and actor.is_authenticated else None,
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
