"""Finance corrections (owner, 2026-10-30): a line not yet validated can be
corrected (marked "Modifié"); the correction is its author's agreement and
the other one approves it; money in names at least one member, several ticked members
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


def test_an_edit_is_its_authors_agreement_and_the_other_approves():
    cac_api, cac, tre_api, tre = _pair()
    payer, right = UserFactory(), UserFactory()
    line = entry(cac_api, member=payer.pk, amount=2500).json()

    r = tre_api.patch(f"/api/finances/entries/{line['id']}/", {"amount": 3000, "member": right.pk}, format="json")
    assert r.status_code == 200
    body = r.json()
    assert (body["amount"], body["member"], body["status"]) == (3000, right.pk, "pending")
    assert body["edited_by_name"] == tre.short_name and body["edited_at"]
    # The trésorier changed it: he has agreed, the commissaire approves.
    assert body["awaiting_other"] is True and body["can_approve"] is False
    log = AuditLog.objects.get(action="Opération modifiée avant validation")
    assert log.detail["amount"] == {"avant": 2500, "apres": 3000}
    assert Notification.objects.filter(user=cac, title="Opération modifiée · à approuver").exists()
    assert tre_api.post(f"/api/finances/entries/{line['id']}/validate/").json()["code"] == "own_entry"
    assert cac_api.get("/api/home/bureau/").json()["to_validate"] == 1
    assert tre_api.get("/api/home/bureau/").json()["to_validate"] == 0

    r = cac_api.post(f"/api/finances/entries/{line['id']}/validate/")
    assert r.json()["status"] == "validated" and r.json()["validated_by_name"] == cac.short_name
    assert cac_api.get("/api/finances/summary/").json()["balance"] == 3000
    assert Notification.objects.filter(user=right, title="Paiement validé").exists()
    # Final: no more changes.
    assert tre_api.patch(f"/api/finances/entries/{line['id']}/", {"amount": 1}, format="json").json()["code"] == "not_editable"


def test_who_entered_can_correct_before_the_other_approves():
    cac_api, _, tre_api, _ = _pair()
    line = entry(cac_api).json()
    assert cac_api.patch(f"/api/finances/entries/{line['id']}/", {"amount": 2000}, format="json").status_code == 200
    assert cac_api.post(f"/api/finances/entries/{line['id']}/validate/").json()["code"] == "own_entry"
    assert tre_api.post(f"/api/finances/entries/{line['id']}/validate/").json()["status"] == "validated"


def test_unchanged_line_is_still_validated_in_one_step():
    cac_api, _, tre_api, _ = _pair()
    line = entry(cac_api).json()
    # Sending the same values changes nothing and doesn't mark the line.
    tre_api.patch(f"/api/finances/entries/{line['id']}/", {"amount": line["amount"]}, format="json")
    assert tre_api.post(f"/api/finances/entries/{line['id']}/validate/").json()["status"] == "validated"


def test_a_line_waiting_to_be_finalised_before_the_change_still_can_be():
    """Lines put "À finaliser" under the 2026-10-30 morning rule keep their
    Finaliser / Renvoyer."""
    cac_api, cac, tre_api, tre = _pair()
    line = entry(cac_api).json()
    Entry.objects.filter(pk=line["id"]).update(status=Entry.Status.TO_CONFIRM, edited_by=tre, validated_by=tre)
    no_reason = cac_api.post(f"/api/finances/entries/{line['id']}/confirm/", {"accept": False}, format="json")
    assert no_reason.json()["code"] == "reason_required"
    assert tre_api.post(f"/api/finances/entries/{line['id']}/confirm/", {"accept": True}, format="json").json()["code"] == "own_edit"
    r = cac_api.post(f"/api/finances/entries/{line['id']}/confirm/", {"accept": True}, format="json")
    assert r.json()["status"] == "validated" and r.json()["confirmed_by_name"] == cac.short_name


def test_only_finance_approvers_edit():
    cac_api, _, _, _ = _pair()
    line = entry(cac_api).json()
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
