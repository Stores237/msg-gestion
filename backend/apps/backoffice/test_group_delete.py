"""Editing a group, and deleting it with two super admins (owner,
2026-10-23): one asks with a reason, another confirms; the group is then
hidden with its data kept, and can be restored."""

from datetime import timedelta

import pytest
from django.test import Client
from django.utils import timezone
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import RefreshToken

from apps.accounts.factories import UserFactory, give_role
from apps.accounts.models import Role, RoleAssignment, User
from apps.core import sms
from apps.core.group_admin import create_group
from apps.core.groups import in_group
from apps.core.models import AuditLog, Group, GroupDeletion, Membership, Settings
from apps.finances.models import Due, Entry
from apps.members import services as access

pytestmark = pytest.mark.django_db
PASSWORD = "correct-horse-battery"


@pytest.fixture
def login(monkeypatch):
    sent = {}
    original = sms.secrets.randbelow

    def fake(n):
        v = original(n)
        sent["v"] = v
        return v

    monkeypatch.setattr(sms.secrets, "randbelow", fake)

    def as_admin(phone):
        user = UserFactory(phone=f"+237{phone}", password=PASSWORD, membership=False)
        give_role(user, "super-admin")
        c = Client()
        c.post("/bo/connexion/", {"phone": phone, "password": PASSWORD})
        c.post("/bo/connexion/code/", {"code": f"{sent['v']:06d}"})
        c.user = user
        return c

    return as_admin


def app_get(user, group=None):
    api = APIClient()
    headers = {"HTTP_AUTHORIZATION": f"Bearer {RefreshToken.for_user(user).access_token}"}
    if group is not None:
        headers["HTTP_X_GROUP"] = str(group.pk)
    api.credentials(**headers)
    return api.get("/api/me/")


@pytest.fixture
def choir():
    """A second group with people, roles and money in it."""
    g = create_group(name="Chorale Sainte-Cécile", place="Bonapriso")
    leader = UserFactory(membership=g)
    with in_group(g):
        give_role(leader, "secretaire-general")
        req = access.submit(by=leader, last_name="Mbarga", first_name="Rose", phone="+237690112233",
                            role=Role.objects.get(slug="tresorier"), registration_paid=True)
        access.approve(req, by=leader)
    return g


def test_edit_a_group(login, choir):
    a = login("677000001")
    login("677000002")
    r = a.post(f"/bo/groupes/{choir.pk}/modifier/", {"name": "Chorale Ste-Cécile", "parish": "Akwa", "motto": "Chanter",
                                                     "welcome_message": "Bienvenue", "color": "#5B3FA0"}, follow=True)
    assert "enregistré" in r.content.decode()
    choir.refresh_from_db()
    st = Settings.get(choir)
    assert (choir.name, st.parish, st.motto, st.welcome_message, st.color) == ("Chorale Ste-Cécile", "Akwa", "Chanter", "Bienvenue", "#5B3FA0")
    assert AuditLog.objects.filter(action="Groupe modifié", group__isnull=True).exists()
    r = a.post(f"/bo/groupes/{choir.pk}/modifier/", {"name": "X", "color": "violet"}, follow=True)
    assert "#RRVVBB" in r.content.decode()
    choir.refresh_from_db()
    assert choir.name == "Chorale Ste-Cécile"


def test_deletion_needs_a_second_super_admin(login, choir):
    a, b = login("677000001"), login("677000002")
    first = Group.objects.order_by("pk").first()
    rose = User.objects.get(phone="+237690112233")
    assert Entry.all_groups.filter(group=choir).exists() and Due.all_groups.filter(group=choir).exists()
    url = f"/bo/groupes/{choir.pk}/supprimer/"

    # A reason and the exact name are required.
    a.post(url, {"action": "request", "reason": "", "confirm_name": choir.name})
    a.post(url, {"action": "request", "reason": "Doublon", "confirm_name": "chorale"})
    assert not GroupDeletion.objects.exists()
    assert AuditLog.objects.filter(action="Suppression de groupe refusée", refused=True).count() == 2

    a.post(url, {"action": "request", "reason": "Groupe créé en double", "confirm_name": choir.name})
    assert GroupDeletion.objects.get().status == "pending"
    assert Group.objects.filter(pk=choir.pk).exists()  # nothing deleted yet
    page = a.get("/bo/groupes/").content.decode()
    assert "Suppression demandée" in page and "Confirmer la suppression" not in page

    # The one who asked cannot confirm.
    r = a.post(url, {"action": "confirm", "confirm_name": choir.name}, follow=True)
    assert "autre super admin" in r.content.decode()
    assert Group.objects.filter(pk=choir.pk).exists()

    # Another super admin confirms: the group is hidden, its data kept.
    assert "Confirmer la suppression" in b.get("/bo/groupes/").content.decode()
    r = b.post(url, {"action": "confirm", "confirm_name": choir.name}, follow=True)
    assert "données sont conservées" in r.content.decode()
    choir.refresh_from_db()
    assert not choir.is_active and choir.deleted_by == b.user
    assert Entry.all_groups.filter(group=choir).exists() and Role.all_groups.filter(group=choir).exists()
    assert RoleAssignment.all_groups.filter(user=rose).exists() and Membership.all_groups.filter(group=choir).exists()
    log = AuditLog.objects.get(action="Groupe supprimé")
    assert log.group is None and log.actor == b.user and log.detail["motif"] == "Groupe créé en double"
    # Gone from the app and from the back-office's group choice.
    assert app_get(rose).status_code == 403
    assert app_get(rose, choir).json()["code"] == "not_in_group"
    page = a.get("/bo/groupes/").content.decode()
    assert "Groupes supprimés" in page and f'value="{choir.pk}"' not in a.get("/bo/").content.decode().split("bo-group")[1].split("</form>")[0]
    assert a.post("/bo/groupes/choisir/", {"group": choir.pk}).status_code == 404
    assert Group.objects.filter(pk=first.pk, is_active=True).exists()

    # Restored as it was.
    a.post(url, {"action": "restore"})
    choir.refresh_from_db()
    assert choir.is_active and choir.deleted_at is None
    assert AuditLog.objects.filter(action="Groupe restauré").exists()
    assert app_get(rose, choir).status_code == 200


def test_cancel_expire_and_last_group(login, choir):
    a, b = login("677000001"), login("677000002")
    url = f"/bo/groupes/{choir.pk}/supprimer/"
    a.post(url, {"action": "request", "reason": "Test", "confirm_name": choir.name})
    b.post(url, {"action": "cancel"})
    assert GroupDeletion.objects.get().status == "cancelled"
    b.post(url, {"action": "confirm", "confirm_name": choir.name})
    assert Group.objects.filter(pk=choir.pk).exists()

    # A request older than 3 days lapses.
    a.post(url, {"action": "request", "reason": "Encore", "confirm_name": choir.name})
    GroupDeletion.objects.filter(status="pending").update(requested_at=timezone.now() - timedelta(days=4))
    b.post(url, {"action": "confirm", "confirm_name": choir.name})
    assert Group.objects.filter(pk=choir.pk).exists()

    # The platform's only group cannot be deleted.
    first = Group.objects.order_by("pk").first()
    Group.objects.filter(pk=choir.pk).update(is_active=False)
    r = a.post(f"/bo/groupes/{first.pk}/supprimer/", {"action": "request", "reason": "x", "confirm_name": first.name}, follow=True)
    assert "seul groupe" in r.content.decode()


def test_login_pages_work_with_several_groups(login, choir):
    """Staging, 2026-10-23: /bo/connexion/ answered 500 once a second group
    existed (the side panel asked for "the" group before any was chosen)."""
    c = Client()
    assert c.get("/bo/connexion/").status_code == 200
    assert c.post("/bo/connexion/", {"phone": "677000009", "password": "faux"}).status_code == 401  # not 500
    a = login("677000001")  # password page, code page, then the dashboard
    assert a.get("/bo/").status_code == 200
    # A hidden group still counts as a group: the pages hold.
    Group.objects.filter(pk=choir.pk).update(is_active=False)
    assert Client().get("/bo/connexion/").status_code == 200
    assert a.get("/bo/").status_code == 200


def test_platform_help_contacts_and_texts(login, choir):
    a = login("677000001")
    assert "Politique de confidentialité" in a.get("/bo/plateforme/").content.decode()
    a.post("/bo/plateforme/", {"support_phone": "659802679", "support_whatsapp": "654858138",
                               "support_email": "aide@example.org", "website": "https://msg.example.org",
                               "privacy_text": "Texte relu.", "terms_text": "Conditions relues."})
    from apps.core.models import PlatformSettings

    p = PlatformSettings.get()
    assert (p.support_phone, p.support_whatsapp, p.support_email, p.website) == ("659802679", "654858138", "aide@example.org", "https://msg.example.org")
    assert AuditLog.objects.filter(action="Réglages de la plateforme modifiés", group__isnull=True).exists()
    r = a.post("/bo/plateforme/", {"website": "pas une adresse"}, follow=True)
    assert "Valeur invalide" in r.content.decode()
    member = UserFactory(membership=Group.objects.order_by("pk").first())
    data = app_get(member).json()  # /api/me/ works; now the platform view
    api = APIClient()
    api.force_authenticate(member)
    j = api.get("/api/platform/").json()
    assert j["support_whatsapp"] == "654858138" and j["privacy_text"] == "Texte relu."
    assert data["id"] == member.pk
