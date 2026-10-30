"""Finance corrections (owner, 2026-10-30): the trésorier edits a line not
yet validated (marked "Modifié"; after his validation the commissaire
finalises it); money in names at least one member, several ticked members
make one line each; "Autre" is a money-in category with a description."""

import uuid

import pytest

from apps.accounts.factories import UserFactory
from apps.core.models import AuditLog, Notification

from .models import Due, Entry
from .tests import client_for, entry

pytestmark = pytest.mark.django_db


def _pair():
    cac_api, cac = client_for("commissaire-aux-comptes")
    tre_api, tre = client_for("tresorier")
    return cac_api, cac, tre_api, tre


def test_edit_then_validate_then_commissaire_finalises():
    cac_api, cac, tre_api, tre = _pair()
    payer, right = UserFactory(), UserFactory()
    line = entry(cac_api, member=payer.pk, amount=2500).json()

    r = tre_api.patch(f"/api/finances/entries/{line['id']}/", {"amount": 3000, "member": right.pk}, format="json")
    assert r.status_code == 200
    body = r.json()
    assert (body["amount"], body["member"], body["status"]) == (3000, right.pk, "pending")
    assert body["edited_by_name"] == tre.short_name and body["edited_at"]
    log = AuditLog.objects.get(action="Opération modifiée avant validation")
    assert log.detail["amount"] == {"avant": 2500, "apres": 3000}
    assert Notification.objects.filter(user=cac, title="Opération modifiée par le trésorier").exists()

    # The trésorier validates: an edited line now waits for the commissaire.
    r = tre_api.post(f"/api/finances/entries/{line['id']}/validate/")
    assert r.json()["status"] == "to_confirm"
    assert Notification.objects.filter(user=cac, title="Opération à finaliser").exists()
    assert not Notification.objects.filter(user=right, title="Paiement validé").exists()
    assert cac_api.get("/api/finances/summary/").json()["to_confirm"] == 1
    # Not final: the balance doesn't count it yet.
    assert cac_api.get("/api/finances/summary/").json()["balance"] == 0
    # The trésorier can't finalise his own correction.
    assert tre_api.post(f"/api/finances/entries/{line['id']}/confirm/", {"accept": True}, format="json").status_code == 403

    r = cac_api.post(f"/api/finances/entries/{line['id']}/confirm/", {"accept": True}, format="json")
    assert r.status_code == 200 and r.json()["status"] == "validated" and r.json()["confirmed_by_name"] == cac.short_name
    assert cac_api.get("/api/finances/summary/").json()["balance"] == 3000
    assert Notification.objects.filter(user=right, title="Paiement validé").exists()
    # Final: no more changes.
    assert tre_api.patch(f"/api/finances/entries/{line['id']}/", {"amount": 1}, format="json").json()["code"] == "not_editable"


def test_unchanged_line_is_still_validated_in_one_step():
    cac_api, _, tre_api, _ = _pair()
    line = entry(cac_api).json()
    # Sending the same values changes nothing and doesn't mark the line.
    tre_api.patch(f"/api/finances/entries/{line['id']}/", {"amount": line["amount"]}, format="json")
    assert tre_api.post(f"/api/finances/entries/{line['id']}/validate/").json()["status"] == "validated"


def test_commissaire_sends_a_correction_back_with_a_reason():
    cac_api, _, tre_api, tre = _pair()
    line = entry(cac_api).json()
    tre_api.patch(f"/api/finances/entries/{line['id']}/", {"amount": 9000}, format="json")
    tre_api.post(f"/api/finances/entries/{line['id']}/validate/")
    no_reason = cac_api.post(f"/api/finances/entries/{line['id']}/confirm/", {"accept": False}, format="json")
    assert no_reason.json()["code"] == "reason_required"
    r = cac_api.post(f"/api/finances/entries/{line['id']}/confirm/", {"accept": False, "reason": "Reçu de 2 500"}, format="json")
    assert r.json()["status"] == "pending" and r.json()["validated_by_name"] is None
    assert Notification.objects.filter(user=tre, title="Opération renvoyée").exists()
    # Back with the trésorier, who can correct it again.
    assert tre_api.patch(f"/api/finances/entries/{line['id']}/", {"amount": 2500}, format="json").status_code == 200


def test_only_the_validator_edits_and_never_his_own_line():
    cac_api, _, tre_api, _ = _pair()
    line = entry(cac_api).json()
    # The commissaire has no "validate": he can't edit (he can delete and re-enter).
    assert cac_api.patch(f"/api/finances/entries/{line['id']}/", {"amount": 1}, format="json").status_code == 403
    member_api, _ = client_for()
    assert member_api.patch(f"/api/finances/entries/{line['id']}/", {"amount": 1}, format="json").status_code == 403


def test_a_payment_towards_a_due_keeps_its_member():
    cac_api, cac, tre_api, _ = _pair()
    m = UserFactory()
    due = Due.objects.create(member=m, kind=Due.Kind.FINE, label="Retard", amount=1000, created_by=cac)
    line = cac_api.post(f"/api/finances/dues/{due.pk}/pay/", {"amount": 1000}, format="json").json()
    r = tre_api.patch(f"/api/finances/entries/{line['id']}/", {"member": UserFactory().pk}, format="json")
    assert r.json()["code"] == "linked_entry"
    assert tre_api.patch(f"/api/finances/entries/{line['id']}/", {"amount": 800}, format="json").status_code == 200


def test_money_in_needs_a_member_money_out_does_not():
    cac_api, _, _, _ = _pair()
    r = cac_api.post("/api/finances/entries/", {"direction": "in", "amount": 500, "category": "aide_don", "label": "Don",
                                               "date": "2026-10-20"}, format="json")
    assert (r.status_code, r.json()["code"]) == (400, "member_required")
    r = cac_api.post("/api/finances/entries/", {"direction": "out", "amount": 500, "category": "depense", "label": "Bougies",
                                               "date": "2026-10-20"}, format="json")
    assert r.status_code == 201


def test_several_members_make_one_line_each_once():
    cac_api, _, _, _ = _pair()
    a, b, c = UserFactory(), UserFactory(), UserFactory()
    key = str(uuid.uuid4())
    body = {"direction": "in", "amount": 2000, "category": "inscription", "label": "Inscription 2026", "date": "2026-10-20",
            "members": [a.pk, b.pk, c.pk], "client_uuid": key}
    r = cac_api.post("/api/finances/entries/", body, format="json")
    assert r.status_code == 201 and r.json()["count"] == 3
    assert sorted(Entry.objects.values_list("member", flat=True)) == sorted([a.pk, b.pk, c.pk])
    assert set(Entry.objects.values_list("amount", flat=True)) == {2000}
    # The phone resends it after a network cut: nothing new.
    cac_api.post("/api/finances/entries/", body, format="json")
    assert Entry.objects.count() == 3


def test_other_category_needs_a_description_and_is_money_in():
    cac_api, _, _, _ = _pair()
    m = UserFactory()
    base = {"direction": "in", "amount": 700, "category": "autre", "date": "2026-10-20", "member": m.pk}
    assert cac_api.post("/api/finances/entries/", {**base, "label": " "}, format="json").status_code == 400
    r = cac_api.post("/api/finances/entries/", {**base, "label": "Autre"}, format="json")
    assert r.json()["code"] == "description_required"
    r = cac_api.post("/api/finances/entries/", {**base, "label": "Vente de calendriers"}, format="json")
    assert r.status_code == 201 and r.json()["category"] == "autre"
    # Money out is always a dépense.
    r = cac_api.post("/api/finances/entries/", {**base, "direction": "out", "label": "Taxi"}, format="json")
    assert r.json()["category"] == "depense"
