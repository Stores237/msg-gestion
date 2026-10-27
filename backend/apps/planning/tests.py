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


def test_formateur_builds_a_week_with_alerts():
    api, _ = client_for("formateur")
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
    api, _ = client_for("formateur")
    s = service()
    away = UserFactory(status=User.Status.LEAVE)
    r = api.put(f"/api/planning/services/{s.id}/slot/", {"post": "premiere_centrale", "side": "yapoma", "member": away.id}, format="json")
    assert r.json()["code"] == "on_leave"
    cands = {c["member"]: c["flag"] for c in api.get(f"/api/planning/services/{s.id}/candidates/").json()}
    assert cands[away.id] == "on_leave"


def test_candidates_least_solicited_first():
    api, _ = client_for("formateur")
    busy, fresh = UserFactory(last_name="Aaa"), UserFactory(last_name="Zzz")
    # The count is per calendar month: keep all three in one (mid next month).
    today = timezone.localdate()
    mid = ((today.replace(day=1) + timedelta(days=32)).replace(day=15) - today).days
    for d in (mid - 2, mid - 1):
        Assignment.objects.create(service=service(days=d, hour=18), post="premiere_centrale", side="pariso", member=busy)
    s = service(days=mid)
    order = [c["member"] for c in api.get(f"/api/planning/services/{s.id}/candidates/").json()]
    assert order.index(fresh.id) < order.index(busy.id)


def test_assign_whole_group_skips_leave_and_busy():
    api, _ = client_for("formateur")
    c, a, b, away = UserFactory(), UserFactory(), UserFactory(), UserFactory(status=User.Status.LEAVE)
    g = ServiceGroup.objects.create(name="Saint-Michel")
    g.members.set([c, a, b, away])
    other = service(days=3, hour=6, size=2)
    Assignment.objects.create(service=other, post="premiere_centrale", side="pariso", member=b)
    s = service(days=3, hour=9, size=4)
    r = api.post(f"/api/planning/services/{s.id}/assign-group/", {"group": g.id}, format="json").json()
    assert r == {"assigned": 2, "still_empty": 2}
    members = set(s.assignments.values_list("member_id", flat=True))
    assert members == {c.id, a.id}


def test_member_sees_duties_only_after_publish_and_is_notified():
    api, _ = client_for("formateur")
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


def test_swap_colleague_accepts_then_formateur_approves():
    censor_api, _ = client_for("formateur")
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
    censor_api, _ = client_for("formateur")
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
    censor_api, _ = client_for("formateur")
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


# --- Who makes the lineup, and the chef de groupe (owner, 2026-10-23) -----------------


@pytest.mark.parametrize("slug", ["formateur", "formateur-adjoint", "president", "vice-president"])
def test_lineup_makers_can_assign(slug):
    api, _ = client_for(slug)
    s = service()
    r = api.put(f"/api/planning/services/{s.id}/slot/", {"post": "premiere_centrale", "side": "pariso", "member": UserFactory().id}, format="json")
    assert r.status_code == 200


@pytest.mark.parametrize("slug", ["secretaire-general", "secretaire-general-adjoint", "censeur-general", "tresorier"])
def test_other_roles_only_look_at_the_lineup(slug):
    api, _ = client_for(slug)
    s = service()
    assert api.get("/api/planning/week/").status_code == 200
    r = api.put(f"/api/planning/services/{s.id}/slot/", {"post": "premiere_centrale", "side": "pariso", "member": UserFactory().id}, format="json")
    assert r.status_code == 403
    assert api.put(f"/api/planning/services/{s.id}/chef/", {"member": None}, format="json").status_code == 403


def test_lineup_rights_cannot_be_granted_to_another_role():
    from apps.accounts.models import Role
    from apps.accounts.services import RuleViolation, set_role_permissions

    sg = Role.objects.get(slug="secretaire-general")
    with pytest.raises(RuleViolation):
        set_role_permissions(sg, {("calendar.planning", "change"): True}, by=None, reason="essai")


def test_chef_de_groupe_is_no_longer_a_standing_role():
    from apps.accounts.models import Role

    assert Role.objects.get(slug="chef-de-groupe").is_archived
    assert Role.objects.filter(slug="formateur-adjoint", is_archived=False).exists()


def test_president_changes_are_recorded_as_exceptional():
    from apps.core.models import AuditLog

    formateur = UserFactory()
    give_role(formateur, "formateur")
    pres_api, _ = client_for("president")
    form_api, _ = client_for("formateur", user=formateur)
    s = service(days=4)
    form_api.put(f"/api/planning/services/{s.id}/slot/", {"post": "premiere_centrale", "side": "pariso", "member": UserFactory().id}, format="json")
    assert not AuditLog.objects.filter(action__contains="exceptionnel").exists()
    pres_api.put(f"/api/planning/services/{s.id}/slot/", {"post": "premiere_centrale", "side": "yapoma", "member": UserFactory().id}, format="json")
    assert AuditLog.objects.filter(action="Planning modifié à titre exceptionnel", sensitive=True).count() == 1
    pres_api.post("/api/planning/publish/", {"day": (timezone.localdate() + timedelta(days=4)).isoformat()}, format="json")
    assert AuditLog.objects.filter(action="Planning publié à titre exceptionnel").exists()
    assert Notification.objects.filter(user=formateur, title="Planning publié par le bureau").exists()


def test_chef_belongs_to_the_event_and_the_planning_can_change_it():
    """Owner, 2026-10-27: the chef de groupe is designated with the event
    (any active member) and told at once; the planning can change it."""
    api, _ = client_for("formateur")
    guard_api, guard = client_for("membre")
    other = UserFactory()
    s = service(days=4)
    api.put(f"/api/planning/services/{s.id}/slot/", {"post": "premiere_centrale", "side": "pariso", "member": guard.id}, format="json")
    r = api.put(f"/api/planning/services/{s.id}/chef/", {"member": other.id}, format="json").json()
    assert r["chef_id"] == other.id
    r = api.put(f"/api/planning/services/{s.id}/chef/", {"member": guard.id}, format="json").json()
    assert r["chef_id"] == guard.id and r["chef"] == guard.short_name
    assert "chef de groupe" in Notification.objects.filter(user=guard, kind="duty").latest("pk").body
    s.event.refresh_from_db()
    assert s.event.chef_id == guard.id
    api.post("/api/planning/publish/", {"day": (timezone.localdate() + timedelta(days=4)).isoformat()}, format="json")
    duty = guard_api.get("/api/planning/mine/").json()[0]
    assert duty["is_chef"] and duty["chef"] == guard.full_name
    # Freeing the chef's post keeps them chef of the event.
    api.put(f"/api/planning/services/{s.id}/slot/", {"post": "premiere_centrale", "side": "pariso", "member": None}, format="json")
    s.event.refresh_from_db()
    assert s.event.chef_id == guard.id
    # A mass needs a chef: it can be changed, not removed.
    assert api.put(f"/api/planning/services/{s.id}/chef/", {"member": None}, format="json").json()["code"] == "chef_required"


def test_absence_goes_to_formateurs_and_the_days_chef():
    formateur = UserFactory()
    give_role(formateur, "formateur")
    me_api, me = client_for("membre")
    chef = UserFactory()
    s = service(days=4)
    a = Assignment.objects.create(service=s, post="controle", side="pariso", member=me)
    Assignment.objects.create(service=s, post="controle", side="yapoma", member=chef)
    s.event.chef = chef
    s.event.save()
    me_api.post(f"/api/planning/assignments/{a.id}/swap/", {"absence": True, "reason": "Malade"}, format="json")
    assert set(Notification.objects.filter(title="Absence déclarée").values_list("user", flat=True)) == {formateur.id, chef.id}
