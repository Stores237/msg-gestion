import uuid
from datetime import date

import pytest
from rest_framework.test import APIClient

from apps.accounts.factories import UserFactory, give_role
from apps.core.models import AuditLog

from .models import Due, Entry
from .services import quarter_bounds

pytestmark = pytest.mark.django_db


def client_for(*slugs):
    user = UserFactory()
    for s in slugs:
        give_role(user, s)
    api = APIClient()
    api.force_authenticate(user)
    return api, user


def entry(api, **kw):
    body = {"direction": "in", "amount": 2500, "category": "solidarite", "label": "Décès · Nkotto", "date": "2026-10-19", **kw}
    return api.post("/api/finances/entries/", body, format="json")


def test_quarter_bounds():
    assert quarter_bounds(2026, 3) == (date(2026, 7, 1), date(2026, 10, 1))
    assert quarter_bounds(2026, 4) == (date(2026, 10, 1), date(2027, 1, 1))


def pending_entry(**kw):
    """A line waiting for validation, as entered by someone who isn't the
    commissaire (e.g. a registration fee taken by the secrétaire)."""
    fields = {"direction": "in", "amount": 2500, "category": "solidarite", "label": "Décès · Nkotto", "date": date(2026, 10, 19), **kw}
    return Entry.objects.create(created_by=UserFactory(), **fields)


def test_treasurer_reads_and_downloads_only():
    tre_api, _ = client_for("tresorier")
    e = pending_entry()
    assert entry(tre_api).status_code == 403
    assert tre_api.post(f"/api/finances/entries/{e.id}/validate/").status_code == 403
    assert tre_api.delete(f"/api/finances/entries/{e.id}/").status_code == 403
    assert tre_api.post("/api/finances/collections/", {"kind": "deces", "title": "x", "amount_per_member": 100}, format="json").status_code == 403
    assert tre_api.post("/api/finances/report/validate/", {"year": 2026, "quarter": 4}, format="json").status_code == 403
    assert tre_api.get("/api/finances/entries/").status_code == 200
    assert tre_api.get("/api/finances/summary/").status_code == 200
    assert tre_api.get("/api/finances/statement/").status_code == 200


def test_treasurer_write_rights_are_locked():
    from apps.accounts.models import Role

    tre_api, _ = client_for("tresorier")
    Role.objects.get(slug="tresorier").permissions.get_or_create(resource="finances.cashbook", action="create")
    assert entry(tre_api).status_code == 403


def test_auditor_has_every_finance_right_and_own_entries_are_validated():
    cac_api, cac = client_for("commissaire-aux-comptes")
    r = entry(cac_api)
    assert r.status_code == 201 and r.json()["status"] == "validated" and r.json()["validated_by_name"] == cac.short_name
    assert AuditLog.objects.filter(action="Opération saisie et validée").exists()
    other = pending_entry()
    v = cac_api.post(f"/api/finances/entries/{other.id}/validate/")
    assert v.status_code == 200 and v.json()["validated_by_name"] == cac.short_name
    assert cac_api.delete(f"/api/finances/entries/{pending_entry().id}/").status_code == 204
    # A pending line of their own (entered before they held the role) still
    # can't be validated by them.
    own = Entry.objects.create(created_by=cac, direction="in", amount=100, category="amende", label="x", date=date(2026, 10, 1))
    r = cac_api.post(f"/api/finances/entries/{own.id}/validate/")
    assert (r.status_code, r.json()["code"]) == (400, "own_entry")
    assert AuditLog.objects.filter(action="Refus · validation de sa propre saisie").exists()


def test_validated_entry_cannot_be_deleted():
    cac_api, _ = client_for("commissaire-aux-comptes")
    eid = entry(cac_api).json()["id"]
    r = cac_api.delete(f"/api/finances/entries/{eid}/")
    assert (r.status_code, r.json()["code"]) == (400, "validated_locked")


def test_offline_retry_does_not_double_count():
    cac_api, _ = client_for("commissaire-aux-comptes")
    key = str(uuid.uuid4())
    first = entry(cac_api, client_uuid=key)
    again = entry(cac_api, client_uuid=key)
    assert first.status_code == 201 and again.status_code == 200
    assert first.json()["id"] == again.json()["id"] and Entry.objects.count() == 1


def test_summary_balance_only_counts_validated():
    tre_api, _ = client_for("tresorier")
    cac_api, _ = client_for("commissaire-aux-comptes")
    entry(cac_api, amount=10000)
    pending_entry(direction="out", amount=3000, category="depense", label="Cierges")
    s = tre_api.get("/api/finances/summary/").json()
    assert (s["balance"], s["balance_with_pending"], s["pending"]) == (10000, 7000, 1)


def test_members_see_no_money():
    member_api, _ = client_for("membre")
    assert member_api.get("/api/finances/summary/").status_code == 403
    assert member_api.get("/api/finances/entries/").status_code == 403


def test_collection_in_thirds_and_bulk_payment():
    cac_api, _ = client_for("commissaire-aux-comptes")
    a, b = UserFactory(last_name="Ateba"), UserFactory(last_name="Bilong")
    r = cac_api.post("/api/finances/collections/", {"kind": "deces", "title": "Décès · famille Nkotto", "amount_per_member": 2500}, format="json")
    assert r.status_code == 201
    cid = r.json()["id"]
    assert r.json()["tranches"] == [834, 1667, 2500]
    assert Due.objects.filter(collection_id=cid).count() == 3  # treasurer + a + b
    pay = cac_api.post(f"/api/finances/collections/{cid}/payments/", {"payments": [
        {"member": a.id, "amount": 834}, {"member": b.id, "amount": 2500}, {"member": 999999, "amount": 100}]}, format="json")
    assert pay.json()["recorded"] == 2
    rows = {r["member"]: r for r in pay.json()["rows"]}
    assert (rows[a.id]["thirds"], rows[a.id]["next_amount"]) == (1, 833)
    assert (rows[b.id]["thirds"], rows[b.id]["next_amount"]) == (3, 0)
    detail = cac_api.get(f"/api/finances/collections/{cid}/").json()
    assert detail["paid_full"] == 1 and detail["collected"] == 3334
    member_api, _ = client_for("membre")
    assert member_api.post(f"/api/finances/collections/{cid}/close/").status_code == 403
    assert cac_api.post(f"/api/finances/collections/{cid}/close/").status_code == 200
    r = cac_api.post(f"/api/finances/collections/{cid}/payments/", {"payments": [{"member": a.id, "amount": 833}]}, format="json")
    assert r.json()["code"] == "collection_closed"


def test_member_sees_own_dues_without_finance_role():
    cac_api, _ = client_for("commissaire-aux-comptes")
    member_api, member = client_for("membre")
    cid = cac_api.post("/api/finances/collections/", {"kind": "deces", "title": "Décès · Nkotto", "amount_per_member": 2500}, format="json").json()["id"]
    cac_api.post("/api/finances/fines/", {"member": member.id, "amount": 500, "reason": "Retard à l’assise"}, format="json")
    cac_api.post(f"/api/finances/collections/{cid}/payments/", {"payments": [{"member": member.id, "amount": 834}]}, format="json")
    mine = member_api.get("/api/finances/mine/").json()
    assert mine["to_pay"] == 1666 + 500
    assert {d["label"]: d["remaining"] for d in mine["dues"]} == {"Décès · Nkotto": 1666, "Retard à l’assise": 500}


def test_paying_a_fine():
    cac_api, _ = client_for("commissaire-aux-comptes")
    member = UserFactory()
    cac_api.post("/api/finances/fines/", {"member": member.id, "amount": 500, "reason": "Tenue"}, format="json")
    due = Due.objects.get(member=member)
    r = cac_api.post(f"/api/finances/dues/{due.id}/pay/", {}, format="json")
    assert r.status_code == 201 and r.json()["category"] == "amende" and r.json()["amount"] == 500
    assert cac_api.post(f"/api/finances/dues/{due.id}/pay/", {}, format="json").json()["code"] == "nothing_due"


def test_quarter_report_blocked_by_pending_then_validated():
    tre_api, _ = client_for("tresorier")
    cac_api, _ = client_for("commissaire-aux-comptes")
    entry(cac_api, amount=142000, category="aide_don", date="2026-06-15")
    entry(cac_api, amount=118500, category="aide_don", date="2026-08-01")
    b = pending_entry(direction="out", amount=74000, category="depense", label="Dépenses", date=date(2026, 9, 10))
    r = cac_api.post("/api/finances/report/validate/", {"year": 2026, "quarter": 3}, format="json")
    assert (r.status_code, r.json()["code"]) == (400, "pending_entries")
    cac_api.post(f"/api/finances/entries/{b.id}/validate/")
    rep = cac_api.post("/api/finances/report/validate/", {"year": 2026, "quarter": 3}, format="json").json()
    assert (rep["opening"], rep["in"], rep["out"], rep["closing"]) == (142000, 118500, 74000, 186500)
    assert rep["validated_by"] is not None
    assert tre_api.post("/api/finances/report/validate/", {"year": 2026, "quarter": 3}, format="json").status_code == 403


def test_statement_general_and_per_member():
    tre_api, _ = client_for("tresorier")
    cac_api, _ = client_for("commissaire-aux-comptes")
    a, b = UserFactory(last_name="Ateba"), UserFactory(last_name="Bilong")
    cid = cac_api.post("/api/finances/collections/", {"kind": "deces", "title": "Décès · Nkotto", "amount_per_member": 2500}, format="json").json()["id"]
    cac_api.post("/api/finances/fines/", {"member": a.id, "amount": 500, "reason": "Tenue"}, format="json")
    cac_api.post(f"/api/finances/collections/{cid}/payments/", {"payments": [{"member": a.id, "amount": 834}, {"member": b.id, "amount": 2500}]}, format="json")
    pending_entry(member=a, amount=300, label="Don")  # waiting for validation, not tied to a debt
    body = tre_api.get("/api/finances/statement/").json()
    rows = {r["member"]: r for r in body["rows"]}
    assert (rows[a.id]["owed"], rows[a.id]["paid"], rows[a.id]["pending"], rows[a.id]["remaining"]) == (3000, 834, 300, 2166)
    assert (rows[b.id]["owed"], rows[b.id]["paid"], rows[b.id]["remaining"]) == (2500, 2500, 0)
    assert body["totals"]["owed"] == sum(r["owed"] for r in body["rows"])
    one = tre_api.get(f"/api/finances/statement/{a.id}/").json()
    assert {d["label"]: d["remaining"] for d in one["dues"]} == {"Décès · Nkotto": 1666, "Tenue": 500}
    assert sorted(e["amount"] for e in one["entries"]) == [300, 834]


def test_statement_pdfs_need_export_and_are_audited():
    tre_api, _ = client_for("tresorier")
    member_api, member = client_for("membre")
    r = tre_api.get("/api/finances/statement/pdf/")
    assert r.status_code == 200 and r.json()["url"].endswith(".pdf")
    assert tre_api.get(f"/api/finances/statement/{member.id}/pdf/").status_code == 200
    assert AuditLog.objects.filter(action="Export PDF du bilan général").exists()
    assert AuditLog.objects.filter(action="Export PDF du bilan individuel", object_id=str(member.id)).exists()
    assert member_api.get("/api/finances/statement/").status_code == 403
    assert member_api.get(f"/api/finances/statement/{member.id}/pdf/").status_code == 403
