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
