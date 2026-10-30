"""Planning, owner 2026-10-30: a published lineup can be reused for another
event; the date matters, so a lineup whose date has passed can't be
published (the planner is told) and none is made for a past event."""

import pytest

from apps.accounts.factories import UserFactory
from apps.accounts.models import User
from apps.core.models import Membership, Notification
from apps.events.models import Event

from . import services
from .models import Assignment, Service
from .tests import at, client_for, service

pytestmark = pytest.mark.django_db


def _published(days=-4, size=4):
    s = service(days=days, size=size)
    guards = [UserFactory(first_name=f"G{i}") for i in range(3)]
    for g, (post, side) in zip(guards, [("premiere_centrale", "pariso"), ("premiere_centrale", "yapoma"),
                                         ("deuxieme_centrale", "pariso")], strict=True):
        Assignment.objects.create(service=s, post=post, side=side, member=g, status=Assignment.Status.CONFIRMED)
    s.published_at = s.event.starts_at
    s.save()
    return s, guards


def test_reuse_a_published_lineup_for_an_upcoming_event():
    api, _ = client_for("formateur")
    source, guards = _published()
    nxt = Event.objects.create(kind="messe", title="Messe du dimanche", starts_at=at(5, 9))
    # The event is offered, an event already planned is not.
    service(days=6)
    offered = [t["event"] for t in api.get(f"/api/planning/services/{source.id}/reuse/").json()]
    assert offered == [nxt.id]

    r = api.post(f"/api/planning/services/{source.id}/reuse/", {"event": nxt.id}, format="json")
    assert r.status_code == 201
    body = r.json()
    assert (body["event"], body["size"], body["published"], body["skipped"]) == (nxt.id, 4, False, [])
    copied = Service.objects.get(event=nxt)
    assert sorted((a.post, a.side, a.member_id, a.status) for a in copied.assignments.all()) == sorted(
        (a.post, a.side, a.member_id, Assignment.Status.PENDING) for a in source.assignments.all())
    # A draft: nobody is told until it is published.
    assert not Notification.objects.filter(user__in=guards).exists()
    # The source is untouched.
    assert source.assignments.count() == 3


def test_reuse_leaves_out_who_cant_serve_that_day():
    api, _ = client_for("formateur")
    source, (away, busy, ok) = _published()
    Membership.objects.filter(user=away).update(status=User.Status.LEAVE)
    nxt = Event.objects.create(kind="messe", title="Messe", starts_at=at(5, 9))
    other = service(days=5, hour=6)
    Assignment.objects.create(service=other, post="controle", side="pariso", member=busy)
    body = api.post(f"/api/planning/services/{source.id}/reuse/", {"event": nxt.id}, format="json").json()
    assert sorted(body["skipped"]) == sorted([away.short_name, busy.short_name])
    assert [a["member"] for a in body["assignments"]] == [ok.id]


def test_reuse_refuses_a_past_or_planned_event():
    api, _ = client_for("formateur")
    source, _ = _published()
    past = Event.objects.create(kind="messe", title="Hier", starts_at=at(-1, 9))
    r = api.post(f"/api/planning/services/{source.id}/reuse/", {"event": past.id}, format="json")
    assert (r.status_code, r.json()["code"]) == (400, "date_passed")
    planned = service(days=4)
    r = api.post(f"/api/planning/services/{source.id}/reuse/", {"event": planned.event_id}, format="json")
    assert (r.status_code, r.json()["code"]) == (409, "already_planned")


def test_reuse_is_for_lineup_makers():
    api, _ = client_for()
    source, _ = _published()
    nxt = Event.objects.create(kind="messe", title="Messe", starts_at=at(5, 9))
    assert api.post(f"/api/planning/services/{source.id}/reuse/", {"event": nxt.id}, format="json").status_code == 403


def test_a_past_draft_is_not_published_and_the_planner_is_told():
    api, _ = client_for("formateur")
    past = service(days=-1)
    Assignment.objects.create(service=past, post="controle", side="pariso", member=UserFactory())
    day = at(-1, 9).date().isoformat()
    week = api.get(f"/api/planning/week/?day={day}").json()
    row = next(s for s in week["services"] if s["id"] == past.id)
    assert row["past"] is True and week["past_drafts"] >= 1

    assert week["publishable"] == 0
    r = api.post("/api/planning/publish/", {"day": day}, format="json")
    assert (r.status_code, r.json()["code"]) == (400, "date_passed")
    past.refresh_from_db()
    assert past.published_at is None
    assert not Notification.objects.filter(title="Nouveau service").exists()


def test_publishing_a_week_skips_its_past_drafts():
    _, by = client_for("formateur")
    past, coming = service(days=-1), service(days=1)
    for s in (past, coming):
        Assignment.objects.create(service=s, post="controle", side="pariso", member=UserFactory())
    # Yesterday and tomorrow aren't always in one week: the service layer.
    assert services.publish([past, coming], by=by) == 1
    past.refresh_from_db()
    coming.refresh_from_db()
    assert past.published_at is None and coming.published_at is not None


def test_no_new_lineup_for_a_past_event():
    api, _ = client_for("formateur")
    past = Event.objects.create(kind="messe", title="Hier", starts_at=at(-1, 9))
    r = api.post("/api/planning/services/", {"event": past.id, "size": 4}, format="json")
    assert (r.status_code, r.json()["code"]) == (400, "date_passed")
