import os

from .base import *  # noqa: F401,F403
from .base import ALLOWED_HOSTS, BASE_DIR, DATABASES, MIDDLEWARE, STORAGES

DEBUG = False
SECURE_SSL_REDIRECT = True
# Render terminates TLS at its proxy; without this every request looks
# like plain HTTP and SECURE_SSL_REDIRECT loops forever.
SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
SECURE_HSTS_SECONDS = 60 * 60 * 24 * 30
# /healthz/ is hit over plain HTTP by Render's own health checker.
SECURE_REDIRECT_EXEMPT = [r"^healthz/$"]

# Render assigns the hostname on first deploy; it isn't known before.
RENDER_HOST = os.getenv("RENDER_EXTERNAL_HOSTNAME")
if RENDER_HOST:
    ALLOWED_HOSTS = [*ALLOWED_HOSTS, RENDER_HOST]
    CSRF_TRUSTED_ORIGINS = [f"https://{RENDER_HOST}"]

# WhiteNoise: free-tier Render has no separate static host/CDN, so the
# back-office CSS and admin assets are served by the Django process itself.
MIDDLEWARE = list(MIDDLEWARE)
MIDDLEWARE.insert(
    MIDDLEWARE.index("django.middleware.security.SecurityMiddleware") + 1,
    "whitenoise.middleware.WhiteNoiseMiddleware",
)
STATIC_ROOT = BASE_DIR / "staticfiles"
STORAGES = {
    **STORAGES,
    "staticfiles": {"BACKEND": "whitenoise.storage.CompressedManifestStaticFilesStorage"},
}

# The Supabase pooler runs in transaction mode: persistent connections and
# server-side cursors don't survive it.
DATABASES["default"]["CONN_MAX_AGE"] = 0
DATABASES["default"]["DISABLE_SERVER_SIDE_CURSORS"] = True
# psycopg 3 prepares a statement server-side after 5 runs; through a
# transaction-mode pooler the next run can land on a different backend
# connection that never saw it ("prepared statement does not exist").
DATABASES["default"].setdefault("OPTIONS", {})["prepare_threshold"] = None
