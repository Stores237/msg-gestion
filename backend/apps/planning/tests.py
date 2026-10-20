from datetime import datetime, time, timedelta

import pytest
from django.utils import timezone
from rest_framework.test import APIClient

from apps.accounts.factories import UserFactory, give_role
from apps.accounts.models import User
from apps.core.models import Notification
from apps.events.models import Event

from .models import AlbRotation, Assignment, Request, Service, ServiceGroup, slots_for

pytestmark = pytest.mark.django_db


def client_for(*slugs, user=None):
    user = user or UserFactory()
    for s in slugs:
        give_role(user, s)
    api = APIClient()
    api.force_authenticate(user)
    return api, user


def at(days, hour):
    d = timezone.localdate() + timedelta(days=days)
    return timezone.make_aware(datetime.combine(d, time(hour)))


def service(days=3, hour=9, size=4, title="Grand-messe"):
    e = Event.objects.create(kind="messe", title=title, starts_at=at(days, hour))
    return Service.objects.create(event=e, size=size)


def test_slots_by_size():
    assert len(slots_for(2)) == 2 and slots_for(2)[0] == ("premiere_centrale", "pariso", 0)
    assert len(slots_for(10)) == 10
    assert len(slots_for(12)) == 12 and ("mesanie", "yapoma", 1) in slots_for(12)
    assert slots_for(5) == []


def test_censor_builds_a_week_with_alerts():
    api, _ = client_for("censeur-general")
    s1 = service(days=3, hour=6, size=2, title="Première messe")
    s2 = service(days=3, hour=9, size=4)
    kevin = UserFactory(last_name="Essomba")
    assert api.put(f"/api/planning/services/{s1.id}/slot/", {"post": "premiere_centrale", "side": "pariso", "member": kevin.id}, format="json").status_code == 200
    r = api.put(f"/api/planning/services/{s2.id}/slot/", {"post": "controle", "side": "pariso", "member": kevin.id}, format="json")
    assert r.json()["code"] == "bad_slot"  # size 4 has no contrôle
    r = api.put(f"/api/planning/services/{s2.id}/slot/", {"post": "premiere_centrale", "side": "pariso", "member": kevin.id}, format="json")
    assert (r.status_code, r.json()["code"]) == (409, "double_service")
    r = api.put(f"/api/planning/services/{s2.id}/slot/", {"post": "premiere_centrale", "side": "pariso", "member": kevin.id, "force": True}, format="json")
    assert r.status_code == 200
    week = api.get(f"/api/planning/week/?day={(timezone.localdate() + timedelta(days=3)).isoformat()}").json()
    codes = sorted(a["code"] for a in week["alerts"])
    assert codes == ["double_service", "understaffed", "understaffed"]
    assert all(a["conflict"] for s in week["services"] for a in s["assignments"])


def test_member_on_leave_cannot_be_assigned():
    api, _ = client_for("censeur-general")
    s = service()
    away = UserFactory(status=User.Status.LEAVE)
    r = api.put(f"/api/planning/services/{s.id}/slot/", {"post": "premiere_centrale", "side": "yapoma", "member": away.id}, format="json")
    assert r.json()["code"] == "on_leave"
    cands = {c["member"]: c["flag"] for c in api.get(f"/api/planning/services/{s.id}/candidates/").json()}
    assert cands[away.id] == "on_leave"


def test_candidates_least_solicited_first():
    api, _ = client_for("censeur-general")
    busy, fresh = UserFactory(last_name="Aaa"), UserFactory(last_name="Zzz")
    for d in (1, 2):
        Assignment.objects.create(service=service(days=d, hour=18), post="premiere_centrale", side="pariso", member=busy)
    s = service(days=5)
    order = [c["member"] for c in api.get(f"/api/planning/services/{s.id}/candidates/").json()]
    assert order.index(fresh.id) < order.index(busy.id)


def test_assign_whole_group_skips_leave_and_busy():
    api, _ = client_for("censeur-general")
    chef, a, b, away = UserFactory(), UserFactory(), UserFactory(), UserFactory(status=User.Status.LEAVE)
    g = ServiceGroup.objects.create(name="Saint-Michel", chef=chef)
    g.members.set([chef, a, b, away])
    other = service(days=3, hour=6, size=2)
    Assignment.objects.create(service=other, post="premiere_centrale", side="pariso", member=b)
    s = service(days=3, hour=9, size=4)
    r = api.post(f"/api/planning/services/{s.id}/assign-group/", {"group": g.id}, format="json").json()
    assert r == {"assigned": 2, "still_empty": 2}
    members = set(s.assignments.values_list("member_id", flat=True))
    assert members == {chef.id, a.id}


def test_member_sees_duties_only_after_publish_and_is_notified():
    api, _ = client_for("censeur-general")
    member_api, member = client_for("membre")
    s = service(days=4)
    api.put(f"/api/planning/services/{s.id}/slot/", {"post": "premiere_centrale", "side": "pariso", "member": member.id}, format="json")
    assert member_api.get("/api/planning/mine/").json() == []
    assert member_api.get("/api/planning/week/").status_code == 403  # members don't see the grid
    r = api.post("/api/planning/publish/", {"day": (timezone.localdate() + timedelta(days=4)).isoformat()}, format="json")
    assert r.json()["notified"] == 1
    duties = member_api.get("/api/planning/mine/").json()
    assert len(duties) == 1 and duties[0]["status"] == "pend"
    assert Notification.objects.filter(user=member, kind="duty").count() == 1
    member_api.post(f"/api/planning/assignments/{duties[0]['id']}/confirm/")
    assert Assignment.objects.get().status == "conf"


def test_swap_colleague_accepts_then_chef_approves():
    censor_api, _ = client_for("censeur-general")
    me_api, me = client_for("membre")
    col_api, colleague = client_for("membre")
    s = service(days=4)
    s.published_at = timezone.now()
    s.save()
    a = Assignment.objects.create(service=s, post="premiere_centrale", side="pariso", member=me)
    r = me_api.post(f"/api/planning/assignments/{a.id}/swap/", {"target": colleague.id, "reason": "Examen"}, format="json")
    assert r.status_code == 201
    req = col_api.get("/api/planning/requests/").json()["for_me"][0]
    assert censor_api.post(f"/api/planning/requests/{req['id']}/decide/", {"approve": True}, format="json").json()["code"] == "not_ready"
    col_api.post(f"/api/planning/requests/{req['id']}/answer/", {"accept": True}, format="json")
    assert [x["id"] for x in censor_api.get("/api/planning/requests/").json()["to_decide"]] == [req["id"]]
    censor_api.post(f"/api/planning/requests/{req['id']}/decide/", {"approve": True}, format="json")
    a.refresh_from_db()
    assert a.member == colleague and a.status == "conf"
    assert Request.objects.get().status == "approved"


def test_someone_elses_duty_cannot_be_swapped():
    me_api, _ = client_for("membre")
    other = UserFactory()
    a = Assignment.objects.create(service=service(), post="premiere_centrale", side="pariso", member=other)
    r = me_api.post(f"/api/planning/assignments/{a.id}/swap/", {"absence": True}, format="json")
    assert r.status_code == 403


def test_absence_then_replacement():
    censor_api, _ = client_for("censeur-general")
    me_api, me = client_for("membre")
    repl = UserFactory()
    a = Assignment.objects.create(service=service(), post="controle", side="pariso", member=me)
    rid = me_api.post(f"/api/planning/assignments/{a.id}/swap/", {"absence": True, "reason": "Malade"}, format="json").json()["id"]
    assert censor_api.post(f"/api/planning/requests/{rid}/decide/", {"approve": True}, format="json").json()["code"] == "replacement_required"
    cands = [c["member"] for c in censor_api.get(f"/api/planning/requests/{rid}/candidates/").json()]
    assert repl.id in cands
    censor_api.post(f"/api/planning/requests/{rid}/decide/", {"approve": True, "replacement": repl.id}, format="json")
    a.refresh_from_db()
    assert a.member == repl


def test_alb_rotation_and_fairness():
    censor_api, _ = client_for("censeur-general")
    member_api, member = client_for("membre")
    g = ServiceGroup.objects.create(name="Saint-Michel")
    g.members.add(member)
    monday = timezone.localdate() - timedelta(days=timezone.localdate().weekday())
    r = censor_api.post("/api/planning/albs/", {"week_start": monday.isoformat(), "group": g.id}, format="json").json()
    assert r["status"] == "a_laver"
    assert member_api.post(f"/api/planning/albs/{r['id']}/advance/").json()["status"] == "lavees"
    member_api.post(f"/api/planning/albs/{r['id']}/advance/")
    assert member_api.post(f"/api/planning/albs/{r['id']}/advance/").json()["code"] == "already_returned"
    outsider_api, _ = client_for("membre")
    assert outsider_api.get("/api/planning/albs/").json()["fairness"] == [{"name": "Saint-Michel", "count": 1}]
    assert AlbRotation.objects.get().status == "rendues"


def test_swap_candidates_are_free_colleagues_only():
    me_api, me = client_for("membre")
    free, busy = UserFactory(), UserFactory()
    away = UserFactory(status=User.Status.LEAVE)
    s = service(days=4, hour=9)
    a = Assignment.objects.create(service=s, post="premiere_centrale", side="pariso", member=me)
    Assignment.objects.create(service=service(days=4, hour=18, size=2), post="premiere_centrale", side="pariso", member=busy)
    ids = {c["member"] for c in me_api.get(f"/api/planning/assignments/{a.id}/swap-candidates/").json()}
    assert free.id in ids and busy.id not in ids and away.id not in ids and me.id not in ids
    other_api, _ = client_for("membre")
    assert other_api.get(f"/api/planning/assignments/{a.id}/swap-candidates/").status_code == 404
