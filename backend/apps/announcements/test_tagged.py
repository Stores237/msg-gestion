"""Choosing who is notified (owner, 2026-10-29): tagged members get the
notification; the announcement or convocation stays visible to everyone."""

import pytest

from apps.core.models import AuditLog, Notification

from .tests import client_for

pytestmark = pytest.mark.django_db


def test_only_tagged_members_are_notified_everyone_sees_it():
    author_api, author = client_for("secretaire-general")
    a_api, a = client_for("membre")
    b_api, b = client_for("membre")
    c_api, c = client_for("membre")
    people = author_api.get("/api/announcements/recipients/").json()
    assert {a.pk, b.pk, c.pk} <= {p["id"] for p in people} and author.pk not in {p["id"] for p in people}

    r = author_api.post("/api/announcements/", {"title": "Clés de la sacristie", "tagged": [a.pk, b.pk]}, format="json")
    assert r.status_code == 201
    body = r.json()
    assert {m["id"] for m in body["tagged_members"]} == {a.pk, b.pk}
    assert set(Notification.objects.values_list("user_id", flat=True)) == {a.pk, b.pk}
    assert Notification.objects.filter(user=a).get().title == "Annonce pour vous"
    assert AuditLog.objects.get(action="Annonce publiée").detail == {"notifiés": 2, "mentionnés": 2}

    # C wasn't tagged: still sees it, not "for me".
    item = c_api.get("/api/announcements/").json()["results"][0]
    assert item["title"] == "Clés de la sacristie" and item["for_me"] is False
    mine = a_api.get("/api/announcements/?filter=for_me").json()["results"]
    assert [x["for_me"] for x in mine] == [True]
    assert b_api.get(f"/api/announcements/{body['id']}/").json()["for_me"] is True

    # The read receipts show who was tagged; a reminder goes to tagged non-readers.
    a_api.post(f"/api/announcements/{body['id']}/read/")
    rows = author_api.get(f"/api/announcements/{body['id']}/reads/").json()["rows"]
    assert {r["member"] for r in rows if r["tagged"]} == {a.pk, b.pk}
    Notification.objects.all().delete()
    assert author_api.post(f"/api/announcements/{body['id']}/remind/").json()["reminded"] == 1
    assert list(Notification.objects.values_list("user_id", flat=True)) == [b.pk]


def test_without_tags_everyone_is_notified_and_edits_tell_new_tags():
    author_api, _ = client_for("secretaire-general")
    _, a = client_for("membre")
    _, b = client_for("membre")
    r = author_api.post("/api/announcements/", {"title": "Répétition"}, format="json")
    assert {a.pk, b.pk} <= set(Notification.objects.values_list("user_id", flat=True))
    assert r.json()["tagged_members"] == []

    r = author_api.post("/api/announcements/", {"title": "Quête", "tagged": [a.pk]}, format="json")
    aid = r.json()["id"]
    Notification.objects.all().delete()
    r = author_api.patch(f"/api/announcements/{aid}/", {"tagged": [a.pk, b.pk]}, format="json")
    assert r.status_code == 200
    assert list(Notification.objects.values_list("user_id", flat=True)) == [b.pk]  # a was already told


def test_tags_must_be_members_of_the_group():
    author_api, _ = client_for("secretaire-general")
    _, suspended = client_for("membre")
    # No group chosen in these tests: the account status counts.
    suspended.status = "suspendu"
    suspended.save()
    r = author_api.post("/api/announcements/", {"title": "x", "tagged": [suspended.pk]}, format="json")
    assert r.status_code == 400 and "tagged" in r.json()
    member_api, _ = client_for("membre")
    assert member_api.get("/api/announcements/recipients/").status_code == 403
