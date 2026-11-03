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


# --- Build 42: joint planning ---------------------------------------------------------------

def _zone_event(zone, pres_z, cascade=True):
    from apps.core.groups import in_group
    from apps.events.models import ActivityType

    with in_group(zone):
        kind = ActivityType.objects.first().slug
    when = (timezone.now() + timedelta(days=5)).replace(microsecond=0).isoformat()
    r = app_client(pres_z, zone).post("/api/events/", {"kind": kind, "title": "Pèlerinage de zone", "starts_at": when,
                                                      "cascade": cascade, "chef": pres_z.pk}, format="json")
    assert r.status_code == 201, r.content
    return r.json()["id"]


def test_the_zone_asks_the_parish_names(mgs):
    parish, zone, pres_p, pres_z, member = _attached(mgs)
    pk = _zone_event(zone, pres_z)
    zapi = app_client(pres_z, zone)
    body = zapi.get(f"/api/events/{pk}/contingents/").json()
    assert body["groups"][0]["group"]["name"] == parish.name and body["groups"][0]["requested"] == 0
    r = zapi.put(f"/api/events/{pk}/contingents/", {"requests": [{"group": parish.pk, "requested": 2, "note": "En tenue"}]},
                 format="json")
    assert r.status_code == 200 and r.json()["groups"][0]["requested"] == 2
    assert Notification.all_groups.filter(user=pres_p, group=parish, title__startswith=f"{zone.name} demande 2").exists()

    papi = app_client(pres_p, parish)
    mine = papi.get(f"/api/events/{pk}/contingent/").json()
    assert mine["requested"] == 2 and mine["note"] == "En tenue" and mine["can_answer"] is True
    r = papi.put(f"/api/events/{pk}/contingent/", {"members": [member.pk, pres_p.pk]}, format="json")
    assert r.status_code == 200 and len(r.json()["members"]) == 2
    assert Notification.all_groups.filter(user=member, group=parish, title="Vous êtes désigné(e)").exists()
    assert Notification.all_groups.filter(user=pres_z, group=zone, title=f"{parish.name} a désigné 2/2").exists()
    # The member sees it on the event; the zone sees the names.
    ev = next(e for e in app_client(member, parish).get("/api/events/").json() if e["id"] == pk)
    assert ev["contingent"] == {"requested": 2, "designated": 2, "me": True}
    names = zapi.get(f"/api/events/{pk}/contingents/").json()["groups"][0]["members"]
    assert len(names) == 2
    assert zapi.get(f"/api/events/{pk}/").json()["contingent"]["designated"] == 2


def test_contingent_rules(mgs):
    parish, zone, pres_p, pres_z, member = _attached(mgs)
    zapi = app_client(pres_z, zone)
    quiet = _zone_event(zone, pres_z, cascade=False)
    r = zapi.put(f"/api/events/{quiet}/contingents/", {"requests": [{"group": parish.pk, "requested": 1}]}, format="json")
    assert r.json()["code"] == "not_sent_down"
    pk = _zone_event(zone, pres_z)
    assert zapi.put(f"/api/events/{pk}/contingents/", {"requests": [{"group": zone.pk, "requested": 1}]},
                    format="json").json()["code"] == "not_below"
    # A plain member can't ask nor name.
    assert app_client(member, parish).put(f"/api/events/{pk}/contingent/", {"members": []}, format="json").status_code == 404
    zapi.put(f"/api/events/{pk}/contingents/", {"requests": [{"group": parish.pk, "requested": 1}]}, format="json")
    assert app_client(member, parish).put(f"/api/events/{pk}/contingent/", {"members": []}, format="json").status_code == 403
    # Only the parish's own active members.
    r = app_client(pres_p, parish).put(f"/api/events/{pk}/contingent/", {"members": [999999]}, format="json")
    assert r.json()["code"] == "not_member"
    # 0 cancels.
    zapi.put(f"/api/events/{pk}/contingents/", {"requests": [{"group": parish.pk, "requested": 0}]}, format="json")
    assert app_client(pres_p, parish).get(f"/api/events/{pk}/contingent/").status_code == 404


# --- Build 43: neighbours and twinning ------------------------------------------------------

def test_neighbours_see_what_each_shares_with_neighbours(mgs):
    parish, zone, pres_p, pres_z, member = _attached(mgs)
    from apps.core.sharing import save_settings

    other = create_group(name="GS Bonamoussadi")
    pres_o = UserFactory.build()
    pres_o.save()
    give(pres_o, other, "president")
    other = place_group(other, network=mgs[0], level=1, by=None)
    accept_invitation(create_invitation(zone, by=None).code, other, by=pres_o)
    papi = app_client(pres_p, parish)
    data = papi.get("/api/network/").json()
    assert [g["name"] for g in data["neighbours"]] == [other.name] and data["sharing_neighbours"]["members"] == "none"
    # Nothing until the neighbour shares; "up" settings don't count for neighbours.
    save_settings(other, {"members": "summary"}, by=pres_o)
    assert papi.get(f"/api/network/groups/{other.pk}/").json()["shared"] == {}
    r = app_client(pres_o, other).put("/api/network/sharing/?audience=neighbours", {"members": "summary"}, format="json")
    assert r.status_code == 200 and r.json()["values"]["members"] == "summary"
    seen = papi.get(f"/api/network/groups/{other.pk}/").json()
    assert seen["relation"] == "neighbours" and seen["shared"]["members"]["data"]["total"] >= 1
    assert Notification.all_groups.filter(user=pres_p, group=parish, title="Partage d’un groupe voisin").exists()


def test_two_groups_anywhere_twin_with_a_code(mgs):
    _, parish, zone, pres_p, pres_z, _ = mgs
    choir = create_group(name="Chorale Sainte-Cécile")  # in no network
    pres_c = UserFactory.build()
    pres_c.save()
    give(pres_c, choir, "president")
    capi, papi = app_client(pres_c, choir), app_client(pres_p, parish)
    code = capi.post("/api/network/invitations/?kind=twin").json()["code"]
    assert capi.get("/api/network/").json()["twin_invitations"][0]["code"] == code
    # Not an attach code.
    assert papi.post("/api/network/join/", {"code": code}, format="json").json()["code"] == "wrong_kind"
    assert papi.get(f"/api/network/invitations/?code={code}&kind=twin").json()["name"] == choir.name
    data = papi.post("/api/network/twins/join/", {"code": code}, format="json").json()
    assert [g["name"] for g in data["twins"]] == [choir.name]
    assert Notification.all_groups.filter(user=pres_c, group=choir, title="Nouveau jumelage").exists()
    capi.put("/api/network/sharing/?audience=twins", {"announcements": "detail"}, format="json")
    seen = papi.get(f"/api/network/groups/{choir.pk}/").json()
    assert seen["relation"] == "twins" and "announcements" in seen["shared"]
    # A second code between the same groups is refused; ending needs a reason.
    code2 = capi.post("/api/network/invitations/", {"kind": "twin"}, format="json").json()["code"]
    assert papi.post("/api/network/twins/join/", {"code": code2}, format="json").json()["code"] == "already_twinned"
    assert papi.post(f"/api/network/twins/{choir.pk}/end/", {"reason": ""}, format="json").json()["code"] == "detach_reason"
    data = papi.post(f"/api/network/twins/{choir.pk}/end/", {"reason": "Fin du projet"}, format="json").json()
    assert data["twins"] == []
    assert papi.get(f"/api/network/groups/{choir.pk}/").status_code == 404


def test_backoffice_ends_a_twinning(boss, mgs):  # noqa: F811
    _, parish, zone, pres_p, pres_z, _ = mgs
    from apps.core.models import GroupInvitation, GroupLink
    from apps.core.network import accept_twin

    accept_twin(create_invitation(zone, by=None, kind=GroupInvitation.Kind.TWIN).code, parish, by=pres_p)
    link = GroupLink.objects.get(is_active=True)
    assert "Jumelages · 1" in boss.get("/bo/reseaux/").content.decode()
    page = boss.post("/bo/reseaux/", {"action": "end_twin", "id": link.pk, "reason": "Doublon"}, follow=True).content.decode()
    assert "terminé" in page and not GroupLink.objects.get(pk=link.pk).is_active


# --- Build 44: contributions between levels ---------------------------------------------

def test_the_zone_asks_a_contribution_and_the_parish_pays_it(mgs):
    parish, zone, pres_p, pres_z, member = _attached(mgs)
    from apps.core.groups import in_group
    from apps.finances.models import Entry, NetworkDue

    zt, pt = UserFactory.build(), UserFactory.build()
    zt.save()
    pt.save()
    give(zt, zone, "tresorier")
    give(pt, parish, "tresorier")
    zapi, papi = app_client(zt, zone), app_client(pt, parish)
    r = zapi.post("/api/finances/network-dues/", {"title": "Quote-part 2027", "amount": 25000, "due_on": "2027-01-31"},
                  format="json")
    assert r.status_code == 200, r.content
    asked = r.json()["asked"]
    assert len(asked) == 1 and asked[0]["group"]["name"] == parish.name and asked[0]["status"] == "open"
    assert Notification.all_groups.filter(user=pt, group=parish, title=f"Quote-part demandée par {zone.name}").exists()

    owed = papi.get("/api/finances/network-dues/").json()
    assert owed["can_pay"] and owed["owed"][0]["group"]["name"] == zone.name and owed["owed"][0]["amount"] == 25000
    due_id = owed["owed"][0]["id"]
    # The zone can't pay it, the parish can't cancel it.
    assert zapi.post(f"/api/finances/network-dues/{due_id}/pay/", {}, format="json").status_code == 404
    assert papi.post(f"/api/finances/network-dues/{due_id}/cancel/", {"reason": "non"}, format="json").status_code == 404
    data = papi.post(f"/api/finances/network-dues/{due_id}/pay/", {}, format="json").json()
    assert data["owed"][0]["status"] == "sent"
    with in_group(parish):
        out = Entry.objects.get(category="reseau")
        assert out.direction == "out" and out.status == "pending" and out.amount == 25000
    with in_group(zone):
        inn = Entry.objects.get(category="reseau")
        assert inn.direction == "in" and zone.name not in inn.label and parish.name in inn.label
    assert papi.post(f"/api/finances/network-dues/{due_id}/pay/", {}, format="json").json()["code"] == "due_paid"
    # Received once the zone validates its line.
    inn.status = Entry.Status.VALIDATED
    inn.save(update_fields=["status"])
    assert NetworkDue.objects.get(pk=due_id).status == "received"
    assert zapi.get("/api/finances/network-dues/").json()["asked"][0]["status"] == "received"


def test_contribution_rules(mgs):
    parish, zone, pres_p, pres_z, member = _attached(mgs)
    zt = UserFactory.build()
    zt.save()
    give(zt, zone, "tresorier")
    zapi = app_client(zt, zone)
    assert zapi.post("/api/finances/network-dues/", {"title": "Q", "amount": 100}, format="json").json()["code"] == "title_required"
    assert zapi.post("/api/finances/network-dues/", {"title": "Quote", "amount": 0}, format="json").json()["code"] == "bad_amount"
    assert app_client(member, parish).post("/api/finances/network-dues/", {"title": "Quote", "amount": 5},
                                           format="json").status_code == 403
    pt = UserFactory.build()
    pt.save()
    give(pt, parish, "tresorier")
    assert app_client(pt, parish).post("/api/finances/network-dues/", {"title": "Quote", "amount": 5},
                                       format="json").json()["code"] == "no_groups_below"
    due = zapi.post("/api/finances/network-dues/", {"title": "Quote", "amount": 5}, format="json").json()["asked"][0]["id"]
    assert zapi.post(f"/api/finances/network-dues/{due}/cancel/", {"reason": ""}, format="json").json()["code"] == "reason_required"
    assert zapi.post(f"/api/finances/network-dues/{due}/cancel/", {"reason": "Erreur"}, format="json").json()["asked"][0]["status"] == "cancelled"
    assert app_client(pt, parish).post(f"/api/finances/network-dues/{due}/pay/", {}, format="json").json()["code"] == "due_cancelled"
    # The category can't be used by hand.
    r = app_client(pt, parish).post("/api/finances/entries/", {"direction": "in", "amount": 5, "category": "reseau",
                                                               "label": "x", "date": "2026-11-01"}, format="json")
    assert r.status_code == 400 and r.json()["code"] == "network_auto"


# --- Build 45: reminders, report, back-office contributions -------------------------------

def test_reminders_reach_the_groups_below_and_the_named(mgs):
    parish, zone, pres_p, pres_z, member = _attached(mgs)
    from django.core.management import call_command

    from apps.core.groups import in_group
    from apps.events.models import ActivityType, Event, EventContingent

    with in_group(zone):
        kind = ActivityType.objects.first().slug
        tomorrow = timezone.localtime() + timedelta(days=1)
        ev = Event.objects.create(kind=kind, title="Pèlerinage", starts_at=tomorrow.replace(hour=9, minute=0),
                                  place="Cathédrale", cascade=True)
    c = EventContingent.objects.create(event=ev, group=parish, requested=1)
    c.members.set([member])
    member.remind_eve = False  # named people are reminded whatever their setting
    member.save(update_fields=["remind_eve"])
    call_command("send_reminders", stdout=__import__("io").StringIO())
    assert Notification.all_groups.filter(user=member, group=parish, title__startswith="Rappel : vous êtes attendu(e)").exists()
    assert Notification.all_groups.filter(user=pres_p, group=parish, title__startswith="Rappel : Pèlerinage").exists()
    # Run twice: nothing more.
    n = Notification.all_groups.filter(kind="reminder").count()
    call_command("send_reminders", stdout=__import__("io").StringIO())
    assert Notification.all_groups.filter(kind="reminder").count() == n


def test_quarter_report_and_backoffice_show_contributions(boss, mgs):  # noqa: F811
    parish, zone, pres_p, pres_z, member = _attached(mgs)
    from apps.core.groups import in_group
    from apps.finances import network_dues as nd
    from apps.finances.models import Entry

    pt = UserFactory.build()
    pt.save()
    give(pt, parish, "tresorier")
    give(pt, parish, "president")
    with in_group(zone):
        due = nd.ask(zone, title="Quote-part T4", amount=10000, by=pres_z)[0]
    with in_group(parish):
        nd.pay(due, by=pt)
    due.refresh_from_db()
    Entry.all_groups.filter(pk=due.received_entry_id).update(status="validated")
    today = timezone.localdate()
    q = (today.month - 1) // 3 + 1
    with in_group(zone):
        from apps.finances.services import report
        r = report(today.year, q)
    assert r["network"]["received_total"] == 10000 and r["network"]["received"][0]["group"] == parish.name
    with in_group(parish):
        r = report(today.year, q)
    assert r["network"]["paid_total"] == 10000 and r["network"]["owed_open"] == 0
    page = boss.get("/bo/reseaux/quotes-parts/").content.decode()
    assert "Quote-part T4" in page and parish.name in page and "Reçue" in page
    assert "Quote-part T4" not in boss.get("/bo/reseaux/quotes-parts/?statut=open").content.decode()


def test_demo_network_builds_and_goes_away(tmp_path):
    from io import StringIO

    from django.core.management import call_command

    from apps.accounts.models import User
    from apps.core.models import Group, GroupLink
    from apps.finances.models import NetworkDue

    out = tmp_path / "demo.txt"
    call_command("seed_network_demo", out=str(out), stdout=StringIO())
    from apps.accounts.models import Role
    from apps.core.network import has_president

    zone = Group.objects.get(name="Zone Wouri 9 (démo)")
    kids = {g.name: has_president(g) for g in zone.children.all()}
    assert len(kids) == 7 and kids["GS Yapoma (démo)"] and not kids["GS Paroisse 7 (démo)"]
    assert zone.parent.name == "Archidiocèse de Douala (démo)" and GroupLink.objects.filter(is_active=True).count() == 1
    assert NetworkDue.objects.filter(umbrella=zone).count() == 3  # the three active parishes
    assert Role.all_groups.get(group=zone.parent, slug="conseiller").name == "Aumônier diocésain"
    assert Role.all_groups.get(group=zone, slug="president").name == "Coordinateur de zone"
    assert zone.network.level_name(4) == "Province ecclésiastique"
    text = out.read_text()
    assert "PIN de tous les comptes" in text and "+237600000100" in text
    call_command("seed_network_demo", delete=True, stdout=StringIO())
    assert not Group.objects.filter(name__endswith=" (démo)").exists()
    assert not User.objects.filter(phone="+237600000100").exists()


# --- Build 46: six levels, roles per level, direct placement, « à compléter » ----------------

def test_six_levels_and_presets_per_level():
    from apps.accounts.models import Role
    from apps.core.network import create_in_network, level_model

    net = save_network(by=None, name="Église (test)", levels=["Paroisse", "Zone", "Diocèse", "Province", "National", ""])
    assert net.level_name(5) == "National" and net.level_name(6) == ""
    d = create_in_network(name="Archidiocèse de Douala", network=net, level=3, by=None)
    z = create_in_network(name="Zone Wouri 9", network=net, level=2, parent=d, by=None)
    roles = lambda g: dict(Role.all_groups.filter(group=g).values_list("slug", "name"))  # noqa: E731
    assert roles(d)["conseiller"] == "Aumônier diocésain" and "censeur-general" not in roles(d)
    assert roles(z)["president"] == "Coordinateur de zone" and "formateur" not in roles(z)
    # The first group of a level is its model; edits to it reach the next ones.
    assert level_model(net, 2) == z
    Role.all_groups.filter(group=z, slug="secretaire-general").update(name="Secrétaire de zone")
    z2 = create_in_network(name="Zone Wouri 10", network=net, level=2, parent=d, by=None)
    assert roles(z2)["secretaire-general"] == "Secrétaire de zone"
    assert z2.parent == d and z2.network == net


def test_import_a_list_all_or_nothing(boss):  # noqa: F811
    from apps.core.network import import_groups

    net = save_network(by=None, name="MGS (import)", levels=["Paroisse", "Zone paroissiale", "Diocèse"])
    text = "Archidiocèse de Douala ; Diocèse ;\nZone Wouri 9 ; 2 ; Archidiocèse de Douala\n" + "\n".join(
        f"GS Paroisse {i} ; Paroisse ; Zone Wouri 9" for i in range(1, 8))
    made = import_groups(net, text, by=None)
    zone = Group.objects.get(name="Zone Wouri 9")
    assert len(made) == 9 and zone.children.count() == 7 and zone.parent.name == "Archidiocèse de Douala"
    with pytest.raises(NetworkRule) as e:
        import_groups(net, "Zone X ; 2 ; Archidiocèse de Douala\nGS Y ; 1 ; Zone Inconnue", by=None)
    assert e.value.code == "bad_parent" and "Ligne 2" in e.value.message
    assert not Group.objects.filter(name="Zone X").exists()  # nothing kept
    page = boss.post("/bo/reseaux/", {"action": "import", "network": net.pk, "lines": "GS Paroisse 8 ; 1 ; Zone Wouri 9"},
                     follow=True).content.decode()
    assert "1 groupe créé" in page and "À compléter" in page


def test_direct_placement_only_without_a_president(mgs):
    net, parish, zone, pres_p, pres_z, _ = mgs
    from apps.core.network import attach_direct, create_in_network

    with pytest.raises(NetworkRule) as e:
        attach_direct(parish, zone, by=None)  # Yapoma has a président: it joins with a code
    assert e.value.code == "has_president"
    empty = create_in_network(name="GS Paroisse 2", network=net, level=1, by=None)
    attach_direct(empty, zone, by=None)
    data = app_client(pres_z, zone).get("/api/network/").json()
    child = next(c for c in data["children"] if c["name"] == "GS Paroisse 2")
    assert child["waiting"] is True
    assert Notification.all_groups.filter(user=pres_z, group=zone, title="Nouveau groupe rattaché").exists()


def test_backoffice_creates_a_group_in_place(boss, mgs):  # noqa: F811
    net, parish, zone, *_ = mgs
    page = boss.post("/bo/reseaux/", {"action": "create", "network": net.pk, "name": "GS Paroisse 3", "level": 1,
                                      "parent": zone.pk}, follow=True).content.decode()
    g = Group.objects.get(name="GS Paroisse 3")
    assert g.parent == zone and "à compléter" in page.lower()
    page = boss.post("/bo/reseaux/", {"action": "network", "id": net.pk, "name": net.name, "level1": "Paroisse",
                                      "level2": "Zone paroissiale", "level3": "Diocèse", "level4": "Province ecclésiastique",
                                      "level5": "National"}, follow=True).content.decode()
    assert "Province ecclésiastique" in page


# --- Build 47: the demo network from the back-office (staging only) ---------------------------

def test_backoffice_demo_page_only_on_staging(boss, settings):  # noqa: F811
    settings.DEMO_TOOLS = False
    assert boss.get("/bo/reseaux/demonstration/").status_code == 404
    assert "Démonstration" not in boss.get("/bo/reseaux/").content.decode()
    settings.DEMO_TOOLS = True
    assert "Démonstration" in boss.get("/bo/reseaux/").content.decode()
    page = boss.post("/bo/reseaux/demonstration/", {"action": "create"}).content.decode()
    assert 'id="demo-pin"' in page and "Zone Wouri 9 (démo)" in page and "Aumônier diocésain" in page
    assert Group.objects.filter(name="Archidiocèse de Douala (démo)").exists()
    assert AuditLog.objects.filter(action="Réseau de démonstration créé").exists()
    # Twice: refused, the PIN isn't shown again.
    page = boss.post("/bo/reseaux/demonstration/", {"action": "create"}, follow=True).content.decode()
    assert "existe déjà" in page and 'id="demo-pin"' not in page
    page = boss.post("/bo/reseaux/demonstration/", {"action": "delete", "confirm": "non"}, follow=True).content.decode()
    assert "Tapez SUPPRIMER" in page and Group.objects.filter(name__endswith=" (démo)").exists()
    boss.post("/bo/reseaux/demonstration/", {"action": "delete", "confirm": "SUPPRIMER"})
    assert not Group.objects.filter(name__endswith=" (démo)").exists()


def test_demo_page_is_for_super_admins_only(settings):
    from django.test import Client

    from apps.accounts.factories import give_role

    settings.DEMO_TOOLS = True
    u = UserFactory()
    give_role(u, "membre")
    c = Client()
    c.force_login(u)
    assert c.get("/bo/reseaux/demonstration/").status_code in (302, 403, 404)
    assert c.post("/bo/reseaux/demonstration/", {"action": "create"}).status_code in (302, 403, 404)
    assert not Group.objects.filter(name__endswith=" (démo)").exists()
