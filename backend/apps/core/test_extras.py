from datetime import datetime, time, timedelta

import pytest
from django.core.management import call_command
from django.utils import timezone
from rest_framework.test import APIClient

from apps.accounts.factories import UserFactory, give_role
from apps.accounts.models import RoleRequest
from apps.core.models import Notification, Settings
from apps.events.models import Attendance, Event
from apps.finances.models import Due, Entry

pytestmark = pytest.mark.django_db


def client_for(*slugs):
    user = UserFactory()
    for s in slugs:
        give_role(user, s)
    api = APIClient()
    api.force_authenticate(user)
    return api, user


def test_settings_feed_the_app():
    api, _ = client_for("membre")
    st = Settings.get()
    st.fee_death = 3000
    st.save()
    body = api.get("/api/settings/").json()
    assert body["fees"]["deces"] == 3000 and 3000 in body["quick_amounts"]


def test_registration_fee_goes_to_cash_book_pending():
    """Paid to the leader with the access request: owed at approval, and the
    leader's line waits for the trésorier."""
    from apps.members import services as access
    from apps.members.models import AccessRequest

    api, sg = client_for("secretaire-general")
    r = api.post("/api/members/access-requests/", {"last_name": "Ndjock", "first_name": "Patrick", "phone": "674583902", "registration_paid": True}, format="json")
    assert r.status_code == 201, r.json()
    member = access.approve(AccessRequest.objects.get(pk=r.json()["id"]), by=UserFactory()).user
    due = Due.objects.get(member=member)
    entry = Entry.objects.get(due=due)
    assert (due.kind, due.amount, entry.amount, entry.status, entry.created_by) == ("inscription", 500, 500, "pending", sg)
    r2 = api.post("/api/members/access-requests/", {"last_name": "B", "first_name": "S", "phone": "672905114"}, format="json")
    other = access.approve(AccessRequest.objects.get(pk=r2.json()["id"]), by=UserFactory()).user
    assert Due.objects.filter(member=other).exists() and not Entry.objects.filter(member=other).exists()


def test_profile_shows_last_four_assises():
    api, _ = client_for("secretaire-general")
    member = UserFactory()
    past = [Event.objects.create(kind="assise", title="Assise", starts_at=timezone.now() - timedelta(days=7 * i + 1)) for i in range(5)]
    for e, st in zip(past[:4], ["present", "present", "excuse", "present"], strict=True):
        Attendance.objects.create(event=e, member=member, status=st)
    att = api.get(f"/api/members/{member.id}/").json()["attendance"]
    assert (att["present"], att["excuse"], att["absent"], att["of"]) == (3, 1, 0, 4)


def test_role_request_by_bureau_member():
    api, _ = client_for("formateur")
    member_api, _ = client_for("membre")
    target = UserFactory()
    r = api.post(f"/api/members/{target.id}/role-requests/", {"role": "censeur-du-jour", "reason": "Grande veillée"}, format="json")
    assert r.status_code == 201
    assert api.post(f"/api/members/{target.id}/role-requests/", {"role": "super-admin", "reason": "x"}, format="json").json()["code"] == "bad_role"
    assert member_api.post(f"/api/members/{target.id}/role-requests/", {"role": "censeur-du-jour", "reason": "x"}, format="json").status_code == 403
    assert RoleRequest.objects.get().status == "pending"
    assert "censeur-du-jour" in [x["slug"] for x in api.get("/api/members/requestable-roles/").json()]


def test_remind_unread_only_notifies_who_has_not_read():
    api, sg = client_for("secretaire-general")
    reader, lazy = UserFactory(), UserFactory()
    give_role(reader, "membre")
    aid = api.post("/api/announcements/", {"title": "AG"}, format="json").json()["id"]
    reader_api = APIClient()
    reader_api.force_authenticate(reader)
    reader_api.post(f"/api/announcements/{aid}/read/")
    Notification.objects.all().delete()
    assert api.post(f"/api/announcements/{aid}/remind/").json()["reminded"] == 1
    assert list(Notification.objects.values_list("user_id", flat=True)) == [lazy.id]


def test_reminder_preferences():
    api, me = client_for("membre")
    assert api.patch("/api/me/preferences/", {"remind_eve": False, "remind_2h": True}, format="json").json() == {"remind_eve": False, "remind_2h": True}
    other = UserFactory()
    tomorrow = timezone.make_aware(datetime.combine(timezone.localdate() + timedelta(days=1), time(15)))
    Event.objects.create(kind="assise", title="Assise", starts_at=tomorrow)
    soon = Event.objects.create(kind="messe", title="Messe", starts_at=timezone.now() + timedelta(minutes=120))
    call_command("send_reminders")
    call_command("send_soon_reminders")
    call_command("send_soon_reminders")
    eve = set(Notification.objects.filter(title__contains="demain").values_list("user_id", flat=True))
    two_h = set(Notification.objects.filter(target__id=soon.id, target__when="2h").values_list("user_id", flat=True))
    assert me.id not in eve and other.id in eve
    assert two_h == {me.id}


def test_pdf_exports_need_export_right(settings, tmp_path):
    tre_api, _ = client_for("tresorier")
    member_api, _ = client_for("membre")
    r = tre_api.get("/api/finances/report/pdf/?year=2026&quarter=3")
    assert r.status_code == 200 and r.json()["url"].endswith(".pdf")
    assert tre_api.get("/api/finances/entries/pdf/").status_code == 200
    assert member_api.get("/api/finances/entries/pdf/").status_code == 403


def test_bureau_home_blocks_follow_permissions():
    tre_api, _ = client_for("tresorier")
    member_api, _ = client_for("membre")
    assert set(tre_api.get("/api/home/bureau/").json()) == {"members_active", "to_validate", "collections", "unfilled"}
    assert member_api.get("/api/home/bureau/").json() == {}


def test_role_of_the_day_requested_for_an_active_member_without_role():
    """Owner, 2026-10-23: président, censeur, secrétaire, formateur,
    commissaire aux comptes or trésorier "du jour", for an active member
    with no role."""
    from datetime import date

    api, _ = client_for("formateur")
    daily = {r["slug"] for r in api.get("/api/members/requestable-roles/?daily=1").json()}
    assert daily == {"president", "censeur-du-jour", "secretaire-general", "formateur", "commissaire-aux-comptes", "tresorier"}
    target = UserFactory()
    give_role(target, "membre")
    tomorrow = (timezone.localdate() + timedelta(days=1)).isoformat()
    body = {"role": "tresorier", "reason": "Kermesse", "daily": True, "day": tomorrow}
    r = api.post(f"/api/members/{target.id}/role-requests/", body, format="json")
    assert r.status_code == 201
    rr = RoleRequest.objects.get()
    assert (rr.role.slug, str(rr.starts_on), str(rr.ends_on)) == ("tresorier", tomorrow, tomorrow)
    # Same member, same day again: refused; a past day too.
    assert api.post(f"/api/members/{target.id}/role-requests/", body, format="json").json()["code"] == "already_requested"
    past = {**body, "day": "2020-01-01"}
    assert api.post(f"/api/members/{target.id}/role-requests/", past, format="json").json()["code"] == "past_day"
    # A role that isn't a day role, a member who already has a role, one on leave.
    assert api.post(f"/api/members/{target.id}/role-requests/", {**body, "role": "vice-president"}, format="json").json()["code"] == "bad_role"
    holder = UserFactory()
    give_role(holder, "secretaire-general-adjoint")
    assert api.post(f"/api/members/{holder.id}/role-requests/", body, format="json").json()["code"] == "has_role"
    on_leave = UserFactory(status="conge")
    assert api.post(f"/api/members/{on_leave.id}/role-requests/", body, format="json").json()["code"] == "not_active"
    assert isinstance(date.fromisoformat(tomorrow), date)


@pytest.mark.parametrize("slug,shown", [("tresorier", "Trésorier"), ("commissaire-aux-comptes", "Commissaire aux comptes"),
                                        ("censeur-general", "Censeur général"), ("vice-president", "Vice-président")])
def test_every_bureau_member_posts_and_acts_on_the_calendar_with_their_role(slug, shown):
    """Owner, 2026-10-26: all the bureau make announcements and act on the
    calendar; their role is shown on what they post."""
    api, user = client_for("membre", slug)
    r = api.post("/api/announcements/", {"title": "Collecte", "body": "Samedi"}, format="json")
    assert r.status_code == 201, r.json()
    feed = api.get("/api/announcements/").json()
    item = next(a for a in feed["results"] if a["title"] == "Collecte")
    assert item["author_role"] == shown
    start = timezone.now() + timedelta(days=3)
    r = api.post("/api/events/", {"kind": "assise", "title": "Assise", "starts_at": start.isoformat(), "chef": user.pk}, format="json")
    assert r.status_code == 201, r.json()
    assert r.json()["created_by_role"] == shown and r.json()["created_by_name"] == user.short_name
    eid = r.json()["id"]
    assert api.patch(f"/api/events/{eid}/", {"place": "Salle paroissiale"}, format="json").status_code == 200
    assert api.delete(f"/api/events/{eid}/").status_code in (200, 204)


def test_plain_member_still_cannot_post_and_role_of_the_day_is_named():
    api, _ = client_for("membre")
    assert api.post("/api/announcements/", {"title": "x"}, format="json").status_code == 403
    assert api.post("/api/events/", {"kind": "assise", "title": "x", "starts_at": timezone.now().isoformat()}, format="json").status_code == 403
    day = UserFactory()
    give_role(day, "membre")
    give_role(day, "president", starts_on=timezone.localdate(), ends_on=timezone.localdate())
    assert day.display_role() == "Président du jour"
    censor = UserFactory()
    give_role(censor, "censeur-du-jour", starts_on=timezone.localdate(), ends_on=timezone.localdate())
    assert censor.display_role() == "Censeur du jour"


def _poster(*perms):
    """A member whose only role can post (view + create), nothing more."""
    from apps.accounts.models import Role, RolePermission

    role = Role.objects.create(slug=f"poster-{len(perms)}-{Role.objects.count()}", name="Responsable des annonces")
    for res in perms:
        for act in ("view", "create"):
            RolePermission.objects.create(role=role, resource=res, action=act)
    api, user = client_for("membre", role.slug)
    return api, user


def test_the_author_edits_and_deletes_their_own_announcement_only():
    """Owner, 2026-10-26: whoever posts can edit and delete what they posted."""
    from apps.announcements.models import Announcement

    api, me = _poster("announcements.posts")
    other_api, _ = _poster("announcements.posts")
    aid = api.post("/api/announcements/", {"title": "Répétition", "body": "Jeudi"}, format="json").json()["id"]
    mine = api.get(f"/api/announcements/{aid}/").json()
    assert mine["can_edit"] and mine["can_delete"]
    theirs = other_api.get(f"/api/announcements/{aid}/").json()
    assert not theirs["can_edit"] and not theirs["can_delete"]
    r = api.patch(f"/api/announcements/{aid}/", {"title": "Répétition déplacée", "body": "Vendredi", "pinned": True}, format="json")
    assert r.status_code == 200 and r.json()["title"] == "Répétition déplacée"
    assert not Announcement.objects.get(pk=aid).pinned  # pinning isn't the author's
    assert other_api.patch(f"/api/announcements/{aid}/", {"title": "x"}, format="json").status_code == 403
    assert other_api.delete(f"/api/announcements/{aid}/").status_code == 403
    assert api.delete(f"/api/announcements/{aid}/").status_code == 204
    assert not Announcement.objects.filter(pk=aid).exists()


def test_the_author_edits_and_deletes_their_own_event_only():
    from apps.events.models import Event

    api, me = _poster("calendar.events")
    other_api, _ = _poster("calendar.events")
    start = timezone.now() + timedelta(days=4)
    eid = api.post("/api/events/", {"kind": "assise", "title": "Répétition", "starts_at": start.isoformat(), "chef": me.pk}, format="json").json()["id"]
    assert api.get(f"/api/events/{eid}/").json()["can_edit"]
    assert not other_api.get(f"/api/events/{eid}/").json()["can_delete"]
    assert other_api.patch(f"/api/events/{eid}/", {"place": "x"}, format="json").status_code == 403
    assert api.patch(f"/api/events/{eid}/", {"place": "Salle paroissiale"}, format="json").json()["place"] == "Salle paroissiale"
    assert other_api.delete(f"/api/events/{eid}/").status_code == 403
    assert api.delete(f"/api/events/{eid}/").status_code == 204
    assert not Event.objects.filter(pk=eid).exists()
    # Someone with the calendar's change right still edits anyone's event.
    eid = api.post("/api/events/", {"kind": "assise", "title": "Autre", "starts_at": start.isoformat(), "chef": me.pk}, format="json").json()["id"]
    sg, _ = client_for("secretaire-general")
    assert sg.patch(f"/api/events/{eid}/", {"title": "Autre (modifié)"}, format="json").status_code == 200
