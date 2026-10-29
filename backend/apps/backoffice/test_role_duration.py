"""Only the super admin holds a role with no end; every other role is given
for the duration the back-office sets on it (owner, 2026-10-29)."""

from datetime import date

import pytest

from apps.accounts import registry
from apps.accounts.factories import UserFactory
from apps.accounts.models import Role, RoleAssignment
from apps.accounts.services import RuleViolation, assign_role, default_end
from apps.backoffice.test_staff import boss, login, staff_member  # noqa: F401 - fixtures
from apps.core.models import AuditLog

pytestmark = pytest.mark.django_db


def test_every_role_but_super_admin_and_membre_has_a_duration():
    # After the migration, nothing but the open-ended roles is without one.
    assert not Role.all_groups.exclude(slug__in=registry.OPEN_ENDED_ROLES).filter(mandate_months__isnull=True).exists()
    assert Role.all_groups.get(slug="formateur").mandate_months
    assert Role.all_groups.get(slug="president").mandate_months == 24


def test_assignment_gets_the_role_end_and_super_admin_stays_open():
    m = UserFactory()
    formateur = Role.objects.get(slug="formateur")
    a = assign_role(m, formateur, reason="Nomination", by=None, starts_on=date(2026, 10, 20))
    assert a.ends_on == default_end(formateur, date(2026, 10, 20)) and a.ends_on is not None
    member = assign_role(m, Role.objects.get(slug="membre"), reason="Adhésion", by=None)
    assert member.ends_on is None
    admin = assign_role(UserFactory(), Role.objects.get(slug="super-admin"), reason="Équipe", by=None)
    assert admin.ends_on is None


def test_a_role_without_duration_cannot_be_given():
    role = Role.objects.create(slug="sans-duree", name="Sans durée")
    with pytest.raises(RuleViolation, match="n’a pas de durée"):
        assign_role(UserFactory(), role, reason="Essai", by=None)
    assert AuditLog.objects.filter(action="Refus · durée du rôle", refused=True).exists()
    assert not RoleAssignment.objects.filter(role=role).exists()


def test_backoffice_sets_the_duration(boss):  # noqa: F811
    page = boss.get("/bo/roles/formateur/").content.decode()
    assert 'id="dlg-duration"' in page and "Durée " in page
    r = boss.post("/bo/roles/formateur/gerer/", {"action": "duration", "months": "6", "reason": ""}, follow=True)
    assert "motif est obligatoire" in r.content.decode()
    r = boss.post("/bo/roles/formateur/gerer/", {"action": "duration", "months": "0", "reason": "Essai"}, follow=True)
    assert "de 1 à 120 mois" in r.content.decode()
    boss.post("/bo/roles/formateur/gerer/", {"action": "duration", "months": "6", "reason": "Mandat court"})
    role = Role.objects.get(slug="formateur")
    assert role.mandate_months == 6
    log = AuditLog.objects.get(action="Durée du rôle modifiée")
    assert log.detail["apres"] == 6 and log.detail["motif"] == "Mandat court"
    # The super admin's role has none to set.
    page = boss.get("/bo/roles/super-admin/").content.decode()
    assert 'id="dlg-duration"' not in page and "Sans fin" in page
    r = boss.post("/bo/roles/nouveau/", {"action": "new", "name": "Sans fin ?"}, follow=True)
    assert "Durée requise" in r.content.decode() and not Role.objects.filter(name="Sans fin ?").exists()


def test_who_may_set_it(login):  # noqa: F811
    agent = login(staff_member("support-agent", "690000331"), "690000331")
    r = agent.post("/bo/roles/formateur/gerer/", {"action": "duration", "months": "6", "reason": "x"})
    assert r.status_code == 403
