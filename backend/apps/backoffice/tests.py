import pytest
from django.test import Client
from django.utils import timezone

from apps.accounts.factories import UserFactory, give_role
from apps.accounts.models import Role
from apps.core import sms
from apps.core.models import AuditLog

pytestmark = pytest.mark.django_db
PASSWORD = "correct-horse-battery"


@pytest.fixture
def codes(monkeypatch):
    """Capture the dev-mode one-time code instead of reading logs."""
    sent = {}
    original = sms.secrets.randbelow

    def fake(n):
        value = original(n)
        sent["code"] = f"{value:06d}"
        return value

    monkeypatch.setattr(sms.secrets, "randbelow", fake)
    return sent


@pytest.fixture
def admin_user():
    user = UserFactory(phone="+237677000001", password=PASSWORD)
    give_role(user, "super-admin")
    return user


def _password_step(client, phone="677000001", password=PASSWORD):
    return client.post("/bo/connexion/", {"phone": phone, "password": password})


def test_full_two_step_login(client, admin_user, codes):
    r = _password_step(client)
    assert r.status_code == 302 and r["Location"] == "/bo/connexion/code/"
    # Password alone is not a session.
    assert client.get("/bo/").status_code == 302
    r = client.post("/bo/connexion/code/", {"code": codes["code"]})
    assert r.status_code == 302 and r["Location"] == "/bo/"
    assert client.get("/bo/").status_code == 200
    assert AuditLog.objects.filter(action="Connexion back-office", actor=admin_user).exists()


def test_wrong_code_refused(client, admin_user, codes):
    _password_step(client)
    wrong = "000000" if codes["code"] != "000000" else "111111"
    assert client.post("/bo/connexion/code/", {"code": wrong}).status_code == 401
    assert client.get("/bo/").status_code == 302


def test_code_is_single_use(codes):
    sms.send_code("+237677000001")
    assert sms.check_code("+237677000001", codes["code"])
    assert not sms.check_code("+237677000001", codes["code"])


def test_wrong_password_same_message_as_unknown_number(client, admin_user):
    a = _password_step(client, password="nope")
    b = _password_step(client, phone="699999999")
    assert a.status_code == b.status_code == 401
    assert "Numéro ou mot de passe incorrect." in a.content.decode()
    assert "Numéro ou mot de passe incorrect." in b.content.decode()


def test_member_without_backoffice_permission_cannot_log_in(client):
    """Even with a valid password: a plain member has no back-office rights."""
    user = UserFactory(phone="+237677452108", password=PASSWORD)
    give_role(user, "membre")
    assert _password_step(client, phone="677452108").status_code == 401


def test_trusted_device_skips_the_code(client, admin_user, codes):
    _password_step(client)
    client.post("/bo/connexion/code/", {"code": codes["code"], "trust": "1"})
    assert "bo_trust" in client.cookies
    cookie = client.cookies["bo_trust"].value
    fresh = Client()
    fresh.cookies["bo_trust"] = cookie
    r = _password_step(fresh)
    assert r["Location"] == "/bo/"


def test_password_change_revokes_trusted_devices(client, admin_user, codes):
    _password_step(client)
    client.post("/bo/connexion/code/", {"code": codes["code"], "trust": "1"})
    cookie = client.cookies["bo_trust"].value
    admin_user.set_password("a-brand-new-password")
    admin_user.save()
    fresh = Client()
    fresh.cookies["bo_trust"] = cookie
    assert _password_step(fresh, password="a-brand-new-password")["Location"] == "/bo/connexion/code/"


def test_login_form_rate_limited(client, admin_user):
    statuses = [_password_step(client, password="nope").status_code for _ in range(21)]
    assert statuses[-1] == 429


@pytest.fixture
def logged_in(client, admin_user, codes):
    _password_step(client)
    client.post("/bo/connexion/code/", {"code": codes["code"]})
    return client


@pytest.mark.parametrize("url", ["/bo/", "/bo/utilisateurs/", "/bo/roles/", "/bo/roles/tresorier/", "/bo/journal/"])
def test_pages_render(logged_in, url):
    assert logged_in.get(url).status_code == 200


def test_pages_require_login(client):
    for url in ["/bo/", "/bo/utilisateurs/", "/bo/roles/", "/bo/journal/"]:
        r = client.get(url)
        assert r.status_code == 302 and r["Location"] == "/bo/connexion/"


def test_super_admin_dashboard_shows_finances(logged_in):
    body = logged_in.get("/bo/").content.decode()
    assert "Montant masqué" not in body and "Total dû par les membres" in body and "Bilan financier" in body


def test_users_search(logged_in):
    UserFactory(last_name="Moukouri", first_name="Danielle")
    UserFactory(last_name="Ewane", first_name="Brice")
    body = logged_in.get("/bo/utilisateurs/?q=mouk").content.decode()
    assert "Moukouri Danielle" in body and "Ewane Brice" not in body


def test_roles_matrix_edit_requires_reason_and_logs(logged_in):
    role = Role.objects.get(slug="tresorier")
    before = set(role.permissions.values_list("resource", "action"))
    wanted = [f"{r}:{a}" for r, a in before] + ["announcements.posts:delete"]
    r = logged_in.post("/bo/roles/tresorier/", {"perm": wanted, "reason": ""}, follow=True)
    assert "Le motif est obligatoire" in r.content.decode()
    assert set(role.permissions.values_list("resource", "action")) == before

    logged_in.post("/bo/roles/tresorier/", {"perm": wanted, "reason": "Appels à contribution"})
    assert ("announcements.posts", "delete") in set(role.permissions.values_list("resource", "action"))
    assert AuditLog.objects.filter(action="Permission modifiée").count() == 1


def test_locked_cell_cannot_be_posted_on(logged_in):
    """A forged POST ticking a locked cell is ignored, not applied."""
    role = Role.objects.get(slug="tresorier")
    wanted = [f"{r}:{a}" for r, a in role.permissions.values_list("resource", "action")] + ["calendar.planning:create"]
    logged_in.post("/bo/roles/tresorier/", {"perm": wanted, "reason": "test"})
    assert not role.permissions.filter(resource="calendar.planning", action="create").exists()


def test_only_a_super_admin_gets_into_the_backoffice(client, codes):
    """Owner, 2026-10-23: the back-office administers the platform. A group
    officer is refused even with a valid password, whatever their roles."""
    for phone, slug in (("677000002", "president"), ("677000003", "tresorier"), ("677000004", "commissaire-aux-comptes")):
        user = UserFactory(phone=f"+237{phone}", password=PASSWORD)
        give_role(user, slug)
        assert _password_step(client, phone=phone).status_code == 401


def test_session_ends_when_super_admin_role_is_revoked(logged_in, admin_user):
    from apps.accounts.models import RoleAssignment

    RoleAssignment.objects.filter(user=admin_user, role__slug="super-admin").update(revoked_at=timezone.now())
    r = logged_in.get("/bo/utilisateurs/")
    assert r.status_code == 302 and r["Location"].endswith("/bo/connexion/")


def test_finance_code_switch_and_expense_domains(logged_in):
    """Owner, 2026-10-30: each group turns the finance code on, and names its
    expense domains with the role that approves first."""
    from apps.core.models import Settings
    from apps.finances.models import ExpenseDomain

    page = logged_in.get("/bo/parametres/").content.decode()
    assert "Code finances obligatoire" in page and "Domaines de dépense" in page
    st = Settings.get()
    logged_in.post("/bo/parametres/", {"finance_code_form": "1", "finance_code_required": "on"})
    st.refresh_from_db()
    assert st.finance_code_required
    logged_in.post("/bo/parametres/", {"finance_code_form": "1"})
    st.refresh_from_db()
    assert not st.finance_code_required

    censeur = Role.objects.get(slug="censeur-general")
    formation = ExpenseDomain.objects.get(name="Formation")
    logged_in.post("/bo/parametres/listes/", {f"x{formation.pk}_name": "Formation", f"x{formation.pk}_lead": str(censeur.pk),
                                               "x_new_name": "Matériel", "x_new_lead": ""})
    formation.refresh_from_db()
    assert formation.lead_role == censeur
    assert ExpenseDomain.objects.get(name="Matériel").lead_role is None
