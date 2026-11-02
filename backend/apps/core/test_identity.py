"""Huddle (owner, 2026-11-02): like a Slack workspace, each group shows its
own name, sigle and logo; the président changes them in the app, the super
admin in the back-office."""

import io

import pytest
from django.core.files.uploadedfile import SimpleUploadedFile
from PIL import Image
from rest_framework.test import APIClient

from apps.accounts.factories import UserFactory, give_role
from apps.core.models import AuditLog, Group

pytestmark = pytest.mark.django_db


def api_for(*slugs):
    u = UserFactory()
    for s in slugs:
        give_role(u, s)
    api = APIClient()
    api.force_authenticate(u)
    return api, u


def png(w=800, h=400):
    buf = io.BytesIO()
    Image.new("RGB", (w, h), (14, 159, 143)).save(buf, "PNG")
    return SimpleUploadedFile("logo.png", buf.getvalue(), content_type="image/png")


def test_initials_and_sigle():
    g = Group(name="Chorale Saint Joseph de la Paix")
    assert g.initials == "CSJ"
    g.short_name = "msg"
    assert g.initials == "MSG"


def test_me_shows_the_groups_identity():
    api, _ = api_for("membre")
    me = api.get("/api/me/").json()
    group = me["group"]
    assert {"name", "initials", "logo", "color"} <= set(group) and group["logo"] is None
    assert all({"name", "initials", "logo"} <= set(g) for g in me["groups"])


def test_the_president_renames_and_sets_the_logo():
    api, _ = api_for("president")
    r = api.patch("/api/group/", {"name": "Garde Suisse de Yapoma", "short_name": "g s y"}, format="json")
    assert r.status_code == 200 and r.json()["name"] == "Garde Suisse de Yapoma" and r.json()["initials"] == "GSY"
    assert AuditLog.objects.filter(action="Nom du groupe modifié").exists()
    r = api.post("/api/group/logo/", {"logo": png()}, format="multipart")
    assert r.status_code == 200 and r.json()["logo"]
    g = Group.objects.get(name="Garde Suisse de Yapoma")
    with Image.open(g.logo) as im:
        assert im.size == (512, 512)  # cropped to a square
    assert api.delete("/api/group/logo/").json()["logo"] is None
    assert api.patch("/api/group/", {"name": " "}, format="json").json()["code"] == "name_required"


def test_a_member_cannot_change_them():
    api, _ = api_for("membre")
    assert api.patch("/api/group/", {"name": "X"}, format="json").status_code == 403
    assert api.post("/api/group/logo/", {"logo": png()}, format="multipart").status_code == 403
    bad = SimpleUploadedFile("x.png", b"not an image", content_type="image/png")
    pres, _ = api_for("president")
    assert pres.post("/api/group/logo/", {"logo": bad}, format="multipart").json()["code"] == "file_type"
