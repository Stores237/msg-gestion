from datetime import timedelta

import pytest
from django.utils import timezone
from rest_framework.test import APIClient

from apps.accounts.factories import UserFactory, give_role
from apps.events.models import Event

from .models import Announcement, Read

pytestmark = pytest.mark.django_db


def client_for(*slugs):
    user = UserFactory()
    for s in slugs:
        give_role(user, s)
    api = APIClient()
    api.force_authenticate(user)
    return api, user


def test_secretary_publishes_member_reads_unread_flag_clears():
    sg_api, _ = client_for("secretaire-general")
    member_api, member = client_for("membre")
    r = sg_api.post("/api/announcements/", {"title": "Répétition des chants", "body": "Jeudi 18:00"}, format="json")
    assert r.status_code == 201
    aid = r.json()["id"]
    feed = member_api.get("/api/announcements/").json()
    assert feed["unread"] == 1 and feed["results"][0]["unread"] is True
    assert feed["results"][0]["reads"] is None  # members don't see read counts
    member_api.post(f"/api/announcements/{aid}/read/")
    member_api.post(f"/api/announcements/{aid}/read/")  # idempotent
    assert Read.objects.filter(announcement_id=aid, member=member).count() == 1
    assert member_api.get("/api/announcements/").json()["unread"] == 0


def test_member_cannot_publish():
    api, _ = client_for("membre")
    assert api.post("/api/announcements/", {"title": "x"}, format="json").status_code == 403


def test_convocation_needs_an_event_and_is_pinned_first():
    api, _ = client_for("secretaire-general")
    assert api.post("/api/announcements/", {"kind": "convocation", "title": "AG"}, format="json").status_code == 400
    event = Event.objects.create(kind="assise", title="Assemblée générale", starts_at=timezone.now() + timedelta(days=18))
    api.post("/api/announcements/", {"title": "Plus ancienne"}, format="json")
    r = api.post("/api/announcements/", {"kind": "convocation", "title": "AG ordinaire", "event": event.id, "pinned": True}, format="json")
    assert r.status_code == 201 and r.json()["event_title"] == "Assemblée générale"
    api.post("/api/announcements/", {"title": "Plus récente"}, format="json")
    titles = [a["title"] for a in api.get("/api/announcements/").json()["results"]]
    assert titles == ["AG ordinaire", "Plus récente", "Plus ancienne"]
    assert [a["title"] for a in api.get("/api/announcements/?filter=convocations").json()["results"]] == ["AG ordinaire"]


def test_author_sees_receipts_member_does_not():
    sg_api, sg = client_for("secretaire-general")
    member_api, member = client_for("membre")
    other = UserFactory()
    aid = sg_api.post("/api/announcements/", {"title": "x"}, format="json").json()["id"]
    member_api.post(f"/api/announcements/{aid}/read/")
    receipts = sg_api.get(f"/api/announcements/{aid}/reads/").json()
    assert receipts["read"] == 2 and receipts["total"] == 3  # sg (author) + member, of 3 people
    assert {r["member"]: r["read"] for r in receipts["rows"]}[other.id] is False
    assert member_api.get(f"/api/announcements/{aid}/reads/").status_code == 403
    feed_item = sg_api.get("/api/announcements/?filter=sent").json()["results"][0]
    assert feed_item["reads"] == {"read": 2, "total": 3}


def test_unread_filter():
    sg_api, _ = client_for("secretaire-general")
    member_api, _ = client_for("membre")
    a = sg_api.post("/api/announcements/", {"title": "lue"}, format="json").json()["id"]
    sg_api.post("/api/announcements/", {"title": "non lue"}, format="json")
    member_api.post(f"/api/announcements/{a}/read/")
    assert [x["title"] for x in member_api.get("/api/announcements/?filter=unread").json()["results"]] == ["non lue"]
    assert Announcement.objects.count() == 2
