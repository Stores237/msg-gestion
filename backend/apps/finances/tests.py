import uuid
from datetime import date

import pytest
from rest_framework.test import APIClient

from apps.accounts.factories import UserFactory, give_role
from apps.core.models import AuditLog

from .models import Collection, Due, Entry
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


def test_treasurer_records_auditor_validates_never_own():
    tre_api, tre = client_for("tresorier")
    cac_api, cac = client_for("commissaire-aux-comptes")
    r = entry(tre_api)
    assert r.status_code == 201 and r.json()["status"] == "pending"
    eid = r.json()["id"]
    # Treasurer can't validate (locked cell), even their own.
    assert tre_api.post(f"/api/finances/entries/{eid}/validate/").status_code == 403
    v = cac_api.post(f"/api/finances/entries/{eid}/validate/")
    assert v.status_code == 200 and v.json()["validated_by_name"] == cac.short_name
    # Auditor's own entry: refused even with the right role.
    from apps.accounts.models import Role

    Role.objects.get(slug="commissaire-aux-comptes").permissions.create(resource="finances.cashbook", action="create")
    own = entry(cac_api).json()["id"]
    r = cac_api.post(f"/api/finances/entries/{own}/validate/")
    assert (r.status_code, r.json()["code"]) == (400, "own_entry")
    assert AuditLog.objects.filter(action="Refus · validation de sa propre saisie").exists()


def test_validated_entry_cannot_be_deleted():
    tre_api, _ = client_for("tresorier")
    cac_api, _ = client_for("commissaire-aux-comptes")
    from apps.accounts.models import Role

    Role.objects.get(slug="tresorier").permissions.create(resource="finances.cashbook", action="delete")
    eid = entry(tre_api).json()["id"]
    cac_api.post(f"/api/finances/entries/{eid}/validate/")
    r = tre_api.delete(f"/api/finances/entries/{eid}/")
    assert (r.status_code, r.json()["code"]) == (400, "validated_locked")


def test_offline_retry_does_not_double_count():
    tre_api, _ = client_for("tresorier")
    key = str(uuid.uuid4())
    first = entry(tre_api, client_uuid=key)
    again = entry(tre_api, client_uuid=key)
    assert first.status_code == 201 and again.status_code == 200
    assert first.json()["id"] == again.json()["id"] and Entry.objects.count() == 1


def test_summary_balance_only_counts_validated():
    tre_api, _ = client_for("tresorier")
    cac_api, _ = client_for("commissaire-aux-comptes")
    a = entry(tre_api, amount=10000).json()["id"]
    entry(tre_api, direction="out", amount=3000, category="depense", label="Cierges")
    cac_api.post(f"/api/finances/entries/{a}/validate/")
    s = tre_api.get("/api/finances/summary/").json()
    assert (s["balance"], s["balance_with_pending"], s["pending"]) == (10000, 7000, 1)


def test_super_admin_and_members_see_no_money():
    sa_api, _ = client_for("super-admin")
    member_api, _ = client_for("membre")
    for api in (sa_api, member_api):
        assert api.get("/api/finances/summary/").status_code == 403
        assert api.get("/api/finances/entries/").status_code == 403


def test_collection_in_thirds_and_bulk_payment():
    tre_api, _ = client_for("tresorier")
    a, b = UserFactory(last_name="Ateba"), UserFactory(last_name="Bilong")
    r = tre_api.post("/api/finances/collections/", {"kind": "deces", "title": "Décès · famille Nkotto", "amount_per_member": 2500}, format="json")
    assert r.status_code == 201
    cid = r.json()["id"]
    assert r.json()["tranches"] == [834, 1667, 2500]
    assert Due.objects.filter(collection_id=cid).count() == 3  # treasurer + a + b
    pay = tre_api.post(f"/api/finances/collections/{cid}/payments/", {"payments": [
        {"member": a.id, "amount": 834}, {"member": b.id, "amount": 2500}, {"member": 999999, "amount": 100}]}, format="json")
    assert pay.json()["recorded"] == 2
    rows = {r["member"]: r for r in pay.json()["rows"]}
    assert (rows[a.id]["thirds"], rows[a.id]["next_amount"]) == (1, 833)
    assert (rows[b.id]["thirds"], rows[b.id]["next_amount"]) == (3, 0)
    detail = tre_api.get(f"/api/finances/collections/{cid}/").json()
    assert detail["paid_full"] == 1 and detail["collected"] == 3334
    member_api, _ = client_for("membre")
    assert member_api.post(f"/api/finances/collections/{cid}/close/").status_code == 403
    assert tre_api.post(f"/api/finances/collections/{cid}/close/").status_code == 200
    r = tre_api.post(f"/api/finances/collections/{cid}/payments/", {"payments": [{"member": a.id, "amount": 833}]}, format="json")
    assert r.json()["code"] == "collection_closed"


def test_member_sees_own_dues_without_finance_role():
    tre_api, _ = client_for("tresorier")
    member_api, member = client_for("membre")
    cid = tre_api.post("/api/finances/collections/", {"kind": "deces", "title": "Décès · Nkotto", "amount_per_member": 2500}, format="json").json()["id"]
    tre_api.post("/api/finances/fines/", {"member": member.id, "amount": 500, "reason": "Retard à l’assise"}, format="json")
    tre_api.post(f"/api/finances/collections/{cid}/payments/", {"payments": [{"member": member.id, "amount": 834}]}, format="json")
    mine = member_api.get("/api/finances/mine/").json()
    assert mine["to_pay"] == 1666 + 500
    assert {d["label"]: d["remaining"] for d in mine["dues"]} == {"Décès · Nkotto": 1666, "Retard à l’assise": 500}


def test_paying_a_fine():
    tre_api, _ = client_for("tresorier")
    member = UserFactory()
    tre_api.post("/api/finances/fines/", {"member": member.id, "amount": 500, "reason": "Tenue"}, format="json")
    due = Due.objects.get(member=member)
    r = tre_api.post(f"/api/finances/dues/{due.id}/pay/", {}, format="json")
    assert r.status_code == 201 and r.json()["category"] == "amende" and r.json()["amount"] == 500
    assert tre_api.post(f"/api/finances/dues/{due.id}/pay/", {}, format="json").json()["code"] == "nothing_due"


def test_quarter_report_blocked_by_pending_then_validated():
    tre_api, _ = client_for("tresorier")
    cac_api, _ = client_for("commissaire-aux-comptes")
    old = entry(tre_api, amount=142000, category="aide_don", date="2026-06-15").json()["id"]
    a = entry(tre_api, amount=118500, category="aide_don", date="2026-08-01").json()["id"]
    b = entry(tre_api, direction="out", amount=74000, category="depense", label="Dépenses", date="2026-09-10").json()["id"]
    for eid in (old, a):
        cac_api.post(f"/api/finances/entries/{eid}/validate/")
    r = cac_api.post("/api/finances/report/validate/", {"year": 2026, "quarter": 3}, format="json")
    assert (r.status_code, r.json()["code"]) == (400, "pending_entries")
    cac_api.post(f"/api/finances/entries/{b}/validate/")
    rep = cac_api.post("/api/finances/report/validate/", {"year": 2026, "quarter": 3}, format="json").json()
    assert (rep["opening"], rep["in"], rep["out"], rep["closing"]) == (142000, 118500, 74000, 186500)
    assert rep["validated_by"] is not None
    assert tre_api.post("/api/finances/report/validate/", {"year": 2026, "quarter": 3}, format="json").status_code == 403
    assert Collection.objects.count() == 0
