"""Several groups on one platform (owner, 2026-10-23): what one group
holds never shows in another, and one account can belong to both."""

from datetime import timedelta

import pytest
from django.utils import timezone
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import RefreshToken

from apps.accounts.factories import UserFactory, give_role
from apps.accounts.models import Role
from apps.announcements.models import Announcement
from apps.core.group_admin import create_group
from apps.core.groups import in_group
from apps.core.models import Group, Membership, Settings
from apps.events.models import Event
from apps.finances.models import Entry

pytestmark = pytest.mark.django_db


def app_client(user, group=None):
    """A real app session (token + X-Group), as the phone sends it."""
    api = APIClient()
    headers = {"HTTP_AUTHORIZATION": f"Bearer {RefreshToken.for_user(user).access_token}"}
    if group is not None:
        headers["HTTP_X_GROUP"] = str(group.pk)
    api.credentials(**headers)
    return api


@pytest.fixture
def two_groups():
    first = Group.objects.order_by("pk").first()
    second = create_group(name="Chorale Sainte-Cécile", welcome_message="Bienvenue à la chorale !")
    return first, second


def give(user, group, slug):
    with in_group(group):
        give_role(user, slug)
        Membership.join(user, group.pk)


def test_new_group_gets_its_own_roles_and_settings(two_groups):
    first, second = two_groups
    assert Role.all_groups.get(group=second, slug="tresorier").daily  # role of the day too
    assert Role.all_groups.filter(group=second).count() == Role.all_groups.filter(group=first, is_archived=False).count()
    assert Settings.get(second).welcome_message == "Bienvenue à la chorale !"
    with in_group(second):
        assert Role.objects.filter(slug="tresorier").get().group == second
        assert Role.objects.filter(slug="super-admin").exists()  # platform role, visible everywhere


def test_data_never_crosses_groups(two_groups):
    first, second = two_groups
    a = UserFactory(membership=first)
    b = UserFactory(membership=second)
    give(a, first, "president")
    give(b, second, "president")
    start = timezone.now() + timedelta(days=2)
    with in_group(first):
        Event.objects.create(kind="assise", title="Assise", starts_at=start)
        Announcement.objects.create(title="Annonce A", body="x", author=a)
    with in_group(second):
        Event.objects.create(kind="assise", title="Répétition", starts_at=start)
    api_a, api_b = app_client(a), app_client(b)
    assert [e["title"] for e in api_a.get("/api/events/").json()] == ["Assise"]
    assert [e["title"] for e in api_b.get("/api/events/").json()] == ["Répétition"]
    names_b = {m["full_name"] for m in api_b.get("/api/members/").json()["results"]}
    assert b.full_name in names_b and a.full_name not in names_b
    assert api_b.get(f"/api/members/{a.pk}/").status_code == 404
    assert api_b.get("/api/announcements/").json()["results"] == []
    assert [x["title"] for x in api_a.get("/api/announcements/").json()["results"]] == ["Annonce A"]


def test_one_account_two_groups_picks_with_header(two_groups):
    first, second = two_groups
    m = UserFactory(membership=first)
    give(m, first, "tresorier")
    give(m, second, "membre")
    me1 = app_client(m, first).get("/api/me/").json()
    me2 = app_client(m, second).get("/api/me/").json()
    assert {g["id"] for g in me1["groups"]} == {first.pk, second.pk}
    assert me1["group"]["id"] == first.pk and "finances" in me1["tabs"]
    assert me2["group"]["id"] == second.pk and "finances" not in me2["tabs"]
    assert me2["group"]["welcome_message"] == "Bienvenue à la chorale !"
    assert me2["group"]["color"] == "#2E7D46"  # each group has its own colour


def test_header_for_a_group_you_are_not_in_is_refused(two_groups):
    first, second = two_groups
    m = UserFactory(membership=first)
    r = app_client(m, second).get("/api/me/")
    assert (r.status_code, r.json()["code"]) == (403, "not_in_group")
    lonely = UserFactory(membership=False)
    r = app_client(lonely).get("/api/me/")
    assert (r.status_code, r.json()["code"]) == (403, "no_group")


def test_money_stays_in_its_group(two_groups):
    first, second = two_groups
    cac = UserFactory(membership=second)
    give(cac, second, "commissaire-aux-comptes")
    body = {"direction": "in", "amount": 1000, "category": "aide_don", "label": "Don", "date": "2026-10-20"}
    assert app_client(cac, second).post("/api/finances/entries/", body, format="json").status_code == 201
    assert Entry.all_groups.get().group == second
    tre = UserFactory(membership=first)
    give(tre, first, "tresorier")
    assert app_client(tre, first).get("/api/finances/entries/").json() == []
    assert app_client(tre, first).get("/api/finances/summary/").json()["balance"] == 0


def test_each_group_has_its_own_activity_types(two_groups):
    from apps.events.models import ActivityType

    first, second = two_groups
    assert ActivityType.all_groups.filter(group=second, slug="assise").exists()  # copied at creation
    with in_group(second):
        ActivityType.objects.create(slug="repetition", name="Répétition", counts_presence=True)
    leader = UserFactory(membership=second)
    give(leader, second, "secretaire-general")
    api = app_client(leader, second)
    start = (timezone.now() + timedelta(days=3)).isoformat()
    r = api.post("/api/events/", {"kind": "repetition", "title": "Répétition", "starts_at": start, "chef": leader.pk}, format="json")
    assert r.status_code == 201, r.json()
    assert r.json()["kind_name"] == "Répétition"
    kinds = {k["slug"] for k in api.get("/api/settings/").json()["activity_types"]}
    assert "repetition" in kinds
    other = UserFactory(membership=first)
    give(other, first, "secretaire-general")
    r = app_client(other, first).post("/api/events/", {"kind": "repetition", "title": "X", "starts_at": start}, format="json")
    assert r.status_code == 400 and "kind" in r.json()


def test_status_is_per_group(two_groups):
    """Owner, 2026-10-23: on leave in one group, active in another;
    suspended in one group closes only that group."""
    first, second = two_groups
    m = UserFactory(membership=first)
    give(m, first, "membre")
    give(m, second, "membre")
    Membership.all_groups.filter(user=m, group=first).update(status="conge")
    Membership.all_groups.filter(user=m, group=second).update(status="actif")
    leader1 = UserFactory(membership=first)
    give(leader1, first, "secretaire-general")
    leader2 = UserFactory(membership=second)
    give(leader2, second, "secretaire-general")
    row1 = next(r for r in app_client(leader1, first).get("/api/members/").json()["results"] if r["id"] == m.pk)
    row2 = next(r for r in app_client(leader2, second).get("/api/members/").json()["results"] if r["id"] == m.pk)
    assert (row1["status"], row2["status"]) == ("conge", "actif")
    assert app_client(m, first).get("/api/me/").json()["status"] == "conge"
    Membership.all_groups.filter(user=m, group=first).update(status="suspendu")
    assert app_client(m, first).get("/api/me/").json()["code"] == "not_in_group"
    me = app_client(m).get("/api/me/").json()
    assert me["group"]["id"] == second.pk and [g["id"] for g in me["groups"]] == [second.pk]
