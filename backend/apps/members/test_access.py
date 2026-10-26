"""The access process (owner, 2026-10-23): the group leader requests in the
app → the partner creates the access in the back-office → the leader gets
the temporary PIN in the app → the member signs in and sees their role."""

import pytest
from django.test import Client
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import RefreshToken

from apps.accounts.factories import UserFactory, give_role
from apps.accounts.models import User
from apps.core import sms
from apps.core.group_admin import create_group
from apps.core.models import AuditLog, Membership, Notification
from apps.members.models import AccessRequest

pytestmark = pytest.mark.django_db
PASSWORD = "correct-horse-battery"


def api_for(*slugs):
    user = UserFactory()
    for s in slugs:
        give_role(user, s)
    api = APIClient()
    api.force_authenticate(user)
    return api, user


@pytest.fixture
def partner(monkeypatch):
    """A super admin logged into the back-office."""
    sent = {}
    original = sms.secrets.randbelow

    def fake(n):
        v = original(n)
        sent["v"] = v  # the last code sent
        return v

    monkeypatch.setattr(sms.secrets, "randbelow", fake)
    admin = UserFactory(phone="+237677000001", password=PASSWORD, membership=False)
    give_role(admin, "super-admin")
    give_role(UserFactory(membership=False), "super-admin")
    c = Client()
    c.post("/bo/connexion/", {"phone": "677000001", "password": PASSWORD})
    c.post("/bo/connexion/code/", {"code": f"{sent['v']:06d}"})
    return c


REQ = {"last_name": "Mbarga", "first_name": "Rose", "phone": "690112233", "role": "tresorier", "note": "Élue en AG"}


def test_only_leaders_request_and_direct_registration_is_gone():
    leader, _ = api_for("secretaire-general")
    member, _ = api_for("membre")
    assert member.post("/api/members/access-requests/", REQ, format="json").status_code == 403
    r = leader.post("/api/members/access-requests/", REQ, format="json")
    assert r.status_code == 201 and r.json()["status"] == "pending" and r.json()["role_name"] == "Trésorier"
    again = leader.post("/api/members/access-requests/", REQ, format="json")
    assert again.status_code == 400 and "phone" in again.json()
    old = leader.post("/api/members/", {"last_name": "X", "first_name": "Y", "phone": "690000001"}, format="json")
    assert (old.status_code, old.json()["code"]) == (410, "use_access_request")
    assert leader.post("/api/members/access-requests/", {**REQ, "phone": "690112299", "role": "super-admin"}, format="json").status_code == 400


def test_full_process_request_create_pin_once_then_member_signs_in(partner):
    leader_api, leader = api_for("secretaire-general")
    rid = leader_api.post("/api/members/access-requests/", {**REQ, "registration_paid": True}, format="json").json()["id"]
    page = partner.get("/bo/demandes-acces/").content.decode()
    assert "Mbarga Rose" in page
    partner.post(f"/bo/demandes-acces/{rid}/", {"approve": "1"})
    req = AccessRequest.objects.get(pk=rid)
    assert req.status == "approved" and len(req.temp_pin) == 4
    rose = User.objects.get(phone="+237690112233")
    assert rose.pin_must_change and rose.role_slugs() == {"membre", "tresorier"}
    assert Membership.objects.filter(user=rose).exists()
    assert Notification.objects.filter(user=leader, title__startswith="Accès créé").exists()
    listed = leader_api.get("/api/members/access-requests/").json()[0]
    assert listed["pin_ready"] is True
    first = leader_api.post(f"/api/members/access-requests/{rid}/pin/")
    pin = first.json()["pin"]
    assert first.status_code == 200 and first.json()["phone"] == "+237690112233"
    assert leader_api.post(f"/api/members/access-requests/{rid}/pin/").json()["code"] == "pin_gone"
    assert AuditLog.objects.filter(action="Code provisoire remis au responsable").exists()
    # The member signs in with it and sees their role.
    login = APIClient().post("/api/auth/login/", {"phone": "690112233", "pin": pin, "accept_terms": True, "terms_version": 1}, format="json").json()
    assert login["pin_must_change"] is True
    me = APIClient()
    me.credentials(HTTP_AUTHORIZATION=f"Bearer {login['access']}")
    roles = {r["slug"] for r in me.get("/api/me/").json()["roles"]}
    assert roles == {"membre", "tresorier"}
    # Registration fee: owed, and the leader's payment waits for the trésorier.
    from apps.finances.models import Due, Entry

    assert Due.objects.filter(member=rose, kind="inscription").exists()
    assert Entry.objects.get(member=rose).status == "pending"


def test_existing_account_joins_without_new_pin(partner):
    leader_api, leader = api_for("president")
    choir = create_group(name="Chorale")
    singer = UserFactory(phone="+237690445566", membership=choir)
    # Two groups now: the app names its group, as the phone does.
    first = leader.groups_joined().first()
    leader_api = APIClient()
    leader_api.credentials(HTTP_AUTHORIZATION=f"Bearer {RefreshToken.for_user(leader).access_token}", HTTP_X_GROUP=str(first.pk))
    rid = leader_api.post("/api/members/access-requests/", {**REQ, "phone": "690445566", "role": "membre"}, format="json").json()["id"]
    r = partner.post(f"/bo/demandes-acces/{rid}/", {"approve": "1"}, follow=True)
    req = AccessRequest.all_groups.get(pk=rid)
    assert req.status == "approved" and req.temp_pin == "" and req.user == singer, r.content.decode()[-3000:]
    assert Membership.all_groups.filter(user=singer).count() == 2
    assert leader_api.post(f"/api/members/access-requests/{rid}/pin/").json()["code"] == "pin_gone"


def test_refusal_needs_a_reason_and_tells_the_leader(partner):
    leader_api, leader = api_for("secretaire-general")
    rid = leader_api.post("/api/members/access-requests/", REQ, format="json").json()["id"]
    partner.post(f"/bo/demandes-acces/{rid}/", {"reason": ""})
    assert AccessRequest.objects.get(pk=rid).status == "pending"
    partner.post(f"/bo/demandes-acces/{rid}/", {"reason": "Numéro à vérifier"})
    assert AccessRequest.objects.get(pk=rid).status == "refused"
    assert Notification.objects.filter(user=leader, body="Numéro à vérifier").exists()
