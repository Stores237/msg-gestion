"""Networks of groups (owner, 2026-11-03): parish groups attached to a zone,
zones to a diocese. The back-office creates networks and levels; an umbrella
invites with a single-use code; the invited group's président accepts; either
side can end it; the umbrella only informs."""

from datetime import timedelta

import pytest
from django.utils import timezone

from apps.accounts.factories import UserFactory
from apps.backoffice.test_staff import boss, login, staff_member  # noqa: F401 - fixtures
from apps.core.group_admin import create_group
from apps.core.models import AuditLog, Group, GroupInvitation, Network, Notification
from apps.core.network import NetworkRule, accept_invitation, create_invitation, detach, place_group, save_network
from apps.core.test_groups import app_client, give

pytestmark = pytest.mark.django_db


@pytest.fixture
def mgs():
    """A network with a parish group (the first group) and a zone."""
    pres_p, pres_z, member = UserFactory(), UserFactory(), UserFactory()  # before a 2nd group exists
    net = save_network(by=None, name="MGS Cameroun", levels=["Paroisse", "Zone paroissiale", "Diocèse", "National"])
    parish = Group.objects.order_by("pk").first()
    zone = create_group(name="Zone de Bonamoussadi")
    place_group(parish, network=net, level=1, by=None)
    place_group(zone, network=net, level=2, by=None)
    parish.refresh_from_db()
    zone.refresh_from_db()
    give(pres_p, parish, "president")
    give(pres_z, zone, "president")
    give(member, parish, "membre")
    return net, parish, zone, pres_p, pres_z, member


def test_the_zone_invites_and_the_parish_accepts(mgs):
    net, parish, zone, pres_p, pres_z, _ = mgs
    zapi = app_client(pres_z, zone)
    r = zapi.post("/api/network/invitations/")
    assert r.status_code == 201
    code = r.json()["code"]
    assert len(code) == 9 and code[4] == "-"
    assert zapi.get("/api/network/").json()["invitations"][0]["code"] == code

    papi = app_client(pres_p, parish)
    preview = papi.get(f"/api/network/invitations/?code={code.lower()}").json()
    assert preview["name"] == zone.name and preview["level_name"] == "Zone paroissiale"
    data = papi.post("/api/network/join/", {"code": code}, format="json").json()
    assert data["parents"][0]["name"] == zone.name and data["level_name"] == "Paroisse"
    parish.refresh_from_db()
    assert parish.parent == zone and parish.attached_at

    z = zapi.get("/api/network/").json()
    assert z["children"][0]["name"] == parish.name and z["invitations"] == []
    assert Notification.all_groups.filter(user=pres_z, kind="network", group=zone).exists()
    assert AuditLog.objects.filter(action="Groupe rattaché", group=zone).exists()
    assert AuditLog.objects.filter(action="Groupe rattaché", group=parish).exists()
    # Single use.
    assert papi.post("/api/network/join/", {"code": code}, format="json").json()["code"] in ("used", "already")
    # The group list in /api/me/ says where the group stands.
    me = papi.get("/api/me/").json()
    assert me["groups"][0]["parent"] == zone.name and me["groups"][0]["level_name"] == "Paroisse"


def test_only_the_president_manages_and_members_can_look(mgs):
    _, parish, zone, _, pres_z, member = mgs
    code = create_invitation(zone, by=pres_z).pretty
    mapi = app_client(member, parish)
    seen = mapi.get("/api/network/").json()
    assert seen["network"]["levels"][:2] == ["Paroisse", "Zone paroissiale"] and seen["can_manage"] is False
    assert mapi.post("/api/network/join/", {"code": code}, format="json").status_code == 403
    assert mapi.get(f"/api/network/invitations/?code={code}").status_code == 403
    assert mapi.post("/api/network/leave/", {"reason": "x"}, format="json").status_code == 403


def test_codes_that_dont_work(mgs):
    net, parish, zone, pres_p, pres_z, _ = mgs
    papi = app_client(pres_p, parish)
    r = papi.post("/api/network/join/", {"code": "ZZZZ-ZZZZ"}, format="json")
    assert r.status_code == 404 and r.json()["code"] == "unknown_invitation"
    assert AuditLog.objects.filter(action="Rattachement refusé", refused=True).exists()
    old = create_invitation(zone, by=pres_z)
    GroupInvitation.objects.filter(pk=old.pk).update(expires_at=timezone.now() - timedelta(minutes=1))
    assert papi.post("/api/network/join/", {"code": old.code}, format="json").json()["code"] == "expired"
    # A parish can't invite: it is the base level.
    assert papi.post("/api/network/invitations/").json()["code"] == "not_umbrella"
    # The zone can't join a parish's code, nor one from another network.
    other = save_network(by=None, name="Chorales", levels=["Chorale", "Doyenné"])
    deanery = create_group(name="Doyenné Nord")
    deanery = place_group(deanery, network=other, level=2, by=None)
    with pytest.raises(NetworkRule) as e:
        accept_invitation(create_invitation(deanery, by=None).code, parish, by=pres_p)
    assert e.value.code == "other_network"
    with pytest.raises(NetworkRule) as e:
        accept_invitation(create_invitation(zone, by=None).code, zone, by=pres_z)
    assert e.value.code == "self"


def test_the_parish_leaves_with_a_reason(mgs):
    _, parish, zone, pres_p, pres_z, _ = mgs
    accept_invitation(create_invitation(zone, by=pres_z).code, parish, by=pres_p)
    papi = app_client(pres_p, parish)
    assert papi.post("/api/network/leave/", {"reason": ""}, format="json").json()["code"] == "detach_reason"
    data = papi.post("/api/network/leave/", {"reason": "Changement de zone"}, format="json").json()
    assert data["parents"] == []
    assert Notification.all_groups.filter(user=pres_z, group=zone, title="Groupe détaché").exists()
    assert papi.post("/api/network/leave/", {"reason": "encore"}, format="json").json()["code"] == "not_attached"


def test_levels_keep_their_order(mgs):
    net, parish, zone, pres_p, pres_z, _ = mgs
    accept_invitation(create_invitation(zone, by=pres_z).code, parish, by=pres_p)
    with pytest.raises(NetworkRule) as e:
        place_group(zone, network=net, level=1, by=None)  # under its own parish
    assert e.value.code == "below_children"
    with pytest.raises(NetworkRule) as e:
        place_group(parish, network=None, level=1, by=None)
    assert e.value.code == "linked"
    diocese = create_group(name="Diocèse de Douala")
    diocese = place_group(diocese, network=net, level=3, by=None)
    accept_invitation(create_invitation(diocese, by=None).code, zone, by=pres_z)
    assert [g.name for g in Group.objects.get(pk=parish.pk).ancestors()] == [zone.name, diocese.name]
    assert {g.pk for g in diocese.descendants()} == {zone.pk, parish.pk}
    detach(zone, by=None, reason="Réorganisation")
    assert Group.objects.get(pk=zone.pk).parent is None


def test_backoffice_networks_page(boss, mgs):  # noqa: F811
    net, parish, zone, *_ = mgs
    page = boss.get("/bo/reseaux/").content.decode()
    assert "MGS Cameroun" in page and "Zone paroissiale" in page and zone.name in page
    page = boss.post("/bo/reseaux/", {"action": "invite", "group": zone.pk}, follow=True).content.decode()
    inv = GroupInvitation.objects.get(umbrella=zone)
    assert inv.pretty in page
    boss.post("/bo/reseaux/", {"action": "revoke", "id": inv.pk})
    assert GroupInvitation.objects.get(pk=inv.pk).status == "revoked"
    boss.post("/bo/reseaux/", {"action": "network", "name": "Scouts", "level1": "Unité", "level2": "District"})
    scouts = Network.objects.get(name="Scouts")
    page = boss.post("/bo/reseaux/", {"action": "place", "group": parish.pk, "network": scouts.pk, "level": 1},
                     follow=True).content.decode()
    assert Group.objects.get(pk=parish.pk).network == scouts
    # Detach through the back-office.
    place_group(Group.objects.get(pk=parish.pk), network=net, level=1, by=None)
    accept_invitation(create_invitation(zone, by=None).code, Group.objects.get(pk=parish.pk), by=None)
    page = boss.post("/bo/reseaux/", {"action": "detach", "group": parish.pk, "reason": "Erreur de zone"},
                     follow=True).content.decode()
    assert "n’est plus rattaché" in page and Group.objects.get(pk=parish.pk).parent is None
    page = boss.post("/bo/reseaux/", {"action": "network", "name": "", "level1": "a", "level2": "b"}, follow=True).content.decode()
    assert "Le nom du réseau est obligatoire." in page
