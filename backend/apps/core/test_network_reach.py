"""Build 48 (owner, 2026-11-04): photos and files reach the other groups;
the sender chooses which groups (and whether only their bureau) receive a
post or an event; a group asks a linked group to share more, whose
président accepts or declines; the président previews what they share."""

from datetime import timedelta

import pytest
from django.utils import timezone

from apps.accounts.factories import UserFactory
from apps.accounts.models import Role
from apps.announcements.models import Announcement
from apps.announcements.tests import _pdf
from apps.core.group_admin import create_group
from apps.core.groups import in_group
from apps.core.models import AuditLog, Group, GroupInvitation, GroupShare, Notification, ShareRequest
from apps.core.network import accept_invitation, accept_twin, create_invitation, place_group, save_network
from apps.core.test_groups import app_client, give

pytestmark = pytest.mark.django_db


@pytest.fixture
def zone3():
    """A zone with two parishes attached (A is the first group), and a
    chorale twinned with parish A."""
    people = {k: UserFactory() for k in ("pa", "pb", "pz", "pc", "ma", "mb", "ta")}  # before a 2nd group exists
    net = save_network(by=None, name="MGS", levels=["Paroisse", "Zone", "Diocèse", "National"])
    a = Group.objects.order_by("pk").first()
    b, zone, chorale = create_group(name="GS Kotto"), create_group(name="Zone Wouri"), create_group(name="Chorale")
    for g, lv in ((a, 1), (b, 1), (zone, 2)):
        place_group(g, network=net, level=lv, by=None)
    for g in (a, b, zone, chorale):
        g.refresh_from_db()
    give(people["pa"], a, "president")
    give(people["pb"], b, "president")
    give(people["pz"], zone, "president")
    give(people["pc"], chorale, "president")
    give(people["ma"], a, "membre")
    give(people["mb"], b, "membre")
    give(people["ta"], a, "tresorier")
    for g in (a, b):
        accept_invitation(create_invitation(zone, by=people["pz"]).code, g, by=people["pa" if g == a else "pb"])
    accept_twin(create_invitation(chorale, by=people["pc"], kind=GroupInvitation.Kind.TWIN).code, a, by=people["pa"])
    for g in (a, b, zone, chorale):
        g.refresh_from_db()
    return {"a": a, "b": b, "zone": zone, "chorale": chorale, **people}


def _ids(api, url="/api/announcements/"):
    return [x["id"] for x in api.get(url).json()["results"]]


def test_photos_and_files_reach_the_groups_below(zone3):
    z = zone3
    zapi = app_client(z["pz"], z["zone"])
    aid = zapi.post("/api/announcements/", {"title": "Pèlerinage", "cascade": True}, format="json").json()["id"]
    assert zapi.post(f"/api/announcements/{aid}/attachments/", {"file": _pdf()}, format="multipart").status_code == 201
    mapi = app_client(z["ma"], z["a"])
    row = next(x for x in mapi.get("/api/announcements/").json()["results"] if x["id"] == aid)
    assert [f["name"] for f in row["attachments"]] == ["Convocation_AG.pdf"] and row["attachments"][0]["url"]
    assert row["from_group"]["name"] == "Zone Wouri" and row["sent_to"] is None
    assert mapi.get(f"/api/announcements/{aid}/").json()["attachments"][0]["name"] == "Convocation_AG.pdf"


def test_the_sender_picks_the_groups(zone3):
    z = zone3
    zapi = app_client(z["pz"], z["zone"])
    r = zapi.post("/api/announcements/", {"title": "Pour Kotto", "cascade": True, "reach": [z["b"].pk]}, format="json")
    assert r.status_code == 201
    body = r.json()
    assert body["sent_to"]["all_below"] is False and [g["name"] for g in body["sent_to"]["groups"]] == ["GS Kotto"]
    assert body["id"] in _ids(app_client(z["mb"], z["b"]))
    assert body["id"] not in _ids(app_client(z["ma"], z["a"]))
    assert Notification.all_groups.filter(user=z["mb"], group=z["b"], title="Annonce de Zone Wouri").exists()
    assert not Notification.all_groups.filter(user=z["ma"], title="Annonce de Zone Wouri").exists()
    assert body["reads"]["total"] == 1 + 2  # the zone (its président) + Kotto's two members


def test_for_the_bureau_only(zone3):
    z = zone3
    zapi = app_client(z["pz"], z["zone"])
    aid = zapi.post("/api/announcements/", {"title": "Réunion des présidents", "cascade": True, "reach_audience": "bureau"},
                    format="json").json()["id"]
    assert Role.all_groups.get(group=z["a"], slug="president").kind == Role.Kind.BUREAU
    assert aid in _ids(app_client(z["pa"], z["a"]))
    assert aid not in _ids(app_client(z["ma"], z["a"]))
    assert app_client(z["ma"], z["a"]).get(f"/api/announcements/{aid}/").status_code == 404
    assert Notification.all_groups.filter(user=z["pa"], title="Annonce de Zone Wouri").exists()
    assert not Notification.all_groups.filter(user=z["ma"], title="Annonce de Zone Wouri").exists()


def test_a_twin_or_a_neighbour_can_be_chosen_not_a_stranger(zone3):
    z = zone3
    papi = app_client(z["pa"], z["a"])
    rows = papi.get("/api/network/recipients/").json()["groups"]
    assert {(r["name"], r["relation"]) for r in rows} == {("GS Kotto", "neighbour"), ("Chorale", "twin")}
    stranger = create_group(name="Ailleurs")
    bad = papi.post("/api/announcements/", {"title": "x", "cascade": True, "reach": [stranger.pk]}, format="json")
    assert bad.status_code == 400 and bad.json()["reach"][0] == "Un des groupes choisis n’est pas lié au vôtre."
    assert papi.post("/api/announcements/", {"title": "x", "reach": [z["b"].pk]}, format="json").status_code == 400
    aid = papi.post("/api/announcements/", {"title": "Concert commun", "cascade": True, "reach": [z["chorale"].pk]},
                    format="json").json()["id"]
    assert aid in _ids(app_client(z["pc"], z["chorale"]))
    assert aid not in _ids(app_client(z["mb"], z["b"]))
    # The zone sees every group below, at any depth.
    zrows = app_client(z["pz"], z["zone"]).get("/api/network/recipients/").json()
    assert zrows["children"] == 2 and {r["relation"] for r in zrows["groups"]} == {"below"}
    assert app_client(z["pa"], z["a"]).get("/api/me/").json()["group"]["reach"] == 2


def test_an_event_to_one_parish_asks_only_that_one(zone3):
    z = zone3
    zapi = app_client(z["pz"], z["zone"])
    with in_group(z["zone"]):
        from apps.events.models import ActivityType

        kind = ActivityType.objects.filter(needs_chef=False, is_archived=False).first().slug
    when = (timezone.now() + timedelta(days=5)).replace(microsecond=0).isoformat()
    r = zapi.post("/api/events/", {"title": "Journée zonale", "kind": kind, "starts_at": when, "cascade": True,
                                   "reach": [z["a"].pk]}, format="json")
    assert r.status_code == 201, r.json()
    eid = r.json()["id"]
    assert eid in [e["id"] for e in app_client(z["ma"], z["a"]).get("/api/events/").json()]
    assert eid not in [e["id"] for e in app_client(z["mb"], z["b"]).get("/api/events/").json()]
    board = zapi.get(f"/api/events/{eid}/contingents/").json()
    assert [g["group"]["name"] for g in board["groups"]] == [z["a"].name]
    # Adding Kotto later tells Kotto only.
    Notification.all_groups.all().delete()
    assert zapi.patch(f"/api/events/{eid}/", {"reach": [z["a"].pk, z["b"].pk]}, format="json").status_code == 200
    assert Notification.all_groups.filter(user=z["mb"], title="Événement de Zone Wouri").exists()
    assert not Notification.all_groups.filter(user=z["ma"], title="Événement de Zone Wouri").exists()


def test_asking_for_more_and_the_president_answers(zone3):
    z = zone3
    zapi = app_client(z["pz"], z["zone"])
    kinds = {k["kind"]: k for k in zapi.get(f"/api/network/groups/{z['a'].pk}/").json()["kinds"]}
    assert kinds["finances"]["state"] == "none" and kinds["finances"]["can_request"] and kinds["finances"]["next_level"] == "summary"
    r = zapi.post(f"/api/network/groups/{z['a'].pk}/requests/", {"kind": "finances", "level": "detail", "note": "Pour le rapport"},
                  format="json")
    assert r.status_code == 201
    kinds = {k["kind"]: k for k in r.json()["kinds"]}
    assert kinds["finances"]["request"]["level"] == "detail" and not kinds["finances"]["can_request"]
    again = zapi.post(f"/api/network/groups/{z['a'].pk}/requests/", {"kind": "finances", "level": "summary"}, format="json")
    assert again.json()["code"] == "already_asked"
    assert Notification.all_groups.filter(user=z["pa"], group=z["a"], title="Demande de partage").exists()

    papi = app_client(z["pa"], z["a"])
    assert papi.get("/api/network/").json()["requests_waiting"] == 1
    box = papi.get("/api/network/requests/").json()
    req = box["incoming"][0]
    assert box["can_answer"] and req["from_group"]["name"] == "Zone Wouri" and req["current"] == "none"
    # A member can't answer.
    assert app_client(z["ma"], z["a"]).post(f"/api/network/requests/{req['id']}/", {"accept": True}, format="json").status_code == 403
    assert papi.post(f"/api/network/requests/{req['id']}/", {"accept": True}, format="json").json()["status"] == "accepted"
    assert GroupShare.objects.get(group=z["a"], audience="up", kind="finances").level == "detail"
    assert Notification.all_groups.filter(user=z["pz"], group=z["zone"], title="Partage accepté").exists()
    assert AuditLog.objects.filter(action="Demande de partage acceptée", group=z["a"]).exists()
    shown = zapi.get(f"/api/network/groups/{z['a'].pk}/").json()
    assert shown["shared"]["finances"]["level"] == "detail"
    assert {k["kind"]: k for k in shown["kinds"]}["finances"]["state"] == "shared"

    # Declined, with a reason; withdrawn.
    rid = zapi.post(f"/api/network/groups/{z['a'].pk}/requests/", {"kind": "members", "level": "summary"}, format="json").json()["request"]["id"]
    assert papi.post(f"/api/network/requests/{rid}/", {"accept": False, "note": "Pas encore"}, format="json").json()["status"] == "declined"
    assert GroupShare.objects.filter(group=z["a"], kind="members").exclude(level="none").count() == 0
    last = {k["kind"]: k for k in zapi.get(f"/api/network/groups/{z['a'].pk}/").json()["kinds"]}["members"]["last_answer"]
    assert last["status"] == "declined" and last["answer_note"] == "Pas encore"
    rid = zapi.post(f"/api/network/groups/{z['a'].pk}/requests/", {"kind": "calendar", "level": "summary"}, format="json").json()["request"]["id"]
    assert zapi.delete(f"/api/network/requests/{rid}/").status_code == 204
    assert ShareRequest.objects.get(pk=rid).status == "cancelled"


def test_only_those_who_would_read_it_may_ask(zone3):
    z = zone3
    # A plain member of a neighbouring parish can't read finances there.
    mapi = app_client(z["mb"], z["b"])
    r = mapi.post(f"/api/network/groups/{z['a'].pk}/requests/", {"kind": "finances", "level": "summary"}, format="json")
    assert r.status_code == 403
    stranger = create_group(name="Ailleurs")
    r = app_client(z["pz"], z["zone"]).post(f"/api/network/groups/{stranger.pk}/requests/", {"kind": "members", "level": "summary"},
                                            format="json")
    assert r.status_code == 404


def test_announcement_files_only_at_detail_and_the_preview(zone3):
    z = zone3
    papi = app_client(z["pa"], z["a"])
    aid = papi.post("/api/announcements/", {"title": "Kermesse", "body": "Samedi"}, format="json").json()["id"]
    papi.post(f"/api/announcements/{aid}/attachments/", {"file": _pdf()}, format="multipart")
    prev = papi.post("/api/network/sharing/preview/", {"announcements": "summary", "finances": "detail"}, format="json").json()["shared"]
    assert prev["announcements"]["data"]["items"][0]["title"] == "Kermesse"
    assert "attachments" not in prev["announcements"]["data"]["items"][0]
    assert "entries" in prev["finances"]["data"]
    prev = papi.post("/api/network/sharing/preview/", {"announcements": "detail"}, format="json").json()["shared"]
    assert prev["announcements"]["data"]["items"][0]["attachments"][0]["name"] == "Convocation_AG.pdf"
    # The preview only shows what the viewer reads in their own group.
    hidden = app_client(z["ma"], z["a"]).post("/api/network/sharing/preview/", {"finances": "detail"}, format="json").json()["shared"]
    assert hidden["finances"] == {"level": "detail", "hidden": True}
    # Nothing saved by a preview.
    assert not GroupShare.objects.filter(group=z["a"]).exclude(level="none").exists()
    with in_group(z["a"]):
        assert Announcement.objects.get(pk=aid).attachments.count() == 1
