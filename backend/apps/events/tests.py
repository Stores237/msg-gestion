from datetime import timedelta

import pytest
from django.utils import timezone
from rest_framework.test import APIClient

from apps.accounts.factories import UserFactory, give_role
from apps.core.models import AuditLog

from .models import Attendance, Event

pytestmark = pytest.mark.django_db


def client_for(*slugs):
    user = UserFactory()
    for s in slugs:
        give_role(user, s)
    api = APIClient()
    api.force_authenticate(user)
    return api, user


def make_event(days=3, **kw):
    start = timezone.now() + timedelta(days=days)
    return Event.objects.create(kind=kw.pop("kind", "assise"), title=kw.pop("title", "Assise hebdomadaire"), starts_at=start, **kw)


def test_member_sees_upcoming_events_with_own_attendance():
    api, me = client_for("membre")
    soon, later, past = make_event(3), make_event(90), make_event(-10)
    Attendance.objects.create(event=soon, member=me, status="excuse")
    ids = [e["id"] for e in api.get("/api/events/").json()]
    assert ids == [soon.id]
    assert api.get("/api/events/").json()[0]["my_attendance"] == "excuse"
    month = api.get(f"/api/events/?from={(timezone.localdate() - timedelta(days=15)).isoformat()}&to={timezone.localdate().isoformat()}").json()
    assert [e["id"] for e in month] == [past.id]
    assert later.id not in ids


def test_member_cannot_create_events():
    api, _ = client_for("membre")
    r = api.post("/api/events/", {"kind": "assise", "title": "x", "starts_at": timezone.now().isoformat()}, format="json")
    assert r.status_code == 403


def test_secretary_creates_updates_deletes_with_audit():
    api, sg = client_for("secretaire-general")
    start = timezone.now() + timedelta(days=11)
    r = api.post("/api/events/", {"kind": "grande_veillee", "title": "Veillée de la Toussaint", "starts_at": start.isoformat(),
                                  "ends_at": (start + timedelta(hours=7)).isoformat(), "place": "Église", "dress": "interieure"}, format="json")
    assert r.status_code == 201, r.json()
    eid = r.json()["id"]
    assert api.patch(f"/api/events/{eid}/", {"place": "Cathédrale"}, format="json").json()["place"] == "Cathédrale"
    assert api.delete(f"/api/events/{eid}/").status_code == 204
    assert [a.action for a in AuditLog.objects.filter(actor=sg).order_by("created_at")] == ["Événement créé", "Événement modifié", "Événement supprimé"]


def test_end_before_start_refused():
    api, _ = client_for("secretaire-general")
    start = timezone.now() + timedelta(days=1)
    r = api.post("/api/events/", {"kind": "messe", "title": "x", "starts_at": start.isoformat(), "ends_at": (start - timedelta(hours=1)).isoformat()}, format="json")
    assert r.status_code == 400 and "ends_at" in r.json()


def test_roll_call_by_censor_and_counts():
    api, censor = client_for("censeur-general")
    event = make_event(0)
    a, b, c = UserFactory(), UserFactory(), UserFactory()
    r = api.put(f"/api/events/{event.id}/attendance/", {"marks": [
        {"member": a.id, "status": "present"}, {"member": b.id, "status": "absent"}, {"member": 999999, "status": "present"}]}, format="json")
    assert r.status_code == 200
    sheet = r.json()
    assert sheet["counts"]["present"] == 1 and sheet["counts"]["absent"] == 1
    assert sheet["counts"]["unmarked"] == len(sheet["rows"]) - 2
    # Changing a mark, and clearing one.
    api.put(f"/api/events/{event.id}/attendance/", {"marks": [{"member": a.id, "status": "excuse"}, {"member": b.id, "status": ""}]}, format="json")
    assert dict(event.attendance.values_list("member_id", "status")) == {a.id: "excuse"}
    assert c.id in [row["member"] for row in api.get(f"/api/events/{event.id}/attendance/").json()["rows"]]


def test_member_cannot_take_the_roll_call():
    api, _ = client_for("membre")
    event = make_event(0)
    assert api.get(f"/api/events/{event.id}/attendance/").status_code == 403
    assert api.put(f"/api/events/{event.id}/attendance/", {"marks": []}, format="json").status_code == 403


def test_member_warns_of_absence_but_cannot_override_the_censor():
    api, me = client_for("membre")
    event = make_event(2)
    r = api.post(f"/api/events/{event.id}/excuse/", {"reason": "Examen"}, format="json")
    assert r.json() == {"my_attendance": "excuse"}
    Attendance.objects.filter(event=event, member=me).update(status="present")
    r = api.post(f"/api/events/{event.id}/excuse/", {}, format="json")
    assert r.status_code == 409 and r.json()["code"] == "already_marked"


def test_detail_shows_counts_only_to_attendance_viewers():
    event = make_event(1)
    member_api, _ = client_for("membre")
    censor_api, _ = client_for("censeur-general")
    assert "attendance_counts" not in member_api.get(f"/api/events/{event.id}/").json()
    assert censor_api.get(f"/api/events/{event.id}/").json()["attendance_counts"] == {"present": 0, "absent": 0, "excuse": 0}


def test_demo_content_is_replaceable_and_removable():
    from django.core.management import call_command

    from apps.announcements.models import Announcement

    real = make_event(5, title="Vraie assise")
    call_command("add_demo_content")
    call_command("add_demo_content")  # replaces, doesn't duplicate
    assert Event.objects.filter(notes__contains="[démo]").count() == 11
    assert Announcement.objects.count() == 3
    call_command("add_demo_content", "--remove")
    assert list(Event.objects.all()) == [real]
    assert Announcement.objects.count() == 0
