"""
One-time codes for the back-office second factor.

With Twilio Verify configured, Twilio generates, sends and checks the code.
Without it, a code is generated here, stored hashed in the cache, and only
*logged* — only with SMS_DEV_FALLBACK on (dev settings). Otherwise it is
refused, so production can never silently "send" a code nobody receives.
"""

import logging
import secrets

import requests
from django.conf import settings
from django.contrib.auth.hashers import check_password, make_password
from django.core.cache import cache

log = logging.getLogger(__name__)

CODE_TTL_SECONDS = 5 * 60
_TIMEOUT = 15


class SmsUnavailable(Exception):
    pass


def _twilio_configured():
    return all(
        [
            settings.TWILIO_ACCOUNT_SID,
            settings.TWILIO_API_KEY_SID,
            settings.TWILIO_API_KEY_SECRET,
            settings.TWILIO_VERIFY_SERVICE_SID,
        ]
    )


def _verify_url(path):
    return f"https://verify.twilio.com/v2/Services/{settings.TWILIO_VERIFY_SERVICE_SID}/{path}"


def _auth():
    return (settings.TWILIO_API_KEY_SID, settings.TWILIO_API_KEY_SECRET)


def _cache_key(phone):
    return f"otp:{phone}"


def send_code(phone):
    if _twilio_configured():
        resp = requests.post(_verify_url("Verifications"), data={"To": phone, "Channel": "sms"}, auth=_auth(), timeout=_TIMEOUT)
        if resp.status_code >= 400:
            # Keep the real body: an exception string that drops it is
            # exactly what made the Spekooh S3 outage take five PRs.
            raise SmsUnavailable(f"Twilio Verify {resp.status_code}: {resp.text[:500]}")
        return
    if not settings.SMS_DEV_FALLBACK:
        raise SmsUnavailable("Aucun fournisseur SMS configuré (TWILIO_*).")
    code = f"{secrets.randbelow(10**6):06d}"
    cache.set(_cache_key(phone), make_password(code), CODE_TTL_SECONDS)
    log.warning("DEV ONLY — code de vérification pour %s : %s", phone, code)


def check_code(phone, code):
    code = (code or "").strip()
    if not code.isdigit():
        return False
    if _twilio_configured():
        resp = requests.post(_verify_url("VerificationCheck"), data={"To": phone, "Code": code}, auth=_auth(), timeout=_TIMEOUT)
        if resp.status_code == 404:  # expired or already used
            return False
        if resp.status_code >= 400:
            raise SmsUnavailable(f"Twilio Verify {resp.status_code}: {resp.text[:500]}")
        return resp.json().get("status") == "approved"
    stored = cache.get(_cache_key(phone))
    if stored and check_password(code, stored):
        cache.delete(_cache_key(phone))
        return True
    return False
