from .models import Notification


def notify(users, kind, title, body="", target=None):
    """Create one notification per user (deduplicated)."""
    seen, rows = set(), []
    for u in users:
        if u is None or u.pk in seen:
            continue
        seen.add(u.pk)
        rows.append(Notification(user=u, kind=kind, title=title[:160], body=body[:300], target=target or {}))
    Notification.objects.bulk_create(rows)
    return len(rows)
