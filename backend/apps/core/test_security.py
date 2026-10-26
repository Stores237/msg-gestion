"""Security check, 2026-10-26: findings fixed in code, kept fixed by tests."""

import pytest
from django.test import Client, RequestFactory, override_settings
from rest_framework.test import APIClient

from apps.accounts.factories import UserFactory, give_role

from .audit import client_ip

pytestmark = pytest.mark.django_db


def test_client_ip_never_trusts_the_left_of_x_forwarded_for():
    r = RequestFactory().get("/", HTTP_X_FORWARDED_FOR="6.6.6.6, 41.202.1.9", REMOTE_ADDR="10.0.0.1")
    assert client_ip(r) == "41.202.1.9"  # the entry added by the proxy, not the one the client wrote


@override_settings(CLIENT_IP_HEADER="HTTP_CF_CONNECTING_IP")
def test_client_ip_uses_the_header_cloudflare_sets():
    r = RequestFactory().get("/", HTTP_X_FORWARDED_FOR="6.6.6.6, 41.202.1.9, 172.70.1.1",
                             HTTP_CF_CONNECTING_IP="41.202.1.9", REMOTE_ADDR="10.0.0.1")
    assert client_ip(r) == "41.202.1.9"


def test_a_new_forged_address_per_request_does_not_escape_the_throttle(monkeypatch):
    from rest_framework.throttling import ScopedRateThrottle

    UserFactory(phone="+237677452108")
    monkeypatch.setattr(ScopedRateThrottle, "THROTTLE_RATES", {**ScopedRateThrottle.THROTTLE_RATES, "phone_lookup": "2/hour"})
    api = APIClient()
    codes = [api.post("/api/auth/phone/", {"phone": "677452108"}, format="json",
                      HTTP_X_FORWARDED_FOR=f"10.9.9.{i}, 41.202.1.9").status_code for i in range(3)]
    assert codes == [200, 200, 429]


def test_api_map_is_for_back_office_accounts_only():
    assert APIClient().get("/api/schema/").status_code in (401, 403)
    assert Client().get("/api/docs/").status_code in (401, 403)
    member = UserFactory()
    c = Client()
    c.force_login(member)
    assert c.get("/api/schema/").status_code == 403
    admin = UserFactory(membership=False)
    give_role(admin, "super-admin")
    c.force_login(admin)
    assert c.get("/api/schema/").status_code == 200


def test_cors_headers_only_on_the_api():
    origin = {"HTTP_ORIGIN": "https://evil.example"}
    assert Client().get("/api/auth/terms/", **origin).headers.get("Access-Control-Allow-Origin") == "*"
    assert "Access-Control-Allow-Origin" not in Client().get("/bo/connexion/", **origin).headers
