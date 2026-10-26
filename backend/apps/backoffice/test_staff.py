"""Back-office staff (owner, 2026-10-26): support, IT helpdesk and
integration ops, at two levels, each limited to its own areas."""

import pytest
from django.test import Client
from rest_framework.test import APIClient

from apps.accounts import registry
from apps.accounts.factories import UserFactory, give_role
from apps.accounts.models import Role, User
from apps.accounts.services import RuleViolation, set_role_permissions
from apps.core import sms
from apps.core.models import AuditLog, Membership
from apps.members.models import AccessRequest

from .models import BackupCode

pytestmark = pytest.mark.django_db
PASSWORD = "correct-horse-battery"


@pytest.fixture
def login(monkeypatch):
    sent = {}
    original = sms.secrets.randbelow

    def fake(n):
        v = original(n)
        sent["v"] = v
        return v

    monkeypatch.setattr(sms.secrets, "randbelow", fake)

    def as_user(user, phone):
        user.set_password(PASSWORD)
        user.save()
        c = Client()
        c.post("/bo/connexion/", {"phone": phone, "password": PASSWORD})
        c.post("/bo/connexion/code/", {"code": f"{sent['v']:06d}"})
        c.user = user
        return c

    return as_user


@pytest.fixture
def boss(login):
    admin = UserFactory(phone="+237677000001", membership=False)
    give_role(admin, "super-admin")
    give_role(UserFactory(membership=False), "super-admin")
    return login(admin, "677000001")


def staff_member(slug, phone):
    u = UserFactory(phone=f"+237{phone}", membership=False)
    give_role(u, slug)
    return u


def test_super_admin_creates_a_staff_account_shown_once(boss):
    r = boss.post("/bo/equipe/", {"action": "create", "last_name": "Kamga", "first_name": "Lise", "phone": "690000201",
                                  "role": "support-agent", "reason": "Recrutement support"})
    page = r.content.decode()
    assert r.status_code == 200 and 'id="once-password"' in page and "Codes de secours" in page
    u = User.objects.get(phone="+237690000201")
    assert u.is_backoffice_staff and u.staff_role().slug == "support-agent" and u.has_usable_password()
    assert not Membership.all_groups.filter(user=u).exists()  # not in any group
    assert BackupCode.remaining(u) == BackupCode.COUNT
    assert AuditLog.objects.filter(action="Compte de l’équipe créé", group__isnull=True).exists()
    # A number that already has an app account can't become staff.
    member = UserFactory(phone="+237690000202")
    r = boss.post("/bo/equipe/", {"action": "create", "last_name": "X", "first_name": "Y", "phone": "690000202",
                                  "role": "it-agent", "reason": "x"}, follow=True)
    assert "déjà un compte" in r.content.decode()
    assert not member.is_backoffice_staff


def test_staff_sign_in_to_the_back_office_never_the_app(login):
    agent = staff_member("support-agent", "690000210")
    c = login(agent, "690000210")
    page = c.get("/bo/").content.decode()
    assert c.get("/bo/").status_code == 200 and "Support · agent" in page
    # The menu shows only the agent's areas.
    assert "Demandes d’accès" in page and "Utilisateurs" in page
    for hidden in ("Intégrations et services", "Bilan financier", "Équipe du back-office"):
        assert hidden not in page, hidden
    agent.set_pin("4821")
    agent.save()
    r = APIClient().post("/api/auth/login/", {"phone": "690000210", "pin": "4821", "accept_terms": True, "terms_version": 1}, format="json")
    assert r.status_code == 403 and r.json()["code"] == "backoffice_only"


def test_support_agent_looks_support_responsable_acts(login):
    member = UserFactory(phone="+237690000220")
    give_role(member, "membre")
    leader = UserFactory()
    req = AccessRequest.objects.create(requested_by=leader, last_name="Mbarga", first_name="Rose", phone="+237690112233",
                                       role=Role.objects.get(slug="membre"))
    agent = login(staff_member("support-agent", "690000221"), "690000221")
    assert agent.get("/bo/demandes-acces/").status_code == 200
    assert agent.get(f"/bo/utilisateurs/{member.pk}/").status_code == 200
    assert agent.post(f"/bo/demandes-acces/{req.pk}/", {"approve": "1"}).status_code == 403
    assert agent.post(f"/bo/utilisateurs/{member.pk}/", {"action": "reset_pin"}).status_code == 403
    for url in ("/bo/integrations/", "/bo/finances/", "/bo/equipe/"):
        assert agent.get(url).status_code == 403, url

    lead = login(staff_member("support-responsable", "690000222"), "690000222")
    r = lead.post(f"/bo/utilisateurs/{member.pk}/", {"action": "reset_pin"})
    assert r.status_code == 200 and "Nouveau code PIN provisoire" in r.content.decode()
    lead.post(f"/bo/demandes-acces/{req.pk}/", {"approve": "1"})
    req.refresh_from_db()
    assert req.status == "approved"
    # Roles stay with the super admin; so do platform accounts.
    r = lead.post(f"/bo/utilisateurs/{member.pk}/", {"action": "assign", "role": "tresorier", "reason": "x"})
    assert r.status_code == 403
    admin = UserFactory(membership=False)
    give_role(admin, "super-admin")
    assert lead.post(f"/bo/utilisateurs/{admin.pk}/", {"action": "suspend", "reason": "x"}).status_code == 403
    assert AuditLog.objects.filter(action="Action back-office refusée", refused=True).count() >= 2


def test_it_helpdesk_helps_staff_but_never_a_super_admin(login, boss):
    it = login(staff_member("it-responsable", "690000230"), "690000230")
    colleague = staff_member("integration-agent", "690000231")
    assert it.get("/bo/equipe/").status_code == 200
    r = it.post("/bo/equipe/", {"action": "new_codes", "user": colleague.pk})
    assert r.status_code == 200 and "Codes de secours" in r.content.decode()
    assert BackupCode.remaining(colleague) == BackupCode.COUNT
    admin = User.objects.get(phone="+237677000001")
    assert it.post("/bo/equipe/", {"action": "new_codes", "user": admin.pk}).status_code == 403
    # Managing the team is the super admin's.
    assert it.post("/bo/equipe/", {"action": "remove", "user": colleague.pk, "reason": "x"}).status_code == 403
    assert it.get("/bo/integrations/").status_code == 200
    assert it.post("/bo/integrations/test-stockage/", follow=True).status_code == 200  # disk storage in tests: ok


def test_integration_agent_sees_services_only(login):
    c = login(staff_member("integration-agent", "690000240"), "690000240")
    assert c.get("/bo/integrations/").status_code == 200
    assert c.post("/bo/integrations/test-stockage/").status_code == 403
    assert c.get("/bo/utilisateurs/").status_code == 403
    assert c.get("/bo/plateforme/").status_code == 200


def test_super_admin_changes_level_and_removes(boss):
    s = staff_member("support-agent", "690000250")
    boss.post("/bo/equipe/", {"action": "change_role", "user": s.pk, "role": "support-responsable"})
    assert s.staff_role().slug == "support-responsable"
    boss.post("/bo/equipe/", {"action": "remove", "user": s.pk, "reason": "Départ"})
    s.refresh_from_db()
    assert not s.is_backoffice_staff and not s.has_usable_password()


def test_fixed_rules_for_staff_roles():
    admin = UserFactory()
    role = Role.all_groups.get(group=None, slug="support-responsable")
    for cell in [("finances.cashbook", "view"), ("backoffice.roles", "change"), ("backoffice.groups", "delete"),
                 ("members.profile", "view")]:
        with pytest.raises(RuleViolation):
            set_role_permissions(role, {cell: True}, by=admin, reason="x")
    # A group's role can never hold a back-office cell, even one named like a staff role.
    tresorier = Role.objects.get(slug="tresorier")
    with pytest.raises(RuleViolation):
        set_role_permissions(tresorier, {("backoffice.users", "view"): True}, by=admin, reason="x")
    assert registry.is_locked("tresorier", "backoffice.integrations", "view")
    assert not registry.is_locked("it-responsable", "backoffice.integrations", "change")
