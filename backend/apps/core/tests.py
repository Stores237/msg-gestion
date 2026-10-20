import pytest
from django.test import override_settings

from apps.core import views

pytestmark = pytest.mark.django_db


def test_healthz_touches_the_database(client):
    assert client.get("/healthz/").json() == {"status": "ok"}


def test_task_endpoint_is_404_without_a_configured_token(client):
    assert client.post("/internal/tasks/anything/").status_code == 404


@override_settings(TASK_TRIGGER_TOKEN="s3cret")
def test_task_endpoint_requires_the_right_token(client, monkeypatch):
    ran = []
    monkeypatch.setitem(views.TASKS, "demo", "check")
    monkeypatch.setattr(views, "call_command", lambda name: ran.append(name))
    assert client.post("/internal/tasks/demo/", HTTP_X_TASK_TOKEN="wrong").status_code == 404
    assert client.post("/internal/tasks/demo/", HTTP_X_TASK_TOKEN="s3cret").status_code == 200
    assert ran == ["check"]


@override_settings(SMS_DEV_FALLBACK=False, TWILIO_VERIFY_SERVICE_SID=None)
def test_no_sms_provider_in_production_fails_loudly():
    from apps.core import sms

    with pytest.raises(sms.SmsUnavailable):
        sms.send_code("+237677000001")


def test_notifications_list_and_mark_read():
    from rest_framework.test import APIClient

    from apps.accounts.factories import UserFactory
    from apps.core.notify import notify

    me, other = UserFactory(), UserFactory()
    notify([me, me, other], "member", "Nouveau membre", "x")
    api = APIClient()
    api.force_authenticate(me)
    body = api.get("/api/notifications/").json()
    assert body["unread"] == 1 and len(body["results"]) == 1
    api.post("/api/notifications/read/", {}, format="json")
    assert api.get("/api/notifications/").json()["unread"] == 0


def test_reminders_for_tomorrow_once():
    from datetime import datetime, time, timedelta

    from django.core.management import call_command
    from django.utils import timezone

    from apps.accounts.factories import UserFactory
    from apps.core.models import Notification
    from apps.events.models import Event

    UserFactory(), UserFactory()
    tomorrow = timezone.make_aware(datetime.combine(timezone.localdate() + timedelta(days=1), time(15)))
    Event.objects.create(kind="assise", title="Assise", starts_at=tomorrow, dress="interieure", place="Salle")
    Event.objects.create(kind="assise", title="Plus tard", starts_at=tomorrow + timedelta(days=3))
    call_command("send_reminders")
    call_command("send_reminders")
    assert Notification.objects.filter(kind="reminder").count() == 2
    assert Notification.objects.first().title == "Rappel : Assise demain 15:00"


def test_new_announcement_notifies_everyone_but_author():
    from rest_framework.test import APIClient

    from apps.accounts.factories import UserFactory, give_role
    from apps.core.models import Notification

    sg, a, b = UserFactory(), UserFactory(), UserFactory()
    give_role(sg, "secretaire-general")
    api = APIClient()
    api.force_authenticate(sg)
    api.post("/api/announcements/", {"title": "Répétition"}, format="json")
    assert set(Notification.objects.values_list("user_id", flat=True)) == {a.id, b.id}
