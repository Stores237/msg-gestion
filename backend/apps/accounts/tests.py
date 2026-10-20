from datetime import date, timedelta

import pytest
from django.utils import timezone
from rest_framework.test import APIClient

from apps.core.models import AuditLog

from . import registry
from .factories import UserFactory, give_role
from .models import Role, RolePermission, User
from .phone import InvalidPhone, mask_phone, normalize_phone
from .services import RuleViolation, assign_role, default_end, revoke_assignment, set_role_permissions

pytestmark = pytest.mark.django_db


@pytest.fixture
def api():
    return APIClient()


# --- Phone numbers -----------------------------------------------------------


@pytest.mark.parametrize(
    "raw,expected",
    [
        ("6 77 45 21 08", "+237677452108"),
        ("677452108", "+237677452108"),
        ("+237 6 77 45 21 08", "+237677452108"),
        ("237677452108", "+237677452108"),
        ("00237677452108", "+237677452108"),
        ("+33 6 12 45 78 90", "+33612457890"),
        ("0033612457890", "+33612457890"),
        ("2 33 42 10 10", "+237233421010"),
    ],
)
def test_normalize_phone(raw, expected):
    assert normalize_phone(raw) == expected


@pytest.mark.parametrize("raw", ["", "12345", "+237 5 77 45 21 08", "6774521", "abc", None])
def test_normalize_phone_rejects(raw):
    with pytest.raises(InvalidPhone):
        normalize_phone(raw)


def test_format_phone():
    from .phone import format_phone

    assert format_phone("+237677452108") == "+237 6 77 45 21 08"
    assert format_phone("+33612457890") == "+33612457890"


def test_mask_phone():
    assert mask_phone("+237677102241") == "+237 6•• •• •• 41"


# --- Login: phone lookup -------------------------------------------------------


def test_lookup_returns_first_name(api):
    UserFactory(phone="+237677452108", first_name="Ingrid")
    r = api.post("/api/auth/phone/", {"phone": "6 77 45 21 08"}, format="json")
    assert r.status_code == 200
    assert r.json() == {"first_name": "Ingrid", "has_pin": True}


def test_lookup_unknown_and_suspended_look_the_same(api):
    UserFactory(phone="+237677452108", status=User.Status.SUSPENDED)
    unknown = api.post("/api/auth/phone/", {"phone": "699999999"}, format="json")
    suspended = api.post("/api/auth/phone/", {"phone": "677452108"}, format="json")
    assert unknown.status_code == suspended.status_code == 404
    assert unknown.json() == suspended.json()


def test_lookup_rejects_malformed_number(api):
    r = api.post("/api/auth/phone/", {"phone": "12"}, format="json")
    assert r.status_code == 400


# --- Login: PIN and lockout -----------------------------------------------------


def _login(api, pin, phone="677452108"):
    return api.post("/api/auth/login/", {"phone": phone, "pin": pin}, format="json")


def test_pin_login_returns_tokens(api):
    UserFactory(phone="+237677452108", pin="4821")
    r = _login(api, "4821")
    assert r.status_code == 200
    assert set(r.json()) == {"access", "refresh"}


def test_three_wrong_pins_lock_the_account(api):
    user = UserFactory(phone="+237677452108", pin="4821")
    first, second = _login(api, "0000"), _login(api, "0000")
    assert (first.status_code, first.json()["attempts_left"]) == (401, 2)
    assert (second.status_code, second.json()["attempts_left"]) == (401, 1)
    assert "1 essai." in second.json()["detail"]
    third = _login(api, "0000")
    assert third.status_code == 423
    # Locked means locked: even the right PIN is refused now.
    assert _login(api, "4821").status_code == 423
    user.refresh_from_db()
    assert user.pin_locked_until > timezone.now() + timedelta(minutes=14)
    assert AuditLog.objects.filter(action="Compte bloqué (PIN)", object_id=str(user.pk)).exists()


def test_lock_expires_and_counter_restarts(api):
    user = UserFactory(phone="+237677452108", pin="4821")
    user.pin_failed_attempts = 3
    user.pin_locked_until = timezone.now() - timedelta(seconds=1)
    user.save()
    r = _login(api, "0000")
    assert (r.status_code, r.json()["attempts_left"]) == (401, 2)
    assert _login(api, "4821").status_code == 200


def test_successful_login_resets_counter(api):
    user = UserFactory(phone="+237677452108", pin="4821")
    _login(api, "0000")
    assert _login(api, "4821").status_code == 200
    user.refresh_from_db()
    assert user.pin_failed_attempts == 0


def test_pin_must_be_four_digits(api):
    UserFactory(phone="+237677452108")
    assert _login(api, "12345").status_code == 400
    assert _login(api, "12a4").status_code == 400


def test_member_without_pin_gets_clear_conflict(api):
    user = UserFactory(phone="+237677452108")
    user.pin = ""
    user.save()
    assert _login(api, "1234").status_code == 409


def test_login_is_throttled_with_429_not_500(api, monkeypatch):
    """A throttled endpoint needs a reachable cache. If Redis were missing
    this would be a ConnectionError 500 (playbook §7)."""
    from rest_framework.throttling import ScopedRateThrottle

    UserFactory(phone="+237677452108")
    monkeypatch.setattr(ScopedRateThrottle, "THROTTLE_RATES", {**ScopedRateThrottle.THROTTLE_RATES, "phone_lookup": "2/hour"})
    codes = [api.post("/api/auth/phone/", {"phone": "677452108"}, format="json").status_code for _ in range(3)]
    assert codes == [200, 200, 429]


# --- Tokens ---------------------------------------------------------------------------


def test_refresh_rotates_and_blacklists_old_token(api):
    UserFactory(phone="+237677452108", pin="4821")
    tokens = _login(api, "4821").json()
    first = api.post("/api/auth/refresh/", {"refresh": tokens["refresh"]}, format="json")
    assert first.status_code == 200 and "refresh" in first.json()
    reused = api.post("/api/auth/refresh/", {"refresh": tokens["refresh"]}, format="json")
    assert reused.status_code == 401


def test_logout_blacklists_refresh(api):
    UserFactory(phone="+237677452108", pin="4821")
    tokens = _login(api, "4821").json()
    api.credentials(HTTP_AUTHORIZATION=f"Bearer {tokens['access']}")
    assert api.post("/api/auth/logout/", {"refresh": tokens["refresh"]}, format="json").status_code == 204
    api.credentials()
    assert api.post("/api/auth/refresh/", {"refresh": tokens["refresh"]}, format="json").status_code == 401


# --- /me and tabs per role ----------------------------------------------------------


def _me(api, user):
    api.force_authenticate(user)
    return api.get("/api/me/").json()


@pytest.mark.parametrize(
    "slugs,tabs",
    [
        (["membre"], ["accueil", "calendrier", "annonces"]),
        (["censeur-general"], ["accueil", "membres", "calendrier", "annonces"]),
        (["secretaire-general"], ["accueil", "membres", "calendrier", "annonces"]),
        (["tresorier"], ["accueil", "membres", "finances", "calendrier", "annonces"]),
        (["commissaire-aux-comptes"], ["accueil", "membres", "finances", "calendrier", "annonces"]),
        (["president"], ["accueil", "membres", "finances", "calendrier", "annonces"]),
        ([], ["accueil"]),
    ],
)
def test_tabs_follow_the_role_matrix(api, slugs, tabs):
    """Design: "Navigation par rôle" — un onglet sans droit n’apparaît pas."""
    user = UserFactory()
    for s in slugs:
        give_role(user, s)
    assert _me(api, user)["tabs"] == tabs


def test_me_requires_auth(api):
    assert api.get("/api/me/").status_code == 401


def test_expired_temporary_role_grants_nothing(api):
    user = UserFactory()
    give_role(user, "censeur-du-jour", starts_on=date.today() - timedelta(days=3), ends_on=date.today() - timedelta(days=1))
    me = _me(api, user)
    assert me["roles"] == []
    assert "calendar.attendance" not in me["permissions"]


def test_future_role_not_active_yet():
    user = UserFactory()
    give_role(user, "tresorier", starts_on=date.today() + timedelta(days=1))
    assert not user.can("finances.cashbook", "view")


# --- Separation of duties ---------------------------------------------------------------


def test_treasurer_can_never_validate_even_if_db_says_so():
    user = UserFactory()
    give_role(user, "tresorier")
    role = Role.objects.get(slug="tresorier")
    RolePermission.objects.create(role=role, resource="finances.cashbook", action="validate")
    assert user.can("finances.cashbook", "change")
    assert not user.can("finances.cashbook", "validate")


def test_super_admin_never_sees_finances_even_with_another_role():
    """The lock follows the person: a super admin who is also président
    still can't see amounts (design: Masked)."""
    user = UserFactory()
    give_role(user, "president")
    give_role(user, "super-admin")
    assert not user.can("finances.cashbook", "view")
    assert "finances" not in user.tabs()


def test_treasurer_cannot_also_be_auditor():
    admin, user = UserFactory(), UserFactory()
    give_role(user, "tresorier")
    with pytest.raises(RuleViolation, match="cumulé"):
        assign_role(user, Role.objects.get(slug="commissaire-aux-comptes"), reason="AG", by=admin)
    assert AuditLog.objects.filter(action="Refus · séparation des tâches", refused=True).exists()
    assert not user.can("finances.cashbook", "validate")


def test_assign_role_requires_reason_and_logs():
    admin, user = UserFactory(), UserFactory()
    role = Role.objects.get(slug="conseiller")
    with pytest.raises(RuleViolation):
        assign_role(user, role, reason="  ", by=admin)
    a = assign_role(user, role, reason="Élection en AG", by=admin, starts_on=date(2026, 10, 1))
    assert a.ends_on == date(2028, 9, 30)
    entry = AuditLog.objects.get(action="Rôle affecté")
    assert entry.actor == admin and entry.detail["motif"] == "Élection en AG"


@pytest.mark.parametrize(
    "start,months,end",
    [(date(2026, 10, 1), 24, date(2028, 9, 30)), (date(2025, 1, 31), 1, date(2025, 2, 27)), (date(2024, 3, 15), 12, date(2025, 3, 14))],
)
def test_default_mandate_end(start, months, end):
    assert default_end(Role(mandate_months=months), start) == end


def test_no_default_end_without_mandate():
    assert default_end(Role(mandate_months=None), date(2026, 1, 1)) is None


# --- Two-super-admin safeguard --------------------------------------------------------------


def test_cannot_drop_below_two_super_admins():
    a, b = UserFactory(), UserFactory()
    give_role(a, "super-admin")
    assignment = give_role(b, "super-admin")
    with pytest.raises(RuleViolation, match="au moins 2"):
        revoke_assignment(assignment, by=a, reason="départ")
    assignment.refresh_from_db()
    assert assignment.revoked_at is None
    assert AuditLog.objects.filter(action="Refus · garde-fou", refused=True).exists()


def test_can_revoke_when_a_third_super_admin_exists():
    a, b, c = UserFactory(), UserFactory(), UserFactory()
    for u in (a, b):
        give_role(u, "super-admin")
    assignment = give_role(c, "super-admin")
    revoke_assignment(assignment, by=a, reason="fin de mission")
    assert not c.is_super_admin


def test_expired_super_admin_does_not_count_toward_minimum():
    a, b, old = UserFactory(), UserFactory(), UserFactory()
    give_role(a, "super-admin")
    assignment = give_role(b, "super-admin")
    give_role(old, "super-admin", starts_on=date(2020, 1, 1), ends_on=date(2021, 1, 1))
    with pytest.raises(RuleViolation):
        revoke_assignment(assignment, by=a, reason="départ")


# --- Permission matrix edits --------------------------------------------------------------------


def test_set_role_permissions_diffs_and_logs():
    admin = UserFactory()
    role = Role.objects.get(slug="tresorier")
    diff = set_role_permissions(
        role, {("announcements.posts", "create"): True, ("calendar.planning", "view"): False}, by=admin, reason="Appels à contribution"
    )
    assert sorted(diff) == [["announcements.posts", "create", False, True], ["calendar.planning", "view", True, False]]
    assert AuditLog.objects.get(action="Permission modifiée").detail["motif"] == "Appels à contribution"


def test_set_role_permissions_refuses_locked_and_inapplicable():
    admin = UserFactory()
    role = Role.objects.get(slug="tresorier")
    with pytest.raises(RuleViolation, match="séparation"):
        set_role_permissions(role, {("finances.cashbook", "validate"): True}, by=admin, reason="x")
    with pytest.raises(RuleViolation, match="sans objet"):
        set_role_permissions(role, {("announcements.posts", "validate"): True}, by=admin, reason="x")


def test_every_seeded_permission_is_applicable_and_not_locked():
    """Migration 0002 and the registry must agree."""
    for p in RolePermission.objects.select_related("role"):
        assert registry.is_applicable(p.resource, p.action), p
        assert not registry.is_locked(p.role.slug, p.resource, p.action), p
