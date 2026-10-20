from .base import *  # noqa: F401,F403

DEBUG = True
ALLOWED_HOSTS = ["*"]
EMAIL_BACKEND = "django.core.mail.backends.console.EmailBackend"
# Log back-office 2FA codes instead of sending them when Twilio is unset.
# Its own flag rather than DEBUG: pytest-django forces DEBUG off.
SMS_DEV_FALLBACK = True
