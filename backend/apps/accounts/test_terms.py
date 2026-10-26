"""Conditions d'utilisation checkbox at login (owner, 2026-10-26)."""

import pytest
from rest_framework.test import APIClient

from apps.core.models import AuditLog, PlatformSettings

from .factories import UserFactory

pytestmark = pytest.mark.django_db


def _login(**extra):
    return APIClient().post("/api/auth/login/", {"phone": "677452108", "pin": "4821", **extra}, format="json")


def test_terms_are_public_before_login():
    r = APIClient().get("/api/auth/terms/")
    assert r.status_code == 200
    body = r.json()
    assert body["terms_version"] == 1 and body["terms_text"] and body["privacy_text"]


def test_login_without_ticking_the_box_is_refused():
    user = UserFactory(phone="+237677452108", pin="4821")
    r = _login()
    assert r.status_code == 428
    assert r.json()["code"] == "terms_required" and r.json()["terms_version"] == 1
    assert "access" not in r.json()
    user.refresh_from_db()
    assert user.terms_version == 0 and user.terms_accepted_at is None


def test_a_wrong_pin_says_nothing_about_the_terms():
    UserFactory(phone="+237677452108", pin="4821")
    r = APIClient().post("/api/auth/login/", {"phone": "677452108", "pin": "0000"}, format="json")
    assert r.status_code == 401 and r.json()["code"] == "wrong_pin"


def test_ticking_the_box_records_the_acceptance_once():
    user = UserFactory(phone="+237677452108", pin="4821")
    assert _login(accept_terms=True, terms_version=1).status_code == 200
    user.refresh_from_db()
    assert user.terms_version == 1 and user.terms_accepted_at is not None
    assert AuditLog.objects.filter(action="Conditions d’utilisation acceptées", object_id=str(user.pk)).count() == 1
    # Accepted already: the next login goes through without re-recording.
    assert _login().status_code == 200
    assert AuditLog.objects.filter(action="Conditions d’utilisation acceptées").count() == 1


def test_new_terms_text_asks_again_and_an_old_tick_does_not_count():
    # The back-office bumps the version when the text changes (test_group_delete).
    UserFactory(phone="+237677452108", pin="4821", terms_version=1)
    PlatformSettings.objects.update_or_create(pk=1, defaults={"terms_version": 2})
    assert _login().status_code == 428
    assert _login(accept_terms=True, terms_version=1).status_code == 428  # ticked on the old text
    assert _login(accept_terms=True, terms_version=2).status_code == 200


def test_forgot_pin_needs_the_box_before_using_the_code(monkeypatch):
    from apps.core import sms

    checked = []
    monkeypatch.setattr(sms, "check_code", lambda phone, code: checked.append(code) or True)
    UserFactory(phone="+237677452108", pin="4821")
    api = APIClient()
    body = {"phone": "677452108", "code": "123456", "new_pin": "7391"}
    r = api.post("/api/auth/pin/forgot/confirm/", body, format="json")
    assert r.status_code == 428 and checked == []  # the code isn't used up
    r = api.post("/api/auth/pin/forgot/confirm/", {**body, "accept_terms": True, "terms_version": 1}, format="json")
    assert r.status_code == 200
