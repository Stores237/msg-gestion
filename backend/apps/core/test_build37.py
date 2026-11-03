"""Build 37 (owner, 2026-11-02): ended events are locked except the roll
call, the back-office's 8-digit recovery code, the FAQ (common, the group's,
members' suggestions) and the wider group settings."""

from datetime import date, timedelta
from io import StringIO

import pytest
from django.core.management import call_command
from django.utils import timezone
from rest_framework.test import APIClient

from apps.accounts.factories import UserFactory, give_role
from apps.backoffice.test_staff import boss, login, staff_member  # noqa: F401 - fixtures
from apps.core.models import AuditLog, FaqEntry, FaqSuggestion, Membership, Notification, Settings
from apps.events.models import Attendance, Event
from apps.events.tests import client_for

pytestmark = pytest.mark.django_db


def _settings(**kw):
    st = Settings.get()
    for k, v in kw.items():
        setattr(st, k, v)
    st.save()
    return st


# --- Ended events --------------------------------------------------------------


def test_an_ended_event_cannot_be_changed_but_its_roll_call_can():
    api, author = client_for("secretaire-general", "censeur-general")
    start = timezone.now() - timedelta(hours=5)
    e = Event.objects.create(kind="assise", title="Assise", starts_at=start, ends_at=start + timedelta(hours=2), created_by=author)
    body = api.get(f"/api/events/{e.pk}/").json()
    assert body["ended"] is True and body["can_edit"] is False and body["can_delete"] is False
    r = api.patch(f"/api/events/{e.pk}/", {"title": "Changé"}, format="json")
    assert (r.status_code, r.json()["code"]) == (409, "event_ended")
    assert api.delete(f"/api/events/{e.pk}/").status_code == 409
    member = UserFactory()
    give_role(member, "membre")
    r = api.put(f"/api/events/{e.pk}/attendance/", {"marks": [{"member": member.pk, "status": "present"}]}, format="json")
    assert r.status_code == 200
    assert Attendance.objects.filter(event=e, member=member, status="present").exists()


def test_without_an_end_time_the_groups_default_length_decides():
    _settings(event_minutes=60)
    e = Event.objects.create(kind="assise", title="Assise", starts_at=timezone.now() - timedelta(minutes=90))
    assert e.has_ended()
    _settings(event_minutes=120)
    assert not e.has_ended()


def test_absence_cannot_be_announced_and_lineup_not_changed_after_the_end():
    from apps.planning.models import Service

    api, _ = client_for("formateur")
    e = Event.objects.create(kind="messe", title="Messe", starts_at=timezone.now() - timedelta(hours=4),
                             ends_at=timezone.now() - timedelta(hours=2))
    s = Service.objects.create(event=e, size=4)
    guard = UserFactory()
    give_role(guard, "membre")
    r = api.put(f"/api/planning/services/{s.pk}/slot/", {"post": "controle", "side": "pariso", "member": guard.pk}, format="json")
    assert (r.status_code, r.json()["code"]) == (409, "event_ended")
    m_api, _ = client_for("membre")
    assert m_api.post(f"/api/events/{e.pk}/excuse/", {"reason": "Malade"}, format="json").status_code == 409


def test_report_deadline_follows_the_group():
    _settings(report_hours=48)
    start = timezone.now() - timedelta(hours=3)
    e = Event.objects.create(kind="assise", title="A", starts_at=start, ends_at=start + timedelta(hours=1))
    assert e.report_due_at == e.ends_at + timedelta(hours=48)


# --- Recovery code ---------------------------------------------------------------


def _confirm(api, code, pin="7391"):
    return api.post("/api/auth/pin/forgot/confirm/", {"phone": "677452108", "code": code, "new_pin": pin,
                                                      "accept_terms": True, "terms_version": 1}, format="json")


def test_backoffice_recovery_code_resets_the_pin_once(boss):  # noqa: F811
    member = UserFactory(phone="+237677452108", pin="4821")
    give_role(member, "membre")
    page = boss.post(f"/bo/utilisateurs/{member.pk}/", {"action": "recovery_code"}).content.decode()
    import re

    code = re.search(r"(\d{4}) (\d{4})</span>", page)
    assert code, "the code is shown once, as 2 × 4 digits"
    code = code[1] + code[2]
    assert AuditLog.objects.filter(action="Code de récupération créé", object_id=str(member.pk)).exists()
    api = APIClient()
    r = _confirm(api, code)
    assert r.status_code == 200 and "access" in r.json()
    member.refresh_from_db()
    assert member.check_pin("7391") and not member.recovery_code
    assert _confirm(api, code, "5826").json()["code"] == "bad_code"  # one use


def test_recovery_code_expires_and_wrong_tries_cancel_it():
    from apps.accounts.services import RECOVERY_TRIES, issue_recovery_code

    admin = UserFactory()
    member = UserFactory(phone="+237677452108", pin="4821")
    code = issue_recovery_code(member, by=admin)
    assert len(code) == 8 and code.isdigit()
    api = APIClient()
    wrong = "0" * 8 if code != "0" * 8 else "1" * 8
    for _ in range(RECOVERY_TRIES):
        assert _confirm(api, wrong).json()["code"] == "bad_code"
    assert _confirm(api, code).json()["code"] == "bad_code"  # cancelled
    code = issue_recovery_code(member, by=admin)
    member.refresh_from_db()
    member.recovery_code_until = timezone.now() - timedelta(minutes=1)
    member.save()
    assert _confirm(api, code).json()["code"] == "bad_code"  # expired


# --- FAQ -----------------------------------------------------------------------------


def test_faq_is_common_plus_the_groups_own_and_members_suggest(boss):  # noqa: F811
    from apps.core.models import Group

    FaqEntry.objects.create(question="Commune ?", answer="Oui.")
    FaqEntry.objects.create(group=Group.objects.first(), question="Du groupe ?", answer="Aussi.")
    api, author = client_for("membre")
    body = api.get("/api/faq/").json()
    assert [e["question"] for e in body["common"]] == ["Commune ?"]
    assert [e["question"] for e in body["group"]] == ["Du groupe ?"]
    assert api.post("/api/faq/suggestions/", {"question": "?"}, format="json").json()["code"] == "question_required"
    assert api.post("/api/faq/suggestions/", {"question": "Comment payer ?", "answer": "Au trésorier."}, format="json").status_code == 201
    s = FaqSuggestion.objects.get()
    assert "Comment payer ?" in boss.get("/bo/aide/questions/").content.decode()
    r = boss.post("/bo/aide/questions/", {"action": "publish", "id": s.pk, "question": "Comment payer ma cotisation ?",
                                          "answer": "Au trésorier, qui la saisit.", "scope": "common"})
    assert r.status_code == 302
    s.refresh_from_db()
    assert s.status == "published" and s.entry.group_id is None
    assert Notification.objects.filter(user=author, kind="faq").exists()
    assert "Comment payer ma cotisation ?" in [e["question"] for e in api.get("/api/faq/").json()["common"]]
    assert api.get("/api/faq/suggestions/").json()[0]["status"] == "published"


def test_declined_suggestion_tells_the_author_why(boss):  # noqa: F811
    api, author = client_for("membre")
    api.post("/api/faq/suggestions/", {"question": "Question en double ?"}, format="json")
    s = FaqSuggestion.objects.get()
    boss.post("/bo/aide/questions/", {"action": "decline", "id": s.pk, "note": "Déjà dans l’aide."})
    s.refresh_from_db()
    assert s.status == "declined"
    assert "Déjà dans l’aide." in Notification.objects.get(user=author, kind="faq").body


# --- Group settings ----------------------------------------------------------------


def test_backoffice_saves_the_wider_settings(boss):  # noqa: F811
    st = Settings.get()
    page = boss.get("/bo/parametres/").content.decode()
    for name in ("currency", "dues_monthly", "probation_days", "report_hours", "language", "rules_text"):
        assert f'name="{name}"' in page
    data = {f: getattr(st, f) for f in ("parish", "motto", "color", "fee_registration", "fee_medal", "fee_illness", "fee_death",
                                        "installments")}
    data.update(name=st.group.name, currency="eur", dues_monthly=1000, dues_day=10, report_hours=36, language="en",
                rules_text="Article 1", contact_email="contact@example.org")
    assert boss.post("/bo/parametres/", data).status_code == 302
    st.refresh_from_db()
    assert (st.currency, st.dues_monthly, st.dues_day, st.report_hours, st.language) == ("EUR", 1000, 10, 36, "en")
    api, _ = client_for("membre")
    me = api.get("/api/me/").json()
    assert (me["group"]["currency"], me["group"]["language"]) == ("EUR", "en")
    assert api.get("/api/settings/").json()["rules_text"] == "Article 1"


def test_monthly_dues_are_created_once_on_their_day():
    from apps.finances.models import Due

    _settings(dues_monthly=1500, dues_day=1)
    member = UserFactory()
    give_role(member, "membre")
    call_command("send_reminders", stdout=StringIO())
    call_command("send_reminders", stdout=StringIO())
    dues = Due.objects.filter(member=member, kind="mensuelle")
    assert dues.count() == 1 and dues[0].amount == 1500
    assert Notification.objects.filter(user=member, title="Cotisation du mois").count() == 1


def test_low_balance_tells_the_finance_team_once():
    from apps.finances.models import Entry

    _settings(low_balance_alert=5000)
    cac_api, cac = client_for("commissaire-aux-comptes")
    tre_api, tre = client_for("tresorier")
    Entry.objects.create(direction="in", amount=8000, category="aide_don", label="Don", date=date.today(), status="validated",
                         created_by=cac)
    out = tre_api.post("/api/finances/entries/", {"direction": "out", "amount": 4000, "category": "depense", "label": "Papier",
                                                   "date": date.today().isoformat()}, format="json").json()
    assert cac_api.post(f"/api/finances/entries/{out['id']}/validate/").status_code == 200
    assert Notification.objects.filter(title="Solde bas").count() == 2  # trésorier and commissaire


def test_probation_and_inactive_flags_and_leave_limit(boss):  # noqa: F811
    _settings(probation_days=30, inactive_months=2, max_leave_days=60)
    new, old = UserFactory(), UserFactory()
    for u in (new, old):
        give_role(u, "membre")
    Membership.objects.filter(user=old).update(joined_on=date.today() - timedelta(days=200))
    Membership.objects.filter(user=new).update(joined_on=date.today() - timedelta(days=3))
    api, _ = client_for("secretaire-general")
    rows = {r["id"]: r for r in api.get("/api/members/").json()["results"]}
    assert rows[new.pk]["on_probation"] and not rows[new.pk]["inactive"]
    assert rows[old.pk]["inactive"] and not rows[old.pk]["on_probation"]
    r = boss.post(f"/bo/utilisateurs/{old.pk}/", {"action": "leave", "reason": "Voyage",
                                                  "until": (date.today() + timedelta(days=90)).isoformat()}, follow=True)
    assert "au plus 60 jours" in r.content.decode()
    assert Membership.objects.get(user=old).status == "actif"


def test_repeated_absences_alert_once():
    _settings(absence_alert=2)
    api, censeur = client_for("censeur-general")
    member = UserFactory()
    give_role(member, "membre")
    for h in (30, 20, 10):
        e = Event.objects.create(kind="assise", title=f"Assise {h}", starts_at=timezone.now() - timedelta(hours=h),
                                 ends_at=timezone.now() - timedelta(hours=h - 1))
        api.put(f"/api/events/{e.pk}/attendance/", {"marks": [{"member": member.pk, "status": "absent"}]}, format="json")
    assert Notification.objects.filter(user=member, title="Absences").count() == 1
    assert Notification.objects.filter(user=censeur, title="Absences répétées").count() == 1


# --- Export period (owner, 2026-11-03) -------------------------------------------------


def _money_history():
    from apps.finances.models import Due, Entry

    member = UserFactory()
    give_role(member, "membre")
    admin = UserFactory()
    old = Due.objects.create(member=member, kind="amende", label="Retard", amount=500)
    Due.objects.filter(pk=old.pk).update(created_at=timezone.now() - timedelta(days=60))
    Due.objects.create(member=member, kind="amende", label="Absence", amount=1000)
    Entry.objects.create(direction="in", amount=500, category="amende", label="Retard", member=member, status="validated",
                         date=date.today() - timedelta(days=50), created_by=admin)
    Entry.objects.create(direction="in", amount=300, category="amende", label="Absence", member=member, status="validated",
                         date=date.today(), created_by=admin)
    return member


def test_statements_and_cash_book_follow_the_period():
    member = _money_history()
    api, _ = client_for("tresorier")
    start = (date.today() - timedelta(days=7)).isoformat()
    whole = {r["member"]: r for r in api.get("/api/finances/statement/").json()["rows"]}[member.pk]
    assert (whole["owed"], whole["paid"]) == (1500, 800)
    body = api.get(f"/api/finances/statement/?from={start}").json()
    row = {r["member"]: r for r in body["rows"]}[member.pk]
    assert (row["owed"], row["paid"]) == (1000, 300) and body["period"].startswith("depuis le")
    one = api.get(f"/api/finances/statement/{member.pk}/?from={start}&to={date.today().isoformat()}").json()
    assert [d["label"] for d in one["dues"]] == ["Absence"] and len(one["entries"]) == 1
    assert api.get("/api/finances/statement/?from=2026-13-01").json()["code"] == "bad_period"
    assert api.get(f"/api/finances/statement/?from={date.today()}&to=2020-01-01").json()["code"] == "bad_period"

    from apps.finances import services

    lines, opening, closing = services.cashbook(services.Period(date.today() - timedelta(days=7), date.today()))
    assert [e.label for e in lines] == ["Absence"] and (opening, closing) == (500, 800)
    assert api.get(f"/api/finances/entries/pdf/?from={start}").status_code == 200
    assert AuditLog.objects.filter(action="Export PDF du livre de caisse", detail__periode__startswith="depuis").exists()


def test_backoffice_period_filters_the_page_and_the_exports(boss):  # noqa: F811
    member = _money_history()
    start = (date.today() - timedelta(days=7)).isoformat()
    page = boss.get(f"/bo/finances/?from={start}").content.decode()
    assert "Chiffres et exports depuis le" in page
    assert f"bilan.pdf?from={start}" in page and f"livre-de-caisse.pdf?from={start}" in page
    r = boss.get(f"/bo/finances/livre-de-caisse.pdf?from={start}")
    assert r.status_code == 200 and r["Content-Type"] == "application/pdf"
    assert start.replace("-", "") in r["Content-Disposition"]
    csv = boss.get(f"/bo/finances/bilan.csv?from={start}").content.decode()
    assert "Période : depuis le" in csv
    page = boss.get(f"/bo/finances/membres/{member.pk}/?from={start}").content.decode()
    assert "Absence" in page and "Retard" not in page
    assert "Période invalide" in boss.get("/bo/finances/?from=hier", follow=True).content.decode()
