"""Editing a group, and deleting it with two super admins (owner,
2026-10-23): one asks with a reason, another confirms."""

from datetime import timedelta

import pytest
from django.test import Client
from django.utils import timezone

from apps.accounts.factories import UserFactory, give_role
from apps.accounts.models import Role, RoleAssignment, User
from apps.core import sms
from apps.core.group_admin import _delete_group, create_group
from apps.core.groups import in_group
from apps.core.models import AuditLog, Group, GroupDeletion, Membership, Settings
from apps.finances.models import Due, Entry
from apps.members import services as access
from apps.members.models import AccessRequest

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

    def as_admin(phone):
        user = UserFactory(phone=f"+237{phone}", password=PASSWORD, membership=False)
        give_role(user, "super-admin")
        c = Client()
        c.post("/bo/connexion/", {"phone": phone, "password": PASSWORD})
        c.post("/bo/connexion/code/", {"code": f"{sent['v']:06d}"})
        c.user = user
        return c

    return as_admin


@pytest.fixture
def choir():
    """A second group with people, roles and money in it."""
    g = create_group(name="Chorale Sainte-Cécile", place="Bonapriso")
    leader = UserFactory(membership=g)
    with in_group(g):
        give_role(leader, "secretaire-general")
        req = access.submit(by=leader, last_name="Mbarga", first_name="Rose", phone="+237690112233",
                            role=Role.objects.get(slug="tresorier"), registration_paid=True)
        access.approve(req, by=leader)
    return g


def test_edit_a_group(login, choir):
    a = login("677000001")
    login("677000002")
    r = a.post(f"/bo/groupes/{choir.pk}/modifier/", {"name": "Chorale Ste-Cécile", "parish": "Akwa", "motto": "Chanter",
                                                     "welcome_message": "Bienvenue", "color": "#5B3FA0"}, follow=True)
    assert "enregistré" in r.content.decode()
    choir.refresh_from_db()
    st = Settings.get(choir)
    assert (choir.name, st.parish, st.motto, st.welcome_message, st.color) == ("Chorale Ste-Cécile", "Akwa", "Chanter", "Bienvenue", "#5B3FA0")
    assert AuditLog.objects.filter(action="Groupe modifié", group__isnull=True).exists()
    r = a.post(f"/bo/groupes/{choir.pk}/modifier/", {"name": "X", "color": "violet"}, follow=True)
    assert "#RRVVBB" in r.content.decode()
    choir.refresh_from_db()
    assert choir.name == "Chorale Ste-Cécile"


def test_deletion_needs_a_second_super_admin(login, choir):
    a, b = login("677000001"), login("677000002")
    first = Group.objects.order_by("pk").first()
    rose = User.objects.get(phone="+237690112233")
    assert Entry.all_groups.filter(group=choir).exists() and Due.all_groups.filter(group=choir).exists()
    url = f"/bo/groupes/{choir.pk}/supprimer/"

    # A reason and the exact name are required.
    a.post(url, {"action": "request", "reason": "", "confirm_name": choir.name})
    a.post(url, {"action": "request", "reason": "Doublon", "confirm_name": "chorale"})
    assert not GroupDeletion.objects.exists()
    assert AuditLog.objects.filter(action="Suppression de groupe refusée", refused=True).count() == 2

    a.post(url, {"action": "request", "reason": "Groupe créé en double", "confirm_name": choir.name})
    assert GroupDeletion.objects.get().status == "pending"
    assert Group.objects.filter(pk=choir.pk).exists()  # nothing deleted yet
    page = a.get("/bo/groupes/").content.decode()
    assert "Suppression demandée" in page and "Confirmer la suppression" not in page

    # The one who asked cannot confirm.
    r = a.post(url, {"action": "confirm", "confirm_name": choir.name}, follow=True)
    assert "autre super admin" in r.content.decode()
    assert Group.objects.filter(pk=choir.pk).exists()

    # Another super admin confirms: the group and its data go, accounts stay.
    assert "Confirmer la suppression" in b.get("/bo/groupes/").content.decode()
    r = b.post(url, {"action": "confirm", "confirm_name": choir.name}, follow=True)
    assert "supprimé" in r.content.decode()
    assert not Group.objects.filter(pk=choir.pk).exists()
    assert not Entry.all_groups.filter(group_id=choir.pk).exists()
    assert not Role.all_groups.filter(group_id=choir.pk).exists()
    assert not RoleAssignment.all_groups.filter(user=rose).exists()
    assert not AccessRequest.all_groups.exists()
    assert not Membership.all_groups.filter(group_id=choir.pk).exists()
    assert User.objects.filter(pk=rose.pk).exists()
    log = AuditLog.objects.get(action="Groupe supprimé")
    assert log.group is None and log.actor == b.user and log.detail["motif"] == "Groupe créé en double"
    # The first group is untouched and the back-office still works.
    assert Group.objects.filter(pk=first.pk).exists()
    assert b.get("/bo/").status_code == 200 and a.get("/bo/groupes/").status_code == 200


def test_cancel_expire_and_last_group(login, choir):
    a, b = login("677000001"), login("677000002")
    url = f"/bo/groupes/{choir.pk}/supprimer/"
    a.post(url, {"action": "request", "reason": "Test", "confirm_name": choir.name})
    b.post(url, {"action": "cancel"})
    assert GroupDeletion.objects.get().status == "cancelled"
    b.post(url, {"action": "confirm", "confirm_name": choir.name})
    assert Group.objects.filter(pk=choir.pk).exists()

    # A request older than 3 days lapses.
    a.post(url, {"action": "request", "reason": "Encore", "confirm_name": choir.name})
    GroupDeletion.objects.filter(status="pending").update(requested_at=timezone.now() - timedelta(days=4))
    b.post(url, {"action": "confirm", "confirm_name": choir.name})
    assert Group.objects.filter(pk=choir.pk).exists()

    # The platform's only group cannot be deleted.
    first = Group.objects.order_by("pk").first()
    _delete_group(choir)
    r = a.post(f"/bo/groupes/{first.pk}/supprimer/", {"action": "request", "reason": "x", "confirm_name": first.name}, follow=True)
    assert "seul groupe" in r.content.decode()
