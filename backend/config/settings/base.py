"""
Shared settings for every environment. dev.py / prod.py layer on top.

Every value has a safe fallback so a fresh clone with zero env vars still
runs (`manage.py check`, the test suite) — see RUNNING_LOCALLY.md.
"""

from datetime import timedelta
from pathlib import Path

import environ
import sentry_sdk
from botocore.config import Config as BotoConfig
from sentry_sdk.integrations.django import DjangoIntegration

BASE_DIR = Path(__file__).resolve().parent.parent.parent

env = environ.Env()
environ.Env.read_env(BASE_DIR / ".env")

SECRET_KEY = env("DJANGO_SECRET_KEY", default="dev-secret-key-change-me-please-at-least-32-bytes-long")
DEBUG = env.bool("DJANGO_DEBUG", default=False)
ALLOWED_HOSTS = env.list("DJANGO_ALLOWED_HOSTS", default=[])

# No-op when SENTRY_DSN is unset. trace_propagation_targets=[] is not
# optional: sentry-sdk's Boto3 integration otherwise injects sentry-trace/
# baggage headers into boto3's own SigV4-signed S3 calls during an active
# transaction, and every write to Supabase Storage fails with an
# unparseable SignatureDoesNotMatch (Spekooh outage, see the playbook §7).
sentry_sdk.init(
    dsn=env("SENTRY_DSN", default=None),
    integrations=[DjangoIntegration()],
    environment=env("SENTRY_ENVIRONMENT", default="development" if DEBUG else "production"),
    traces_sample_rate=0.1,
    send_default_pii=False,
    trace_propagation_targets=[],
)

# Error visibility is a prerequisite for debugging anything live (playbook
# §6): with DEBUG=False, unhandled exceptions go to stderr (Render's log
# tab) and to every address in DJANGO_ADMIN_EMAILS. The "django" logger is
# re-declared here, not just the handlers — dictConfig only relinks a
# logger to a same-named handler if the logger itself is in the same call.
ADMINS = [(email, email) for email in env.list("DJANGO_ADMIN_EMAILS", default=[])]
LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "filters": {
        "require_debug_false": {"()": "django.utils.log.RequireDebugFalse"},
    },
    "handlers": {
        "console": {"level": "INFO", "class": "logging.StreamHandler"},
        "mail_admins": {
            "level": "ERROR",
            "filters": ["require_debug_false"],
            "class": "django.utils.log.AdminEmailHandler",
        },
    },
    "loggers": {
        "django": {"handlers": ["console", "mail_admins"], "level": "INFO"},
        "apps": {"handlers": ["console"], "level": "INFO", "propagate": False},
    },
}

INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    "rest_framework",
    "rest_framework_simplejwt",
    "rest_framework_simplejwt.token_blacklist",
    "corsheaders",
    "django_filters",
    "drf_spectacular",
    "apps.core",
    "apps.accounts",
    "apps.backoffice",
    "apps.members",
    "apps.events",
    "apps.announcements",
    "apps.finances",
    "apps.planning",
]

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "corsheaders.middleware.CorsMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.locale.LocaleMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "config.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [BASE_DIR / "templates"],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

WSGI_APPLICATION = "config.wsgi.application"

# Postgres everywhere — local dev, CI and tests — never SQLite "for now"
# (playbook §3). Staging/production point this at their own Supabase
# project's pooler (port 6543, transaction mode), never a direct :5432
# connection that piles up across Render restarts.
DATABASES = {"default": env.db("DATABASE_URL", default="postgres://postgres@localhost:5432/msg")}

# Redis is required as soon as one throttled endpoint exists (login does):
# without a reachable cache, ScopedRateThrottle raises ConnectionError and
# every login 500s instead of returning 429 (playbook §7).
CACHES = {"default": env.cache("REDIS_URL", default="rediscache://localhost:6379/0")}

AUTH_USER_MODEL = "accounts.User"
LOGIN_URL = "backoffice:login"

AUTH_PASSWORD_VALIDATORS = [
    {"NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator"},
    {"NAME": "django.contrib.auth.password_validation.MinimumLengthValidator", "OPTIONS": {"min_length": 10}},
    {"NAME": "django.contrib.auth.password_validation.CommonPasswordValidator"},
    {"NAME": "django.contrib.auth.password_validation.NumericPasswordValidator"},
]

LANGUAGE_CODE = "fr"
LANGUAGES = [("fr", "Français"), ("en", "English")]
TIME_ZONE = "Africa/Douala"
USE_I18N = True
USE_TZ = True

STATIC_URL = "static/"
STATICFILES_DIRS = [BASE_DIR / "static"]
DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

MEDIA_URL = "/media/"
MEDIA_ROOT = BASE_DIR / "media"

# Local disk when AWS_STORAGE_BUCKET_NAME is unset, Supabase Storage (S3
# API) when it is — same FileField either way. signature_version lives
# inside the same Config as the checksum settings on purpose: django-
# storages ignores a separate top-level "signature_version" OPTIONS key as
# soon as client_config is set, and presigned URLs silently fall back to
# SigV2 (playbook §7). The checksum settings stop botocore's aws-chunked
# trailer envelope, which Supabase's S3 gateway rejects.
_aws_bucket = env("AWS_STORAGE_BUCKET_NAME", default=None)
STORAGES = {
    "default": (
        {
            "BACKEND": "storages.backends.s3.S3Storage",
            "OPTIONS": {
                "access_key": env("AWS_ACCESS_KEY_ID", default=None),
                "secret_key": env("AWS_SECRET_ACCESS_KEY", default=None),
                "bucket_name": _aws_bucket,
                "endpoint_url": env("AWS_S3_ENDPOINT_URL", default=None),
                "region_name": env("AWS_S3_REGION_NAME", default=None),
                "querystring_auth": True,
                "querystring_expire": 3600,
                "default_acl": None,
                "client_config": BotoConfig(
                    signature_version="s3v4",
                    request_checksum_calculation="when_required",
                    response_checksum_validation="when_required",
                ),
            },
        }
        if _aws_bucket
        else {"BACKEND": "django.core.files.storage.FileSystemStorage"}
    ),
    "staticfiles": {"BACKEND": "django.contrib.staticfiles.storage.StaticFilesStorage"},
}

REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": ("rest_framework_simplejwt.authentication.JWTAuthentication",),
    "DEFAULT_PERMISSION_CLASSES": ("rest_framework.permissions.IsAuthenticated",),
    "DEFAULT_FILTER_BACKENDS": ("django_filters.rest_framework.DjangoFilterBackend",),
    "DEFAULT_SCHEMA_CLASS": "drf_spectacular.openapi.AutoSchema",
    # Without this, a view's throttle_scope does nothing at all — caught
    # by test_login_is_throttled_with_429_not_500.
    "DEFAULT_THROTTLE_CLASSES": ("rest_framework.throttling.ScopedRateThrottle",),
    "DEFAULT_THROTTLE_RATES": {
        "phone_lookup": "30/hour",
        "pin_login": "30/hour",
        "pin_forgot": "10/hour",
        "token_refresh": "120/hour",
        "backoffice_login": "20/hour",
        "backoffice_otp": "20/hour",
    },
}

# Members stay logged in on their own phone for weeks (the app works
# offline between assises); the refresh token rotates on every use and the
# old one is blacklisted, so a stolen refresh token dies the first time
# either party uses it.
SIMPLE_JWT = {
    "ACCESS_TOKEN_LIFETIME": timedelta(minutes=15),
    "REFRESH_TOKEN_LIFETIME": timedelta(days=30),
    "ROTATE_REFRESH_TOKENS": True,
    "BLACKLIST_AFTER_ROTATION": True,
    "UPDATE_LAST_LOGIN": True,
}

SPECTACULAR_SETTINGS = {
    "TITLE": "MSG Gestion API",
    "DESCRIPTION": "Mouvement Garde Suisse, Notre-Dame de Lourdes de Yapoma — membres, caisse, calendrier, annonces.",
    "VERSION": "0.1.0",
}

CORS_ALLOW_ALL_ORIGINS = True

# PIN lockout (design: "Après 3 erreurs, le compte est bloqué 15 min").
PIN_MAX_ATTEMPTS = env.int("PIN_MAX_ATTEMPTS", default=3)
PIN_LOCKOUT_MINUTES = env.int("PIN_LOCKOUT_MINUTES", default=15)

# Back-office second factor. With Twilio Verify configured, codes go by
# SMS; without it, apps.core.sms falls back to a locally generated code
# that is only *logged* — and only when SMS_DEV_FALLBACK is on (dev.py
# turns it on; it is never on in prod.py). Otherwise sending a code raises
# instead of pretending it was delivered.
SMS_DEV_FALLBACK = False
TWILIO_ACCOUNT_SID = env("TWILIO_ACCOUNT_SID", default=None)
TWILIO_API_KEY_SID = env("TWILIO_API_KEY_SID", default=None)
TWILIO_API_KEY_SECRET = env("TWILIO_API_KEY_SECRET", default=None)
TWILIO_VERIFY_SERVICE_SID = env("TWILIO_VERIFY_SERVICE_SID", default=None)
BACKOFFICE_TRUST_DEVICE_DAYS = 30

# Staging-only stand-in for a scheduler (Render free tier has none):
# cron-job.org POSTs to /internal/tasks/<name>/ with this token. Unset =
# the endpoint answers 404 for everything. Production uses Render Cron Job
# services instead and never sets this (playbook §4).
TASK_TRIGGER_TOKEN = env("TASK_TRIGGER_TOKEN", default=None)

DEFAULT_FROM_EMAIL = env("DEFAULT_FROM_EMAIL", default="no-reply@msg-yapoma.cm")
EMAIL_BACKEND = env("EMAIL_BACKEND", default="django.core.mail.backends.smtp.EmailBackend")
EMAIL_HOST = env("EMAIL_HOST", default="localhost")
EMAIL_PORT = env.int("EMAIL_PORT", default=25)
EMAIL_HOST_USER = env("EMAIL_HOST_USER", default="")
EMAIL_HOST_PASSWORD = env("EMAIL_HOST_PASSWORD", default="")
EMAIL_USE_TLS = env.bool("EMAIL_USE_TLS", default=True)
