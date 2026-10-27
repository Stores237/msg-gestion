"""Design features that were missing (owner, 2026-10-27): leave with an end
date, per group; drag a guard to another cell; dress details and place
details on events."""

from datetime import timedelta
from io import StringIO

import pytest
from django.core.management import call_command
from django.utils import timezone

from apps.accounts.factories import UserFactory
from apps.accounts.models import User
from apps.backoffice.test_group_delete import login  # noqa: F401 - fixture
from apps.core.models import AuditLog, Membership, Notification
from apps.events.models import DressCode, Event

from . import services
from .models import Assignment, Service
from .tests import client_for, service

pytestmark = pytest.mark.django_db


def _on_leave(user, until=None):
    Membership.objects.filter(user=user).update(status=User.Status.LEAVE, leave_until=until)


# --- Leave, per group, with an end date --------------------------------------------


def test_leave_is_read_in_this_group_with_its_end_date():
    from apps.core.models import Group
    from apps.core.test_groups import app_client

    _, planner = client_for("formateur")
    api = app_client(planner, Group.objects.order_by("pk").first())  # as the phone sends it, with X-Group
    away, ok = UserFactory(), UserFactory()
    until = timezone.localdate() + timedelta(days=19)
    _on_leave(away, until)
    # The account itself says "conge" (another group), but here they're active.
    User.objects.filter(pk=ok.pk).update(status=User.Status.LEAVE)
    s = service()
    r = api.put(f"/api/planning/services/{s.id}/slot/", {"post": "premiere_centrale", "side": "pariso", "member": away.id}, format="json")
    assert r.json()["code"] == "on_leave" and f"jusqu’au {until:%d/%m}" in r.json()["detail"]
    r = api.put(f"/api/planning/services/{s.id}/slot/", {"post": "premiere_centrale", "side": "yapoma", "member": ok.id}, format="json")
    assert r.status_code == 200
    cand = {c["member"]: c for c in api.get(f"/api/planning/services/{s.id}/candidates/").json()}
    assert cand[away.id]["flag"] == "on_leave" and cand[away.id]["leave_until"] == until.isoformat()


def test_a_guard_put_on_leave_after_the_lineup_shows_as_a_conflict():
    s = service()
    a = Assignment.objects.create(service=s, post="controle", side="pariso", member=UserFactory())
    _on_leave(a.member, timezone.localdate() + timedelta(days=3))
    assert a.pk in services.conflicts([s])
    alert = next(x for x in services.alerts([s]) if x["code"] == "on_leave")
    assert alert["until"] == timezone.localdate() + timedelta(days=3)


def test_leave_ends_by_itself_after_its_last_day():
    back, still = UserFactory(), UserFactory()
    _on_leave(back, timezone.localdate() - timedelta(days=1))
    _on_leave(still, timezone.localdate())
    call_command("send_reminders", stdout=StringIO())
    assert Membership.objects.get(user=back).status == User.Status.ACTIVE
    assert Membership.objects.get(user=back).leave_until is None
    assert Membership.objects.get(user=still).status == User.Status.LEAVE
    assert Notification.objects.filter(user=back, title="Retour de congé").exists()
    assert AuditLog.objects.filter(action="Retour de congé").count() == 1


def test_back_office_puts_a_member_on_leave_until_a_date(login):  # noqa: F811
    from apps.core.models import Group

    member = UserFactory(membership=Group.objects.order_by("pk").first())
    a = login("677000001")
    until = timezone.localdate() + timedelta(days=10)
    r = a.post(f"/bo/utilisateurs/{member.pk}/", {"action": "leave", "until": until.isoformat(), "reason": "Examens"})
    assert r.status_code in (200, 302)
    m = Membership.objects.get(user=member)
    assert (m.status, m.leave_until) == (User.Status.LEAVE, until)
    assert "jusqu’au" in a.get(f"/bo/utilisateurs/{member.pk}/").content.decode()
    a.post(f"/bo/utilisateurs/{member.pk}/", {"action": "reactivate", "reason": "Retour"})
    m.refresh_from_db()
    assert (m.status, m.leave_until) == (User.Status.ACTIVE, None)


# --- Drag a guard to another cell ---------------------------------------------------


def test_drag_to_a_free_cell_moves_and_to_a_filled_one_swaps():
    api, _ = client_for("formateur")
    s = service(size=4)
    x = Assignment.objects.create(service=s, post="premiere_centrale", side="pariso", member=UserFactory())
    y = Assignment.objects.create(service=s, post="premiere_centrale", side="yapoma", member=UserFactory())
    r = api.put(f"/api/planning/assignments/{x.id}/move/", {"post": "deuxieme_centrale", "side": "pariso"}, format="json")
    assert r.status_code == 200
    x.refresh_from_db()
    assert (x.post, x.side) == ("deuxieme_centrale", "pariso")
    api.put(f"/api/planning/assignments/{x.id}/move/", {"post": "premiere_centrale", "side": "yapoma"}, format="json")
    x.refresh_from_db()
    y.refresh_from_db()
    assert (x.post, x.side) == ("premiere_centrale", "yapoma") and (y.post, y.side) == ("deuxieme_centrale", "pariso")


def test_drag_to_another_service_checks_like_a_new_assignment():
    api, _ = client_for("formateur")
    first, second = service(days=3, hour=7, size=6), service(days=3, hour=18, size=6)
    guard = UserFactory()
    a = Assignment.objects.create(service=first, post="controle", side="pariso", member=guard)
    taken = Assignment.objects.create(service=second, post="controle", side="pariso", member=UserFactory())
    r = api.put(f"/api/planning/assignments/{a.id}/move/", {"service": second.id, "post": "controle", "side": "pariso"}, format="json")
    assert r.status_code == 409 and r.json()["code"] == "slot_taken"
    assert Assignment.objects.filter(pk=a.pk).exists()  # nothing changed
    r = api.put(f"/api/planning/assignments/{a.id}/move/", {"service": second.id, "post": "controle", "side": "yapoma"}, format="json")
    assert r.status_code == 200
    assert not first.assignments.exists() and second.assignments.filter(member=guard).exists()
    assert taken.pk in set(second.assignments.values_list("pk", flat=True))
    # Only the lineup makers drag.
    other, _ = client_for("secretaire-general")
    moved = second.assignments.get(member=guard)
    assert other.put(f"/api/planning/assignments/{moved.id}/move/", {"post": "controle", "side": "pariso"}, format="json").status_code == 403


def test_a_published_guard_moved_is_told():
    api, _ = client_for("formateur")
    s = service(size=6)
    s.published_at = timezone.now()
    s.save()
    a = Assignment.objects.create(service=s, post="controle", side="pariso", member=UserFactory())
    api.put(f"/api/planning/assignments/{a.id}/move/", {"post": "controle", "side": "yapoma"}, format="json")
    assert Notification.objects.filter(user=a.member, kind="duty").exists()


# --- Dress details and place details -----------------------------------------------


def test_events_carry_the_dress_detail_and_the_place_detail():
    DressCode.objects.filter(slug="interieure").update(description="Ce que la tenue comprend")
    api, me = client_for("secretaire-general")
    start = timezone.now() + timedelta(days=2)
    r = api.post("/api/events/", {"kind": "assise", "title": "Assise", "starts_at": start.isoformat(), "chef": me.pk,
                                  "place": "Salle paroissiale", "place_detail": "Quartier, ville", "dress": "interieure"},
                 format="json").json()
    assert r["place_detail"] == "Quartier, ville" and r["dress_detail"] == "Ce que la tenue comprend"
    dresses = {d["slug"]: d for d in api.get("/api/settings/").json()["dress_codes"]}
    assert dresses["interieure"]["description"] == "Ce que la tenue comprend"
    assert Event.objects.get(pk=r["id"]).place_detail == "Quartier, ville"
    assert Service.objects.count() == 0


# --- The event's chef de groupe validates swaps (design) --------------------------


def test_the_events_chef_validates_swaps_for_their_own_event_only():
    from .models import Request

    chef_api, chef = client_for("membre")
    other_chef_api, _ = client_for("membre")
    s = service(size=6)
    s.event.chef = chef
    s.event.save()
    me, colleague = UserFactory(), UserFactory()
    a = Assignment.objects.create(service=s, post="controle", side="pariso", member=me)
    req = Request.objects.create(kind="swap", assignment=a, requester=me, target=colleague, status="proposed")
    colleague_api = client_for("membre")[0]
    colleague_api.force_authenticate(colleague)
    colleague_api.post(f"/api/planning/requests/{req.pk}/answer/", {"accept": True}, format="json")
    assert Notification.objects.filter(user=chef, title="Échange à valider").exists()
    assert [r["id"] for r in chef_api.get("/api/planning/requests/").json()["to_decide"]] == [req.pk]
    assert other_chef_api.get("/api/planning/requests/").json()["to_decide"] == []
    assert other_chef_api.post(f"/api/planning/requests/{req.pk}/decide/", {"approve": True}, format="json").status_code == 403
    assert chef_api.post(f"/api/planning/requests/{req.pk}/decide/", {"approve": True}, format="json").status_code == 200
    a.refresh_from_db()
    assert a.member_id == colleague.pk
