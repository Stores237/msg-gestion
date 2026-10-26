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
    give_role(UserFactory(), "censeur-du-jour")
    rows = api.get("/api/members/bureau/").json()
    assert sorted(r["role"]["slug"] for r in rows) == ["censeur-general", "tresorier"]


def test_secretary_requests_a_minor_with_parent_and_partner_creates_it():
    from apps.members import services as access
    from apps.members.models import AccessRequest

    api, sg = client_for("secretaire-general")
    r = api.post(
        "/api/members/access-requests/",
        {"last_name": "Ndjock", "first_name": "Patrick", "phone": "6 74 58 39 02", "birth_date": "2010-03-03",
         "parent_name": "Mme Ndjock Hélène", "parent_relation": "Mère", "parent_phone": "699120044"},
        format="json",
    )
    assert r.status_code == 201, r.json()
    req = access.approve(AccessRequest.objects.get(pk=r.json()["id"]), by=UserFactory())
    member = req.user
    assert member.check_pin(req.temp_pin) and not member.has_usable_password()
    assert member.role_slugs() == {"membre"}
    assert member.parent_phone == "+237699120044"
    assert AuditLog.objects.filter(action="Demande d’accès envoyée", actor=sg).exists()


def test_minor_without_parent_phone_is_refused_with_a_code():
    api, _ = client_for("secretaire-general")
    r = api.post("/api/members/access-requests/", {"last_name": "N", "first_name": "P", "phone": "674583902", "birth_date": "2010-03-03"}, format="json")
    assert r.status_code == 400
    assert "parent_phone" in r.json()


def test_phone_already_in_the_group_refused():
    api, _ = client_for("secretaire-general")
    UserFactory(phone="+237674583902")
    r = api.post("/api/members/access-requests/", {"last_name": "N", "first_name": "P", "phone": "674583902"}, format="json")
    assert r.status_code == 400 and "phone" in r.json()


def test_treasurer_cannot_register_members():
    api, _ = client_for("tresorier")
    r = api.post("/api/members/", {"last_name": "N", "first_name": "P", "phone": "674583902"}, format="json")
    assert r.status_code == 403


def test_photo_upload_checked_and_listed():
    from django.core.files.uploadedfile import SimpleUploadedFile

    api, _ = client_for("secretaire-general")
    m = UserFactory()
    png = SimpleUploadedFile("p.png", b"\x89PNG\r\n\x1a\n" + b"0" * 32, content_type="image/png")
    r = api.post(f"/api/members/{m.id}/photo/", {"photo": png}, format="multipart")
    assert r.status_code == 200 and r.json()["photo"].startswith("http")
    assert api.get(f"/api/members/{m.id}/").json()["photo"]
    pdf = SimpleUploadedFile("p.jpg", b"%PDF-1.4", content_type="image/jpeg")
    assert api.post(f"/api/members/{m.id}/photo/", {"photo": pdf}, format="multipart").json()["code"] == "file_type"
    member_api, _ = client_for("tresorier")
    assert member_api.post(f"/api/members/{m.id}/photo/", {"photo": png}, format="multipart").status_code == 403


def test_every_member_changes_their_own_photo():
    from django.core.files.uploadedfile import SimpleUploadedFile

    from apps.core.models import AuditLog

    api, me = client_for("membre")  # no members.profile right
    png = SimpleUploadedFile("moi.png", b"\x89PNG\r\n\x1a\n" + b"0" * 32, content_type="image/png")
    r = api.post("/api/me/photo/", {"photo": png}, format="multipart")
    assert r.status_code == 200 and r.json()["photo"].startswith("http")
    assert api.get("/api/me/").json()["photo"] == r.json()["photo"]
    assert AuditLog.objects.filter(action="Photo de profil modifiée par le membre", actor=me).exists()
    pdf = SimpleUploadedFile("p.jpg", b"%PDF-1.4", content_type="image/jpeg")
    assert api.post("/api/me/photo/", {"photo": pdf}, format="multipart").json()["code"] == "file_type"
    assert api.delete("/api/me/photo/").json() == {"photo": None}
    assert api.get("/api/me/").json()["photo"] is None


def test_storage_failure_is_a_clear_503_not_a_500(monkeypatch):
    """Staging, 2026-10-26: Supabase refused the upload (403); the app saw 500."""
    from botocore.exceptions import ClientError
    from django.core.files.storage import default_storage
    from django.core.files.uploadedfile import SimpleUploadedFile

    def refuse(*a, **k):
        raise ClientError({"Error": {"Code": "403", "Message": "Forbidden"}}, "PutObject")

    monkeypatch.setattr(default_storage, "save", refuse)
    api, _ = client_for("membre")
    png = SimpleUploadedFile("moi.png", b"\x89PNG\r\n\x1a\n" + b"0" * 32, content_type="image/png")
    r = api.post("/api/me/photo/", {"photo": png}, format="multipart")
    assert r.status_code == 503 and r.json()["code"] == "storage_unavailable"
