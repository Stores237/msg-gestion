"""Expense requests (owner, 2026-10-30): a member asks; the domain's lead or
a tagged coordinator approves; the commissaire approves and passes it on; the
trésorier pays at most the approved amount and posts the proof, which records
the Sortie, counted. Cancelled requests stay; a new one replaces it."""

import pytest
from django.core.files.uploadedfile import SimpleUploadedFile
from rest_framework.test import APIClient

from apps.accounts.factories import UserFactory, give_role
from apps.core.models import AuditLog, Notification

from .models import Entry, ExpenseDomain, ExpenseRequest

pytestmark = pytest.mark.django_db

PNG = b"\x89PNG\r\n\x1a\n" + b"0" * 64


def api_for(*slugs):
    u = UserFactory()
    for s in slugs:
        give_role(u, s)
    api = APIClient()
    api.force_authenticate(u)
    return api, u


def formation():
    return ExpenseDomain.objects.get(name="Formation")


def ask(api, **kw):
    body = {"domain": formation().pk, "title": "Papier pour l’examen", "amount": 5000, "description": "2 rames", **kw}
    return api.post("/api/finances/expenses/", body, format="json")


def proof(name="capture.png"):
    return SimpleUploadedFile(name, PNG, content_type="image/png")


def test_the_whole_way_from_request_to_payment():
    member_api, member = api_for("membre")
    lead_api, lead = api_for("formateur")
    cac_api, cac = api_for("commissaire-aux-comptes")
    tre_api, tre = api_for("tresorier")

    r = ask(member_api)
    assert r.status_code == 201
    rid = r.json()["id"]
    assert r.json()["status"] == "submitted" and r.json()["actions"] == ["cancel"]
    assert Notification.objects.filter(user=lead, title="Demande de dépense à approuver").exists()
    # Only the lead of Formation sees it in his "to do".
    assert [x["id"] for x in lead_api.get("/api/finances/expenses/?box=todo").json()] == [rid]
    assert cac_api.get("/api/finances/expenses/?box=todo").json() == []
    # Not the commissaire's step yet.
    assert cac_api.post(f"/api/finances/expenses/{rid}/review/", {"approve": True}, format="json").json()["code"] == "wrong_step"

    r = lead_api.post(f"/api/finances/expenses/{rid}/decide/", {"approve": True}, format="json")
    assert r.json()["status"] == "approved" and r.json()["lead_by_name"] == lead.short_name
    assert Notification.objects.filter(user=cac, title="Demande de dépense à examiner").exists()

    r = cac_api.post(f"/api/finances/expenses/{rid}/review/", {"approve": True, "note": "Devis vu"}, format="json")
    assert r.json()["status"] == "to_pay"
    assert Notification.objects.filter(user=tre, title="Dépense à payer").exists()
    assert tre_api.get(f"/api/finances/expenses/{rid}/").json()["actions"] == ["pay"]

    # More than approved: refused; no proof: refused.
    over = tre_api.post(f"/api/finances/expenses/{rid}/pay/", {"amount": 6000, "file": proof()}, format="multipart")
    assert over.json()["code"] == "amount_over"
    assert tre_api.post(f"/api/finances/expenses/{rid}/pay/", {"amount": 4800}, format="multipart").json()["code"] == "proof_required"
    r = tre_api.post(f"/api/finances/expenses/{rid}/pay/", {"amount": 4800, "file": proof(), "note": "Orange Money"},
                     format="multipart")
    body = r.json()
    assert r.status_code == 200 and body["status"] == "paid" and body["paid_amount"] == 4800
    last = body["messages"][-1]
    assert last["kind"] == "proof" and last["file_url"] and last["author_name"] == tre.short_name
    # The Sortie is in the cash book and counts: two hands done.
    e = Entry.objects.get(pk=body["entry"])
    assert (e.direction, e.amount, e.status, e.created_by, e.validated_by) == ("out", 4800, "validated", tre, cac)
    assert tre_api.get("/api/finances/summary/").json()["balance"] == -4800
    assert Notification.objects.filter(user=member, title="Dépense payée").exists()
    steps = [m["body"] for m in member_api.get(f"/api/finances/expenses/{rid}/").json()["messages"]]
    assert steps[0].startswith("Demande envoyée") and "Transmise au trésorier" in steps[2]


def test_a_tagged_coordinator_can_decide_instead_of_the_lead():
    member_api, _ = api_for("membre")
    lead_api, _ = api_for("formateur")
    pres_api, pres = api_for("president")
    rid = ask(member_api, tagged=[pres.pk]).json()["id"]
    r = pres_api.post(f"/api/finances/expenses/{rid}/decide/", {"approve": True}, format="json")
    assert r.json()["lead_by_name"] == pres.short_name
    # The first one decided; the lead can't any more.
    assert lead_api.post(f"/api/finances/expenses/{rid}/decide/", {"approve": True}, format="json").json()["code"] == "wrong_step"


def test_only_the_lead_role_not_the_adjoint_or_anyone():
    member_api, _ = api_for("membre")
    other_api, _ = api_for("membre")
    api_for("formateur")
    rid = ask(member_api).json()["id"]
    r = other_api.post(f"/api/finances/expenses/{rid}/decide/", {"approve": True}, format="json")
    assert r.status_code == 404  # not involved: doesn't even see it
    sec_api, _ = api_for("secretaire-general")
    ExpenseRequest.objects.get(pk=rid).tagged.clear()
    assert sec_api.post(f"/api/finances/expenses/{rid}/decide/", {"approve": True}, format="json").status_code == 404


def test_the_lead_asking_for_himself_must_tag_someone():
    lead_api, _ = api_for("formateur")
    assert ask(lead_api).json()["code"] == "no_decider"
    _, pres = api_for("president")
    assert ask(lead_api, tagged=[pres.pk]).status_code == 201


def test_refusals_need_a_reason():
    member_api, member = api_for("membre")
    lead_api, _ = api_for("formateur")
    rid = ask(member_api).json()["id"]
    assert lead_api.post(f"/api/finances/expenses/{rid}/decide/", {"approve": False}, format="json").json()["code"] == "reason_required"
    r = lead_api.post(f"/api/finances/expenses/{rid}/decide/", {"approve": False, "note": "Pas prévu"}, format="json")
    assert r.json()["status"] == "refused" and r.json()["close_reason"] == "Pas prévu"
    assert Notification.objects.filter(user=member, title="Demande refusée").exists()


def test_cancel_and_ask_again_with_the_exact_amount():
    member_api, _ = api_for("membre")
    api_for("formateur")
    rid = ask(member_api).json()["id"]
    assert member_api.post(f"/api/finances/expenses/{rid}/cancel/", {}, format="json").json()["code"] == "reason_required"
    r = member_api.post(f"/api/finances/expenses/{rid}/cancel/", {"reason": "Le papier coûte 4 800"}, format="json")
    assert r.json()["status"] == "cancelled" and r.json()["actions"] == ["resubmit"]
    r = ask(member_api, amount=4800, replaces=rid)
    assert r.status_code == 201 and r.json()["replaces"] == rid
    # The cancelled one stays on record, linked; it can't be redone twice.
    old = member_api.get(f"/api/finances/expenses/{rid}/").json()
    assert old["status"] == "cancelled" and old["replaced_by"] == r.json()["id"] and old["actions"] == []
    assert ask(member_api, replaces=rid).json()["code"] == "bad_replaces"


def test_nobody_decides_twice_or_pays_what_they_approved():
    lead_api, lead = api_for("formateur")
    cac_api, cac = api_for("commissaire-aux-comptes")
    cac2_api, _ = api_for("commissaire-aux-comptes")
    # The commissaire asks: he can't review his own request.
    _, pres = api_for("president")
    rid = ask(cac_api, tagged=[pres.pk]).json()["id"]
    pres_api = APIClient()
    pres_api.force_authenticate(pres)
    pres_api.post(f"/api/finances/expenses/{rid}/decide/", {"approve": True}, format="json")
    r = cac_api.post(f"/api/finances/expenses/{rid}/review/", {"approve": True}, format="json")
    assert r.json()["code"] == "own_request"
    assert AuditLog.objects.filter(action="Refus · demande de dépense", refused=True).exists()
    assert cac2_api.post(f"/api/finances/expenses/{rid}/review/", {"approve": True}, format="json").json()["status"] == "to_pay"
    # A member can't pay.
    m_api, _ = api_for("membre")
    assert m_api.post(f"/api/finances/expenses/{rid}/pay/", {"amount": 1, "file": proof()}, format="multipart").status_code == 404


def test_thread_comments_with_a_file_and_bad_files_refused():
    member_api, _ = api_for("membre")
    lead_api, _ = api_for("formateur")
    rid = ask(member_api).json()["id"]
    r = lead_api.post(f"/api/finances/expenses/{rid}/messages/", {"body": "Quel fournisseur ?"}, format="multipart")
    assert r.status_code == 201 and r.json()["messages"][-1]["body"] == "Quel fournisseur ?"
    r = member_api.post(f"/api/finances/expenses/{rid}/messages/", {"body": "Devis", "file": proof("devis.png")}, format="multipart")
    assert r.json()["messages"][-1]["file_name"] == "devis.png"
    bad = SimpleUploadedFile("x.png", b"not an image", content_type="image/png")
    assert member_api.post(f"/api/finances/expenses/{rid}/messages/", {"file": bad}, format="multipart").json()["code"] == "file_type"


def test_domains_list():
    api, _ = api_for("membre")
    names = [d["name"] for d in api.get("/api/finances/expense-domains/").json()]
    assert "Formation" in names


# --- Finance code ------------------------------------------------------------------


def test_finance_code_set_with_pin_then_checked_and_locked():
    u = UserFactory(pin="4821")
    api = APIClient()
    api.force_authenticate(u)
    assert api.get("/api/me/").json()["finance_code_set"] is False
    assert api.post("/api/auth/finance-code/check/", {"code": "7395"}, format="json").status_code == 409
    assert api.post("/api/auth/finance-code/", {"pin": "0000", "code": "7395"}, format="json").status_code == 401
    assert api.post("/api/auth/finance-code/", {"pin": "4821", "code": "4821"}, format="json").json()["code"] == "same_as_pin"
    assert api.post("/api/auth/finance-code/", {"pin": "4821", "code": "1111"}, format="json").json()["code"] == "pin_too_simple"
    assert api.post("/api/auth/finance-code/", {"pin": "4821", "code": "7395"}, format="json").status_code == 204
    u.refresh_from_db()  # a real request loads the account afresh
    assert api.get("/api/me/").json()["finance_code_set"] is True
    assert "7395" not in u.finance_code  # hashed

    assert api.post("/api/auth/finance-code/check/", {"code": "7395"}, format="json").status_code == 204
    r = api.post("/api/auth/finance-code/check/", {"code": "1357"}, format="json")
    assert (r.status_code, r.json()["attempts_left"]) == (401, 2)
    api.post("/api/auth/finance-code/check/", {"code": "1357"}, format="json")
    assert api.post("/api/auth/finance-code/check/", {"code": "1357"}, format="json").status_code == 423
    # Locked: even the right code waits.
    assert api.post("/api/auth/finance-code/check/", {"code": "7395"}, format="json").status_code == 423
    assert AuditLog.objects.filter(action="Code finances incorrect · bloqué").exists()
    # Reset with the PIN unlocks.
    api.post("/api/auth/finance-code/", {"pin": "4821", "code": "8264"}, format="json")
    assert api.post("/api/auth/finance-code/check/", {"code": "8264"}, format="json").status_code == 204


def test_group_setting_is_in_me():
    from apps.core.models import Settings

    api, _ = api_for("tresorier")
    assert api.get("/api/me/").json()["group"]["finance_code_required"] is False
    Settings.objects.update(finance_code_required=True)
    assert api.get("/api/me/").json()["group"]["finance_code_required"] is True
