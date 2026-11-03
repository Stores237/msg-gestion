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


# --- Build 40: what each group shares upward -----------------------------------------------

def _attached(mgs):
    net, parish, zone, pres_p, pres_z, member = mgs
    accept_invitation(create_invitation(zone, by=pres_z).code, parish, by=pres_p)
    return parish, zone, pres_p, pres_z, member


def test_nothing_is_shared_until_the_president_chooses(mgs):
    parish, zone, pres_p, pres_z, _ = _attached(mgs)
    zapi = app_client(pres_z, zone)
    seen = zapi.get(f"/api/network/groups/{parish.pk}/").json()
    assert seen["name"] == parish.name and seen["shared"] == {}
    papi = app_client(pres_p, parish)
    assert papi.get("/api/network/sharing/").json()["values"]["finances"] == "none"
    r = papi.put("/api/network/sharing/", {"members": "detail", "finances": "summary", "announcements": "detail"}, format="json")
    assert r.status_code == 200 and r.json()["values"]["members"] == "detail"
    assert papi.put("/api/network/sharing/", {"announcements": "summary"}, format="json").json()["code"] == "bad_level"
    assert AuditLog.objects.filter(action="Partage avec le réseau modifié", group=parish).exists()
    assert Notification.all_groups.filter(user=pres_z, group=zone, title="Partage d’un groupe rattaché").exists()

    shared = zapi.get(f"/api/network/groups/{parish.pk}/").json()["shared"]
    assert set(shared) == {"members", "finances", "announcements"}
    people = shared["members"]["data"]["people"]
    assert people and all(set(p) == {"name", "roles"} for p in people)  # never a phone
    assert "balance" in shared["finances"]["data"] and "entries" not in shared["finances"]["data"]
    z = zapi.get("/api/network/").json()
    assert z["totals"]["sharing_members"] == 1 and z["totals"]["members"] >= 2
    assert set(z["children"][0]["shares"]) == {"members", "finances", "announcements"}


def test_each_kind_needs_the_matching_role_above(mgs):
    parish, zone, pres_p, pres_z, _ = _attached(mgs)
    from apps.core.sharing import save_settings

    save_settings(parish, {"finances": "detail", "members": "summary"}, by=pres_p)
    plain = UserFactory.build()  # a plain member of the zone
    plain.save()
    give(plain, zone, "membre")
    shared = app_client(plain, zone).get(f"/api/network/groups/{parish.pk}/").json()["shared"]
    assert shared["finances"] == {"level": "detail", "hidden": True}


def test_only_groups_below_can_be_looked_at(mgs):
    parish, zone, pres_p, pres_z, member = _attached(mgs)
    # The parish can't look at its zone, nor a member at their own group this way.
    assert app_client(pres_p, parish).get(f"/api/network/groups/{zone.pk}/").status_code == 404
    assert app_client(member, parish).put("/api/network/sharing/", {"members": "detail"}, format="json").status_code == 403


def test_backoffice_shows_what_each_group_shares(boss, mgs):  # noqa: F811
    parish, zone, pres_p, *_ = _attached(mgs)
    from apps.core.sharing import save_settings

    save_settings(parish, {"calendar": "summary"}, by=pres_p)
    assert "Calendrier : résumé" in boss.get("/bo/reseaux/").content.decode()


# --- Build 41: what flows down -------------------------------------------------------------

def test_a_zone_announcement_reaches_the_parishes(mgs):
    parish, zone, pres_p, pres_z, member = _attached(mgs)
    from apps.announcements.models import Announcement

    zapi = app_client(pres_z, zone)
    r = zapi.post("/api/announcements/", {"title": "Rencontre de zone", "body": "Samedi à 15 h", "cascade": True}, format="json")
    assert r.status_code == 201, r.content
    pk = r.json()["id"]
    assert Notification.all_groups.filter(user=member, group=parish, title=f"Annonce de {zone.name}").exists()

    mapi = app_client(member, parish)
    feed = mapi.get("/api/announcements/").json()
    item = next(a for a in feed["results"] if a["id"] == pk)
    assert item["from_group"]["name"] == zone.name and item["can_edit"] is False and item["reads"] is None
    assert feed["unread"] >= 1
    assert mapi.get(f"/api/announcements/{pk}/").status_code == 200
    assert mapi.post(f"/api/announcements/{pk}/read/").status_code == 204
    # The parish can't change it.
    assert app_client(pres_p, parish).patch(f"/api/announcements/{pk}/", {"title": "x"}, format="json").status_code == 404
    # The zone's own view counts the parish's members in the total.
    own = zapi.get(f"/api/announcements/{pk}/").json()
    assert own["from_group"] is None and own["reads"]["read"] == 2 and own["reads"]["total"] >= 3
    # Not cascaded: stays in the zone.
    quiet = zapi.post("/api/announcements/", {"title": "Bureau seulement"}, format="json").json()["id"]
    assert quiet not in [a["id"] for a in mapi.get("/api/announcements/").json()["results"]]
    assert Announcement.all_groups.get(pk=pk).group == zone


def test_cascade_needs_groups_below(mgs):
    _, parish, zone, pres_p, *_ = mgs
    r = app_client(pres_p, parish).post("/api/announcements/", {"title": "Hello", "cascade": True}, format="json")
    assert r.status_code == 400 and "cascade" in r.json()


def test_a_zone_event_shows_in_the_parish_calendar(mgs):
    parish, zone, pres_p, pres_z, member = _attached(mgs)
    from apps.core.groups import in_group
    from apps.events.models import ActivityType

    with in_group(zone):
        kind = ActivityType.objects.first().slug
    when = (timezone.now() + timedelta(days=3)).replace(microsecond=0).isoformat()
    zapi = app_client(pres_z, zone)
    r = zapi.post("/api/events/", {"kind": kind, "title": "Messe de zone", "starts_at": when, "place": "Cathédrale",
                                    "cascade": True, "chef": pres_z.pk}, format="json")
    assert r.status_code == 201, r.content
    pk = r.json()["id"]
    assert Notification.all_groups.filter(user=member, group=parish, title=f"Événement de {zone.name}").exists()
    mapi = app_client(member, parish)
    ev = next(e for e in mapi.get("/api/events/").json() if e["id"] == pk)
    assert ev["from_group"]["name"] == zone.name and ev["can_edit"] is False and ev["kind_name"]
    detail = app_client(pres_p, parish).get(f"/api/events/{pk}/").json()
    assert detail["from_group"]["name"] == zone.name and "attendance_counts" not in detail
    assert app_client(pres_p, parish).patch(f"/api/events/{pk}/", {"title": "x"}, format="json").status_code == 404
    # Detached: it disappears.
    detach(parish, by=pres_p, reason="Test")
    assert pk not in [e["id"] for e in mapi.get("/api/events/").json()]
