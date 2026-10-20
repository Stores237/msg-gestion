import pytest
from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import Client

from apps.accounts.factories import UserFactory, give_role
from apps.accounts.models import Role, RoleAssignment, RoleRequest, User
from apps.backoffice.models import BackofficeSession, BackupCode
from apps.core import sms
from apps.core.models import AuditLog, Settings

pytestmark = pytest.mark.django_db
PASSWORD = "correct-horse-battery"


@pytest.fixture
def codes(monkeypatch):
    sent = {}
    original = sms.secrets.randbelow

    def fake(n):
        v = original(n)
        sent["code"] = f"{v:06d}"
        return v

    monkeypatch.setattr(sms.secrets, "randbelow", fake)
    return sent


@pytest.fixture
def admin(client, codes):
    user = UserFactory(phone="+237677000001", password=PASSWORD)
    give_role(user, "super-admin")
    give_role(UserFactory(), "super-admin")  # the two-admin minimum
    client.post("/bo/connexion/", {"phone": "677000001", "password": PASSWORD})
    client.post("/bo/connexion/code/", {"code": codes["code"]})
    return user


def test_backup_code_login_when_sms_unavailable(settings):
    settings.SMS_DEV_FALLBACK = False
    settings.TWILIO_VERIFY_SERVICE_SID = None
    user = UserFactory(phone="+237677000001", password=PASSWORD)
    give_role(user, "super-admin")
    c = Client()
    # No SMS and no codes yet: refused clearly.
    assert c.post("/bo/connexion/", {"phone": "677000001", "password": PASSWORD}).status_code == 503
    codes = BackupCode.regenerate(user)
    r = c.post("/bo/connexion/", {"phone": "677000001", "password": PASSWORD})
    assert r["Location"] == "/bo/connexion/code/"
    assert "code de secours" in c.get("/bo/connexion/code/").content.decode().lower()
    assert c.post("/bo/connexion/code/", {"backup_code": "0000-0000"}).status_code == 401
    r = c.post("/bo/connexion/code/", {"backup_code": codes[0]})
    assert r["Location"] == "/bo/"
    assert BackupCode.remaining(user) == 9
    c2 = Client()
    c2.post("/bo/connexion/", {"phone": "677000001", "password": PASSWORD})
    assert c2.post("/bo/connexion/code/", {"backup_code": codes[0]}).status_code == 401  # single use


def test_closing_a_session_logs_it_out(admin, client, codes):
    other = Client()
    other.post("/bo/connexion/", {"phone": "677000001", "password": PASSWORD})
    other.post("/bo/connexion/code/", {"code": codes["code"]})
    assert other.get("/bo/").status_code == 200
    assert BackofficeSession.objects.filter(user=admin).count() == 2
    client.post("/bo/securite/", {"action": "close_others"})
    assert other.get("/bo/").status_code == 302
    assert client.get("/bo/").status_code == 200


def test_security_page_regenerates_codes(admin, client):
    body = client.post("/bo/securite/", {"action": "codes"}).content.decode()
    assert "Vos nouveaux codes de secours" in body
    assert BackupCode.remaining(admin) == 10


def test_user_detail_assign_revoke_with_rules(admin, client):
    m = UserFactory()
    give_role(m, "tresorier")
    r = client.post(f"/bo/utilisateurs/{m.id}/", {"action": "assign", "role": "commissaire-aux-comptes", "reason": "AG", "starts_on": "2026-10-01"}, follow=True)
    assert "ne peut pas être cumulé" in r.content.decode()
    client.post(f"/bo/utilisateurs/{m.id}/", {"action": "assign", "role": "conseiller", "reason": "AG", "starts_on": "2026-10-01"})
    a = RoleAssignment.objects.get(user=m, role__slug="conseiller")
    assert str(a.ends_on) == "2028-09-30"
    client.post(f"/bo/utilisateurs/{m.id}/", {"action": "revoke", "assignment": a.id, "reason": "Fin"})
    a.refresh_from_db()
    assert a.revoked_at is not None


def test_cannot_remove_below_two_super_admins_from_ui(admin, client):
    a = RoleAssignment.objects.get(user=admin, role__slug="super-admin")
    r = client.post(f"/bo/utilisateurs/{admin.id}/", {"action": "revoke", "assignment": a.id, "reason": "x"}, follow=True)
    assert "au moins 2 super admins" in r.content.decode()


def test_reset_pin_suspend_and_backoffice_access(admin, client):
    m = UserFactory()
    body = client.post(f"/bo/utilisateurs/{m.id}/", {"action": "reset_pin"}).content.decode()
    assert "Nouveau code PIN provisoire" in body
    client.post(f"/bo/utilisateurs/{m.id}/", {"action": "suspend", "reason": "3 absences"})
    m.refresh_from_db()
    assert m.status == "suspendu"
    body = client.post(f"/bo/utilisateurs/{m.id}/", {"action": "password"}).content.decode()
    m.refresh_from_db()
    assert m.has_usable_password() and BackupCode.remaining(m) == 10 and "Codes de secours" in body


def test_new_user_and_bulk(admin, client):
    r = client.post("/bo/utilisateurs/nouveau/", {"last_name": "Ndjock", "first_name": "Patrick", "phone": "674583902"})
    assert "Code PIN provisoire" in r.content.decode()
    u = User.objects.get(phone="+237674583902")
    assert u.role_slugs() == {"membre"} and u.pin_must_change
    dup = client.post("/bo/utilisateurs/nouveau/", {"last_name": "X", "first_name": "Y", "phone": "674583902"})
    assert dup.status_code == 400
    r = client.post("/bo/utilisateurs/actions/", {"ids": [u.id], "action": "reset_pin"})
    assert r["Content-Type"].startswith("text/csv") and "Ndjock Patrick" in r.content.decode("utf-8-sig")
    client.post("/bo/utilisateurs/actions/", {"ids": [u.id], "action": "suspend"})
    u.refresh_from_db()
    assert u.status == "suspendu"


def test_import_csv_valid_rows_only(admin, client):
    UserFactory(phone="+237677630219", last_name="Moukouri")
    content = "Nom;Prénoms;Téléphone;Groupe\nNdjock;Patrick;6 50 11 23 45;\nEtoundi;Carine;6 99 2;\nManga;Yves;677630219;\nBilong;Steve;6 70 34 56 12;\n"
    f = SimpleUploadedFile("membres.csv", content.encode("utf-8"), content_type="text/csv")
    client.post("/bo/utilisateurs/import/", {"file": f})
    page = client.get("/bo/utilisateurs/import/").content.decode()
    assert "Téléphone incomplet" in page and "Numéro déjà utilisé (Moukouri" in page and "Importer 2 utilisateurs" in page
    r = client.post("/bo/utilisateurs/import/", {"action": "import"})
    assert r["Content-Type"].startswith("text/csv")
    assert set(User.objects.filter(last_name__in=["Ndjock", "Bilong", "Etoundi"]).values_list("last_name", flat=True)) == {"Ndjock", "Bilong"}
    assert AuditLog.objects.filter(action="Import d’utilisateurs").exists()


def test_role_request_approved_from_dashboard(admin, client):
    m = UserFactory()
    rr = RoleRequest.objects.create(member=m, role=Role.objects.get(slug="censeur-du-jour"), starts_on="2026-10-25", ends_on="2026-10-25", reason="Veillée")
    assert "Veillée" in client.get("/bo/").content.decode()
    client.post(f"/bo/demandes/{rr.id}/", {"approve": "1"})
    rr.refresh_from_db()
    assert rr.status == "approved" and RoleAssignment.objects.filter(user=m, role__slug="censeur-du-jour").exists()


def test_assignments_page_and_renew(admin, client):
    from datetime import timedelta

    from django.utils import timezone

    m = UserFactory()
    a = give_role(m, "conseiller", starts_on=timezone.localdate() - timedelta(days=700), ends_on=timezone.localdate() + timedelta(days=20))
    body = client.get("/bo/affectations/").content.decode()
    assert "Mandat bientôt terminé" in body
    client.post(f"/bo/affectations/{a.id}/renouveler/")
    assert RoleAssignment.objects.filter(user=m, role__slug="conseiller").count() == 2


def test_role_management_and_settings(admin, client):
    client.post("/bo/roles/nouveau/", {"action": "new", "name": "Responsable matériel"})
    role = Role.objects.get(name="Responsable matériel")
    assert role.permissions.count() == 0
    client.post(f"/bo/roles/{role.slug}/gerer/", {"action": "rename", "name": "Matériel"})
    client.post(f"/bo/roles/{role.slug}/gerer/", {"action": "duplicate"})
    assert Role.objects.filter(name="Matériel (copie)").exists()
    client.post(f"/bo/roles/{role.slug}/gerer/", {"action": "archive"})
    role.refresh_from_db()
    assert role.name == "Matériel" and role.is_archived
    r = client.post("/bo/roles/membre/gerer/", {"action": "archive"}, follow=True)
    assert "ne peut pas être archivé" in r.content.decode()
    client.post("/bo/parametres/", {"fee_death": "3000", "name": "Mouvement Garde Suisse"})
    assert Settings.get().fee_death == 3000


@pytest.mark.parametrize("url", ["/bo/securite/", "/bo/affectations/", "/bo/parametres/", "/bo/utilisateurs/nouveau/", "/bo/utilisateurs/import/",
                                 "/bo/utilisateurs/export.csv", "/bo/journal/export.csv", "/bo/utilisateurs/?role=super-admin&diaspora=0"])
def test_pages_render(admin, client, url):
    assert client.get(url).status_code == 200


def test_user_detail_renders(admin, client):
    assert client.get(f"/bo/utilisateurs/{admin.id}/").status_code == 200
