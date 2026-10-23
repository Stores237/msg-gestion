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
