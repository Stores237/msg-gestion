"""One phone at a time (owner, 2026-10-30): signing in on a second phone
signs the first one out; the newest phone wins."""

import pytest
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import RefreshToken

from apps.core.models import AuditLog

from .factories import UserFactory

pytestmark = pytest.mark.django_db

PHONE = "677452108"


def _login(api):
    r = api.post("/api/auth/login/", {"phone": PHONE, "pin": "4821", "accept_terms": True, "terms_version": 1}, format="json")
    assert r.status_code == 200
    return r.json()


def _me(tokens):
    api = APIClient()
    api.credentials(HTTP_AUTHORIZATION=f"Bearer {tokens['access']}")
    return api.get("/api/me/")


def _refresh(tokens):
    return APIClient().post("/api/auth/refresh/", {"refresh": tokens["refresh"]}, format="json")


def test_second_phone_signs_the_first_out():
    user = UserFactory(phone="+237677452108", pin="4821")
    first = _login(APIClient())
    assert _me(first).status_code == 200

    second = _login(APIClient())
    assert _me(second).status_code == 200

    # The first phone: its access token and its refresh token are refused,
    # with the reason the app words for the member.
    old = _me(first)
    assert (old.status_code, old.json()["code"]) == (401, "other_device")
    again = _refresh(first)
    assert (again.status_code, again.json()["code"]) == (401, "other_device")
    assert "autre téléphone" in again.json()["detail"]
    assert AuditLog.objects.filter(action="Connexion sur un autre téléphone", object_id=str(user.pk)).count() == 1


def test_the_phone_in_use_keeps_working_across_refreshes():
    UserFactory(phone="+237677452108", pin="4821")
    tokens = _login(APIClient())
    renewed = _refresh(tokens)
    assert renewed.status_code == 200
    # The session id rides along with the rotated pair.
    assert _me(renewed.json()).status_code == 200
    assert _refresh(renewed.json()).status_code == 200


def test_back_on_the_first_phone_the_second_is_out():
    UserFactory(phone="+237677452108", pin="4821")
    _login(APIClient())
    second = _login(APIClient())
    _login(APIClient())  # the member signs in on the first phone again
    assert _me(second).json()["code"] == "other_device"


def test_sessions_opened_before_the_rule_stay_until_the_next_sign_in():
    user = UserFactory(phone="+237677452108", pin="4821")
    legacy = RefreshToken.for_user(user)  # no session id, as before the deploy
    tokens = {"access": str(legacy.access_token), "refresh": str(legacy)}
    assert _me(tokens).status_code == 200
    _login(APIClient())
    assert _me(tokens).json()["code"] == "other_device"


def test_forged_or_expired_refresh_gets_the_usual_answer():
    UserFactory(phone="+237677452108", pin="4821")
    r = APIClient().post("/api/auth/refresh/", {"refresh": "not-a-token"}, format="json")
    assert r.status_code == 401 and r.json()["code"] == "token_not_valid"
