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


def _pdf(name="Convocation_AG.pdf", body=b"%PDF-1.4\n%fake\n"):
    from django.core.files.uploadedfile import SimpleUploadedFile

    return SimpleUploadedFile(name, body, content_type="application/pdf")


def test_author_attaches_a_pdf_members_see_a_link():
    sg_api, _ = client_for("secretaire-general")
    member_api, _ = client_for("membre")
    aid = sg_api.post("/api/announcements/", {"title": "AG"}, format="json").json()["id"]
    r = sg_api.post(f"/api/announcements/{aid}/attachments/", {"file": _pdf()}, format="multipart")
    assert r.status_code == 201, r.json()
    assert r.json()["content_type"] == "application/pdf" and r.json()["name"] == "Convocation_AG.pdf"
    item = member_api.get("/api/announcements/").json()["results"][0]
    assert [a["name"] for a in item["attachments"]] == ["Convocation_AG.pdf"]
    assert item["attachments"][0]["url"].startswith("http")


def test_attachment_type_checked_on_content_not_name():
    sg_api, _ = client_for("secretaire-general")
    aid = sg_api.post("/api/announcements/", {"title": "AG"}, format="json").json()["id"]
    fake = _pdf(name="virus.pdf", body=b"MZ\x90\x00 not a pdf")
    r = sg_api.post(f"/api/announcements/{aid}/attachments/", {"file": fake}, format="multipart")
    assert (r.status_code, r.json()["code"]) == (400, "file_type")


def test_attachment_size_limit(settings):
    from apps.announcements import files

    sg_api, _ = client_for("secretaire-general")
    aid = sg_api.post("/api/announcements/", {"title": "AG"}, format="json").json()["id"]
    original = files.MAX_BYTES
    import apps.announcements.views as views

    views.MAX_BYTES = 10
    try:
        r = sg_api.post(f"/api/announcements/{aid}/attachments/", {"file": _pdf()}, format="multipart")
    finally:
        views.MAX_BYTES = original
    assert r.json()["code"] == "file_too_large"


def test_only_author_or_managers_attach_or_delete():
    sg_api, _ = client_for("secretaire-general")
    trainer_api, _ = client_for("formateur")
    from apps.accounts.models import Role

    Role.objects.get(slug="formateur").permissions.create(resource="announcements.posts", action="create")
    aid = sg_api.post("/api/announcements/", {"title": "AG"}, format="json").json()["id"]
    assert trainer_api.post(f"/api/announcements/{aid}/attachments/", {"file": _pdf()}, format="multipart").status_code == 403
    att = sg_api.post(f"/api/announcements/{aid}/attachments/", {"file": _pdf()}, format="multipart").json()["id"]
    assert trainer_api.delete(f"/api/announcements/{aid}/attachments/{att}/").status_code == 403
    assert sg_api.delete(f"/api/announcements/{aid}/attachments/{att}/").status_code == 204
