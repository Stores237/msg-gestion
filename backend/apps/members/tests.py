from datetime import date

import pytest
from rest_framework.test import APIClient

from apps.accounts.factories import UserFactory, give_role
from apps.accounts.models import User
from apps.core.models import AuditLog

pytestmark = pytest.mark.django_db


def client_for(*slugs):
    user = UserFactory()
    for s in slugs:
        give_role(user, s)
    api = APIClient()
    api.force_authenticate(user)
    return api, user


@pytest.fixture
def minor():
    return UserFactory(
        last_name="Essomba", first_name="Kévin", birth_date=date(2011, 3, 3), phone="+237691347702",
        parent_name="Mme Essomba Pauline", parent_relation="Mère", parent_phone="+237699123456",
    )


def test_plain_member_cannot_list_members():
    api, _ = client_for("membre")
    assert api.get("/api/members/").status_code == 403


def test_list_with_counts_and_filters():
    api, _ = client_for("secretaire-general")
    UserFactory(last_name="Mbella", status=User.Status.LEAVE)
    UserFactory(last_name="Ateba", is_diaspora=True)
    UserFactory(last_name="Gone", status=User.Status.ARCHIVED)
    body = api.get("/api/members/").json()
    assert body["counts"] == {"all": 3, "actif": 2, "conge": 1, "classe": 0, "diaspora": 1}
    assert "Gone" not in [m["last_name"] for m in body["results"]]
    assert [m["last_name"] for m in api.get("/api/members/?status=conge").json()["results"]] == ["Mbella"]
    assert [m["last_name"] for m in api.get("/api/members/?diaspora=1").json()["results"]] == ["Ateba"]
    assert [m["last_name"] for m in api.get("/api/members/?q=mbel").json()["results"]] == ["Mbella"]


def test_list_shows_roles_but_not_the_implicit_membre():
    api, sg = client_for("secretaire-general", "membre")
    row = next(m for m in api.get("/api/members/").json()["results"] if m["id"] == sg.id)
    assert [r["slug"] for r in row["roles"]] == ["secretaire-general"]


def test_list_query_count_does_not_grow_with_members(django_assert_max_num_queries):
    api, _ = client_for("secretaire-general")
    for _ in range(15):
        give_role(UserFactory(), "membre")
    with django_assert_max_num_queries(8):
        api.get("/api/members/")


def test_minor_contacts_visible_to_secretary(minor):
    api, _ = client_for("secretaire-general")
    body = api.get(f"/api/members/{minor.id}/").json()
    assert body["phone"] == "+237 6 91 34 77 02"
    assert body["parent"] == {"name": "Mme Essomba Pauline", "relation": "Mère", "phone": "+237 6 99 12 34 56"}
    assert "minor_contacts" not in body["restricted"]


def test_minor_contacts_hidden_from_censor_and_said_so(minor):
    """Design: 'Vue du formateur : contacts du mineur et finances masqués.'"""
    api, _ = client_for("censeur-general")
    body = api.get(f"/api/members/{minor.id}/").json()
    assert body["phone"] is None and body["parent"] is None
    assert set(body["restricted"]) == {"minor_contacts", "contributions"}
    assert "699123456" not in str(body) and "691347702" not in str(body)


def test_adult_phone_visible_to_censor():
    api, _ = client_for("censeur-general")
    adult = UserFactory(phone="+237677452108", birth_date=date(1992, 1, 20))
    assert api.get(f"/api/members/{adult.id}/").json()["phone"] == "+237 6 77 45 21 08"


def test_bureau_lists_mandate_roles_only():
    api, _ = client_for("membre", "censeur-general")
    treasurer = UserFactory(last_name="Fotso")
    give_role(treasurer, "tresorier", ends_on=date(2027, 9, 30))
    give_role(UserFactory(), "chef-de-groupe")
    rows = api.get("/api/members/bureau/").json()
    assert sorted(r["role"]["slug"] for r in rows) == ["censeur-general", "tresorier"]


def test_secretary_registers_a_minor_with_parent():
    api, sg = client_for("secretaire-general")
    r = api.post(
        "/api/members/",
        {"last_name": "Ndjock", "first_name": "Patrick", "phone": "6 74 58 39 02", "birth_date": "2010-03-03",
         "parent_name": "Mme Ndjock Hélène", "parent_relation": "Mère", "parent_phone": "699120044"},
        format="json",
    )
    assert r.status_code == 201, r.json()
    body = r.json()
    member = User.objects.get(pk=body["id"])
    assert member.check_pin(body["temporary_pin"]) and not member.has_usable_password()
    assert member.role_slugs() == {"membre"}
    assert member.parent_phone == "+237699120044"
    assert AuditLog.objects.filter(action="Membre inscrit", actor=sg).exists()


def test_minor_without_parent_phone_is_refused_with_a_code():
    api, _ = client_for("secretaire-general")
    r = api.post("/api/members/", {"last_name": "N", "first_name": "P", "phone": "674583902", "birth_date": "2010-03-03"}, format="json")
    assert r.status_code == 400
    assert "parent_phone" in r.json()
    assert not User.objects.filter(phone="+237674583902").exists()


def test_duplicate_phone_refused():
    api, _ = client_for("secretaire-general")
    UserFactory(phone="+237674583902")
    r = api.post("/api/members/", {"last_name": "N", "first_name": "P", "phone": "674583902"}, format="json")
    assert r.status_code == 400 and "phone" in r.json()


def test_treasurer_cannot_register_members():
    api, _ = client_for("tresorier")
    r = api.post("/api/members/", {"last_name": "N", "first_name": "P", "phone": "674583902"}, format="json")
    assert r.status_code == 403
