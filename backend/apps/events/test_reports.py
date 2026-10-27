"""Event types, the chef de groupe and their report (owner, 2026-10-27)."""

from datetime import timedelta
from io import StringIO

import pytest
from django.core.files.uploadedfile import SimpleUploadedFile
from django.core.management import call_command
from django.utils import timezone

from apps.accounts.factories import UserFactory, give_role
from apps.core.models import AuditLog, Notification

from .models import ActivityType, Event
from .tests import client_for

pytestmark = pytest.mark.django_db

PDF = b"%PDF-1.4\n1 0 obj<<>>endobj\ntrailer<<>>\n%%EOF"


def _post(api, **kw):
    start = timezone.now() + timedelta(days=2)
    body = {"kind": "assise", "title": "Assise", "starts_at": start.isoformat(), **kw}
    return api.post("/api/events/", body, format="json")


def test_messe_is_inside_or_outside_and_service_exterieur_is_gone():
    assert ActivityType.objects.get(slug="messe").has_scope
    assert ActivityType.objects.get(slug="service_exterieur").is_archived
    assert not ActivityType.objects.get(slug="reunion").needs_chef
    api, me = client_for("secretaire-general")
    r = _post(api, kind="messe", title="Messe", chef=me.pk)
    assert r.status_code == 400 and r.json()["scope"][0] == "Choisissez intérieur ou extérieur."
    r = _post(api, kind="messe", title="Messe", chef=me.pk, scope="exterieur")
    assert r.status_code == 201 and r.json()["scope"] == "exterieur"
    # A type without inside/outside never keeps one.
    assert _post(api, chef=me.pk, scope="exterieur").json()["scope"] == ""
    kinds = {k["slug"]: k for k in api.get("/api/settings/").json()["activity_types"]}
    assert "service_exterieur" not in kinds and kinds["messe"]["has_scope"] and not kinds["reunion"]["needs_chef"]


def test_other_type_is_written_by_the_author():
    api, me = client_for("secretaire-general")
    assert _post(api, kind="autre", title="Kermesse", chef=me.pk).json()["kind_other"] == ["Précisez le type d’événement."]
    r = _post(api, kind="autre", title="Kermesse", chef=me.pk, kind_other="  Kermesse paroissiale ")
    assert r.status_code == 201 and r.json()["kind_other"] == "Kermesse paroissiale"
    assert _post(api, chef=me.pk, kind_other="ignoré").json()["kind_other"] == ""


def test_chef_is_designated_at_creation_except_for_meetings_and_told():
    api, me = client_for("secretaire-general")
    chef = UserFactory()
    assert _post(api).json()["chef"] == ["Désignez le chef de groupe."]
    r = _post(api, kind="reunion", title="Réunion du bureau", chef=chef.pk)
    assert r.status_code == 201 and r.json()["chef"] is None and r.json()["report_status"] == ""
    assert not Notification.objects.filter(user=chef).exists()
    r = _post(api, chef=chef.pk)
    assert r.status_code == 201 and r.json()["chef_name"] == chef.short_name and r.json()["report_status"] == "pending"
    note = Notification.objects.get(user=chef, kind="duty")
    assert note.title == "Chef de groupe" and "Rapport à remettre au formateur avant le" in note.body
    assert note.target == {"type": "event", "id": r.json()["id"]}
    # A suspended or unknown member can't be chef.
    gone = UserFactory(status="suspendu")
    assert "chef" in _post(api, chef=gone.pk).json()
    # Changing the chef tells the new one.
    other = UserFactory()
    api.patch(f"/api/events/{r.json()['id']}/", {"chef": other.pk}, format="json")
    assert Notification.objects.filter(user=other, kind="duty").exists()


def _ended_event(chef, hours_ago=2):
    start = timezone.now() - timedelta(hours=hours_ago + 2)
    return Event.objects.create(kind="assise", title="Assise", starts_at=start, ends_at=start + timedelta(hours=2), chef=chef)


def _readers():
    people = {}
    for slug in ("formateur", "formateur-adjoint", "secretaire-general", "censeur-general", "vice-censeur"):
        people[slug] = UserFactory()
        give_role(people[slug], slug)
    return people


def test_chef_reports_in_the_app_and_it_goes_to_the_formateur_with_copies():
    readers = _readers()
    chef_api, chef = client_for("membre")
    other_api, _ = client_for("membre")
    e = _ended_event(chef)
    assert chef_api.get(f"/api/events/{e.pk}/").json()["can_report"]
    assert other_api.post(f"/api/events/{e.pk}/report/", {"body": "x"}).json()["code"] == "chef_only"
    assert chef_api.post(f"/api/events/{e.pk}/report/", {"body": "  "}).json()["code"] == "report_empty"
    r = chef_api.post(f"/api/events/{e.pk}/report/", {"body": "RAS. 8 gardes présents."})
    assert r.status_code == 201 and not r.json()["late"] and r.json()["file_url"] is None
    to = Notification.objects.get(user=readers["formateur"], kind="report")
    assert to.title.startswith("Rapport : Assise") and "En copie" in to.body
    for slug in ("formateur-adjoint", "secretaire-general", "censeur-general", "vice-censeur"):
        assert Notification.objects.get(user=readers[slug], kind="report").title.startswith("Copie · Rapport")
    assert AuditLog.objects.filter(action="Rapport remis", object_id=str(e.pk)).exists()
    # Who reads it: the chef and the readers; not other members.
    assert other_api.get(f"/api/events/{e.pk}/report/").status_code == 403
    assert chef_api.get(f"/api/events/{e.pk}/report/").json()["body"] == "RAS. 8 gardes présents."
    form_api = client_for("membre")[0]
    form_api.force_authenticate(readers["vice-censeur"])
    body = form_api.get(f"/api/events/{e.pk}/").json()
    assert body["report_status"] == "submitted" and body["can_read_report"] and not body["can_report"]
    # Within the 24 h the chef may hand it in again.
    assert chef_api.post(f"/api/events/{e.pk}/report/", {"body": "RAS. 9 gardes."}).status_code == 201


def test_chef_attaches_a_pdf_only():
    chef_api, chef = client_for("membre")
    e = _ended_event(chef)
    bad = SimpleUploadedFile("rapport.pdf", b"\x89PNG\r\n\x1a\nxxxx", content_type="application/pdf")
    assert chef_api.post(f"/api/events/{e.pk}/report/", {"file": bad}, format="multipart").json()["code"] == "file_type"
    pdf = SimpleUploadedFile("rapport-assise.pdf", PDF, content_type="application/pdf")
    r = chef_api.post(f"/api/events/{e.pk}/report/", {"file": pdf}, format="multipart")
    assert r.status_code == 201 and r.json()["file_name"] == "rapport-assise.pdf" and r.json()["file_url"]


def test_not_before_the_event_and_late_after_24h_then_locked():
    chef_api, chef = client_for("membre")
    future = Event.objects.create(kind="assise", title="Assise", starts_at=timezone.now() + timedelta(days=1), chef=chef)
    assert chef_api.post(f"/api/events/{future.pk}/report/", {"body": "x"}).json()["code"] == "too_early"
    old = _ended_event(chef, hours_ago=30)
    assert chef_api.get(f"/api/events/{old.pk}/").json()["report_status"] == "missing"
    r = chef_api.post(f"/api/events/{old.pk}/report/", {"body": "En retard, désolé."})
    assert r.status_code == 201 and r.json()["late"]
    assert chef_api.get(f"/api/events/{old.pk}/").json()["report_status"] == "late"
    assert chef_api.post(f"/api/events/{old.pk}/report/", {"body": "y"}).json()["code"] == "report_locked"


def test_job_reminds_the_chef_then_tells_the_formateur_once():
    readers = _readers()
    chef = UserFactory()
    ended = _ended_event(chef, hours_ago=1)
    overdue = _ended_event(chef, hours_ago=26)
    for _ in range(2):  # twice: each notification goes once
        call_command("send_soon_reminders", stdout=StringIO())
    reminders = Notification.objects.filter(user=chef, kind="report")
    assert reminders.filter(title="Rapport attendu : Assise", target__id=ended.pk).count() == 1
    assert reminders.filter(title__startswith="Rapport non remis", target__id=overdue.pk).count() == 1
    late = Notification.objects.filter(user=readers["formateur"], title__startswith="Rapport non remis")
    assert late.count() == 1 and late.get().target["id"] == overdue.pk
    assert Notification.objects.filter(user=readers["vice-censeur"], title__startswith="Rapport non remis").count() == 1


def test_once_a_bureau_member_opens_the_report_the_chef_cannot_change_it():
    """Owner, 2026-10-27: no change after a board member has opened it."""
    readers = _readers()
    chef_api, chef = client_for("membre")
    e = _ended_event(chef)
    chef_api.post(f"/api/events/{e.pk}/report/", {"body": "Première version."})
    # The chef reading their own report doesn't lock it.
    chef_api.get(f"/api/events/{e.pk}/report/")
    assert chef_api.post(f"/api/events/{e.pk}/report/", {"body": "Deuxième version."}).status_code == 201
    sec = client_for("membre")[0]
    sec.force_authenticate(readers["secretaire-general"])
    r = sec.get(f"/api/events/{e.pk}/report/").json()
    assert r["body"] == "Deuxième version." and r["read_by_name"] == readers["secretaire-general"].short_name
    body = chef_api.get(f"/api/events/{e.pk}/").json()
    assert not body["can_report"] and body["report_read_by"] == readers["secretaire-general"].short_name
    r = chef_api.post(f"/api/events/{e.pk}/report/", {"body": "Trop tard."})
    assert r.status_code == 409 and r.json()["code"] == "report_read"
    assert Notification.objects.filter(user=chef, title="Rapport lu : Assise").count() == 1
    # A second reader doesn't change who opened it first.
    form = client_for("membre")[0]
    form.force_authenticate(readers["formateur"])
    assert form.get(f"/api/events/{e.pk}/report/").json()["read_by_name"] == readers["secretaire-general"].short_name
    assert AuditLog.objects.filter(action="Rapport ouvert").count() == 1


def test_roll_call_lists_only_the_lineup_with_each_post():
    """Owner, 2026-10-27: for an event with a lineup, only those lined up are
    on the presence list, with what they served as."""
    from apps.planning.models import Assignment, Service

    censor_api, _ = client_for("censeur-general")
    guard_a, guard_b, chef, outsider = UserFactory(), UserFactory(), UserFactory(), UserFactory()
    for u in (guard_a, outsider):
        give_role(u, "membre")
    start = timezone.now() + timedelta(hours=1)
    mass = Event.objects.create(kind="messe", scope="exterieur", title="Messe", starts_at=start, chef=chef)
    s = Service.objects.create(event=mass, size=2)
    Assignment.objects.create(service=s, post="premiere_centrale", side="yapoma", member=guard_b)
    Assignment.objects.create(service=s, post="premiere_centrale", side="pariso", member=guard_a)
    sheet = censor_api.get(f"/api/events/{mass.pk}/attendance/").json()
    assert sheet["lineup"]
    assert [(r["member"], r["duty"]) for r in sheet["rows"]] == [
        (chef.pk, {"post": "", "side": "", "chef": True}),
        (guard_a.pk, {"post": "premiere_centrale", "side": "pariso", "chef": False}),
        (guard_b.pk, {"post": "premiere_centrale", "side": "yapoma", "chef": False}),
    ]
    # Marks for someone not lined up are ignored.
    r = censor_api.put(f"/api/events/{mass.pk}/attendance/", {"marks": [
        {"member": guard_a.pk, "status": "present"}, {"member": outsider.pk, "status": "present"}]}, format="json")
    assert r.json()["counts"]["present"] == 1
    # An assise without a lineup still lists everyone.
    assise = Event.objects.create(kind="assise", title="Assise", starts_at=start, chef=chef)
    rows = censor_api.get(f"/api/events/{assise.pk}/attendance/").json()["rows"]
    assert outsider.pk in {r["member"] for r in rows} and all(r["duty"] is None for r in rows)
    # Each one sees their own post; someone not serving can't excuse themselves.
    guard_api = client_for("membre")[0]
    guard_api.force_authenticate(guard_a)
    body = guard_api.get(f"/api/events/{mass.pk}/").json()
    assert body["has_lineup"] and body["my_duty"] == {"post": "premiere_centrale", "side": "pariso"}
    out_api = client_for("membre")[0]
    out_api.force_authenticate(outsider)
    assert out_api.get(f"/api/events/{mass.pk}/").json()["my_duty"] is None
    assert out_api.post(f"/api/events/{mass.pk}/excuse/", {}, format="json").json()["code"] == "not_on_duty"
