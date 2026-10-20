"""
Back-office session rules.

A back-office session is a Django session that has passed *both* factors:
password, then an SMS code (or a trusted-device cookie less than 30 days
old). Each page also needs its own permission from the role matrix — a
member with no back-office permission can't get in even with the right
password.
"""

from functools import wraps

from django.conf import settings
from django.core import signing
from django.core.cache import cache
from django.shortcuts import redirect, render
from django.utils import timezone

from apps.core.audit import client_ip

SESSION_OTP_OK = "bo_otp_ok"
SESSION_PENDING = "bo_pending_user"
SESSION_SMS_OK = "bo_sms_ok"
TRUST_COOKIE = "bo_trust"
TRUST_SALT = "backoffice.trusted-device"

BACKOFFICE_PERMS = [("backoffice.users", "view"), ("backoffice.audit", "view")]


def can_enter(user):
    perms = user.permission_set()
    return any(p in perms for p in BACKOFFICE_PERMS)


def trust_token(user):
    # Tied to the password hash: changing the password revokes every
    # trusted device at once.
    return signing.dumps({"u": user.pk, "p": user.password[-12:]}, salt=TRUST_SALT)


def is_trusted(request, user):
    raw = request.COOKIES.get(TRUST_COOKIE)
    if not raw:
        return False
    try:
        data = signing.loads(raw, salt=TRUST_SALT, max_age=settings.BACKOFFICE_TRUST_DEVICE_DAYS * 86400)
    except signing.BadSignature:
        return False
    return data.get("u") == user.pk and data.get("p") == user.password[-12:]


def rate_limited(request, scope, limit, window=3600):
    """Small per-IP counter for the HTML login forms (DRF throttles only
    cover the API). Uses the same Redis cache."""
    key = f"bo-rl:{scope}:{client_ip(request)}"
    added = cache.add(key, 1, window)
    count = 1 if added else cache.incr(key)
    return count > limit


def backoffice_view(resource="backoffice.users", action="view"):
    def decorate(view):
        @wraps(view)
        def wrapper(request, *args, **kwargs):
            user = request.user
            if not user.is_authenticated or not request.session.get(SESSION_OTP_OK):
                return redirect("backoffice:login")
            # A session closed from "Sessions actives" ends here.
            from .models import BackofficeSession

            live = BackofficeSession.objects.filter(session_key=request.session.session_key)
            if not live.exists():
                from django.contrib.auth import logout

                logout(request)
                return redirect("backoffice:login")
            live.update(last_seen=timezone.now())
            if not user.can(resource, action):
                return render(request, "backoffice/forbidden.html", status=403)
            return view(request, *args, **kwargs)

        return wrapper

    return decorate
