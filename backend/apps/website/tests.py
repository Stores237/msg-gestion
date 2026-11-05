"""The public site (owner, 2026-11-05): open to anyone, its download follows
the link set in back-office → Plateforme."""

import pytest
from django.test import Client

from apps.core.models import PlatformSettings

pytestmark = pytest.mark.django_db

APK = "https://github.com/Stores237/msg-gestion/releases/download/build-48/huddle-0.1.0-build48.apk"


def test_site_is_public_and_says_huddle_and_stores():
    r = Client().get("/")
    assert r.status_code == 200
    html = r.content.decode()
    assert "Votre groupe," in html and "Les autres projets de STORES" in html
    for name in ("Spekooh", "S@Learn", "Emergensis"):
        assert name in html
    assert "/telecharger/" in html
    # Every picture's address is clean (a stray backslash once broke them all live).
    import re
    urls = re.findall(r'(?:src|data-shot|href)="([^"]*/static/[^"]*)"', html)
    assert len(urls) >= 10 and not any("\\" in u for u in urls)
    # Huddle is for every group (owner, 2026-11-05), not one movement's site.
    assert "Garde Suisse" not in html and "Pour tous les groupes qui s’organisent" in html


def test_download_without_a_link_says_soon_and_never_redirects_away():
    c = Client()
    assert "revient très bientôt" in c.get("/telecharger/").content.decode()
    r = c.get("/telecharger/apk/")
    assert r.status_code == 302 and r["Location"] == "/telecharger/"


def test_download_follows_the_back_office_link_at_once():
    p = PlatformSettings.get()
    p.app_download_url, p.app_version, p.app_size = APK, "0.1.0 (build 48)", "68 Mo"
    p.app_sha256, p.app_notes = "c2ce056de2d79aec590e4b92516a281250a5a724fe10b5ed6f7ad2f547e6db32", "Réseaux de groupes."
    p.save()
    c = Client()
    page = c.get("/telecharger/").content.decode()
    assert "Version 0.1.0 (build 48)" in page and "(68 Mo)" in page and p.app_sha256 in page and "Réseaux de groupes." in page
    assert "Version 0.1.0 (build 48) · 68 Mo" in c.get("/").content.decode()
    r = c.get("/telecharger/apk/")
    assert r.status_code == 302 and r["Location"] == APK
    assert "no-store" in r["Cache-Control"]
    # A new build: a new link, nothing to deploy.
    p.app_download_url = APK.replace("48", "49")
    p.save()
    assert c.get("/telecharger/apk/")["Location"].endswith("build49.apk")


def test_only_reading():
    assert Client().post("/telecharger/apk/").status_code == 405
