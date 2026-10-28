"""Editing a person's details in the back-office (owner, 2026-10-28)."""

import io
from datetime import date

import pytest
from django.core.files.uploadedfile import SimpleUploadedFile
from PIL import Image
from rest_framework_simplejwt.token_blacklist.models import BlacklistedToken
from rest_framework_simplejwt.tokens import RefreshToken

from apps.accounts.factories import UserFactory, give_role
from apps.accounts.models import User
from apps.backoffice.test_staff import boss, login, staff_member  # noqa: F401 - fixtures
from apps.core.models import AuditLog

pytestmark = pytest.mark.django_db


def _member(**kw):
    m = UserFactory(**kw)
    give_role(m, "membre")
    return m


def _form(m, **kw):
    data = {"action": "identity", "last_name": m.last_name, "first_name": m.first_name,
            "birth_date": m.birth_date.isoformat() if m.birth_date else "", "joined_on": m.joined_on.isoformat(),
            "city": m.city, "parent_name": m.parent_name, "parent_relation": m.parent_relation, "parent_phone": m.parent_phone}
    if m.is_diaspora:
        data["is_diaspora"] = "1"
    return data | kw


def test_edit_identity_journals_old_and_new(boss):  # noqa: F811
    m = _member(last_name="Mbarg", first_name="Rose")
    page = boss.get(f"/bo/utilisateurs/{m.pk}/").content.decode()
    assert 'id="dlg-identity"' in page and 'id="edit-phone"' in page
    r = boss.post(f"/bo/utilisateurs/{m.pk}/", _form(m, last_name="Mbarga", is_diaspora="1", city="Lyon, France"))
    assert r.status_code == 302
    m.refresh_from_db()
    assert (m.last_name, m.is_diaspora, m.city) == ("Mbarga", True, "Lyon, France")
    log = AuditLog.objects.get(action="Identité modifiée")
    assert log.detail["Nom"] == {"avant": "Mbarg", "apres": "Mbarga"}
    assert set(log.detail) == {"Nom", "Diaspora", "Ville"}


def test_identity_errors_reopen_the_dialog_and_change_nothing(boss):  # noqa: F811
    m = _member(last_name="Ndi")
    # A minor needs a parent's phone.
    minor = date(date.today().year - 15, 1, 1).isoformat()
    r = boss.post(f"/bo/utilisateurs/{m.pk}/", _form(m, last_name="Autre", birth_date=minor))
    page = r.content.decode()
    assert r.status_code == 400 and "obligatoire pour un mineur" in page
    assert "document.getElementById('dlg-identity').showModal()" in page and 'value="Autre"' in page
    m.refresh_from_db()
    assert m.last_name == "Ndi"
    r = boss.post(f"/bo/utilisateurs/{m.pk}/", _form(m, first_name=" "))
    assert r.status_code == 400 and "Nom et prénoms sont obligatoires." in r.content.decode()
    # A bad photo doesn't save the rest either.
    bad = SimpleUploadedFile("x.jpg", b"not an image", content_type="image/jpeg")
    r = boss.post(f"/bo/utilisateurs/{m.pk}/", _form(m, last_name="Autre", photo=bad))
    assert r.status_code == 400 and "JPEG ou PNG" in r.content.decode()
    m.refresh_from_db()
    assert m.last_name == "Ndi"


def test_photo_replace_and_remove(boss):  # noqa: F811
    m = _member()
    buf = io.BytesIO()
    Image.new("RGB", (40, 40), "red").save(buf, "JPEG")
    boss.post(f"/bo/utilisateurs/{m.pk}/", _form(m, photo=SimpleUploadedFile("p.jpg", buf.getvalue(), "image/jpeg")))
    m.refresh_from_db()
    assert m.photo
    boss.post(f"/bo/utilisateurs/{m.pk}/", _form(m, remove_photo="1"))
    m.refresh_from_db()
    assert not m.photo
    assert AuditLog.objects.filter(action__in=["Photo modifiée", "Photo retirée"]).count() == 2


def test_phone_change_unique_reasoned_and_signs_phones_out(boss):  # noqa: F811
    m = _member(phone="+237690300001")
    _member(phone="+237690300002")
    token = RefreshToken.for_user(m)
    url = f"/bo/utilisateurs/{m.pk}/"
    r = boss.post(url, {"action": "phone", "phone": "690300003", "reason": ""})
    assert r.status_code == 400 and "motif est obligatoire" in r.content.decode()
    r = boss.post(url, {"action": "phone", "phone": "690300002", "reason": "Nouvelle puce"})
    assert r.status_code == 400 and "déjà celui d’un autre compte" in r.content.decode()
    assert AuditLog.objects.filter(action="Changement de numéro refusé", refused=True).exists()
    r = boss.post(url, {"action": "phone", "phone": "12", "reason": "Nouvelle puce"})
    assert r.status_code == 400
    r = boss.post(url, {"action": "phone", "phone": "6 90 30 00 03", "reason": "Nouvelle puce"})
    assert r.status_code == 302
    m.refresh_from_db()
    assert m.phone == "+237690300003"
    assert BlacklistedToken.objects.filter(token__jti=token["jti"]).exists()
    log = AuditLog.objects.get(action="Numéro de téléphone modifié")
    assert log.detail == {"avant": "+237690300001", "apres": "+237690300003", "motif": "Nouvelle puce"}


def test_who_may_edit(login, boss):  # noqa: F811
    m = _member()
    agent = login(staff_member("support-agent", "690000321"), "690000321")
    assert agent.post(f"/bo/utilisateurs/{m.pk}/", _form(m, last_name="X")).status_code == 403
    lead = login(staff_member("support-responsable", "690000322"), "690000322")
    assert lead.post(f"/bo/utilisateurs/{m.pk}/", _form(m, last_name="Lead")).status_code == 302
    # A platform account's details are the super admin's alone.
    admin = User.objects.get(phone="+237677000001")
    assert lead.post(f"/bo/utilisateurs/{admin.pk}/", _form(admin, last_name="X")).status_code == 403
    assert lead.post(f"/bo/utilisateurs/{admin.pk}/", {"action": "phone", "phone": "690000399", "reason": "x"}).status_code == 403
    assert boss.post(f"/bo/utilisateurs/{admin.pk}/", _form(admin, last_name="Boss")).status_code == 302
    admin.refresh_from_db()
    assert admin.last_name == "Boss"
