"""Back-office shell, modern pass (owner, 2026-10-28)."""

import pytest

from apps.backoffice.test_group_delete import login  # noqa: F401 - fixture

pytestmark = pytest.mark.django_db


def test_sidebar_sections_quick_search_and_rail(login):  # noqa: F811
    page = login("677000001").get("/bo/utilisateurs/").content.decode()
    # Sections, the current page marked for assistive tech, the rail toggle.
    for text in ("Membres", "Groupe", "Plateforme", 'aria-current="page"', "bo-collapse", "data-tip=\"Utilisateurs\""):
        assert text in page
    # "Aller à…" palette and its shortcut.
    assert 'id="bo-cmd"' in page and 'aria-keyshortcuts="Control+K"' in page
    # The modern stylesheet loads after the design's.
    assert "bo-modern.css" in page


def test_account_menu_and_password_change(login):  # noqa: F811
    from apps.accounts.models import User
    from apps.backoffice.models import BackofficeSession
    from apps.core.models import AuditLog, PlatformSettings

    PlatformSettings.objects.update_or_create(pk=1, defaults={"website": "https://msg.example.org"})
    from django.contrib.sessions.backends.db import SessionStore

    a = login("677000001")
    me = User.objects.get(phone="+237677000001")
    # The same account open in another browser.
    other = SessionStore()
    other["x"] = 1
    other.create()
    BackofficeSession.objects.create(session_key=other.session_key, user=me, device="Autre navigateur")
    page = a.get("/bo/").content.decode()
    for text in ('id="bo-acct-menu"', 'data-theme="dark"', "Changer le mot de passe", "Se déconnecter",
                 'href="https://msg.example.org"'):
        assert text in page

    url = "/bo/mot-de-passe/"
    r = a.post(url, {"current": "faux", "new": "Nouveau-mot-2026", "again": "Nouveau-mot-2026"})
    assert r.status_code == 400 and "Mot de passe actuel incorrect." in r.content.decode()
    assert AuditLog.objects.filter(action="Changement de mot de passe refusé", refused=True).exists()
    from apps.backoffice.test_group_delete import PASSWORD

    r = a.post(url, {"current": PASSWORD, "new": "Nouveau-mot-2026", "again": "Autre-chose-2026"})
    assert "ne correspondent pas" in r.content.decode()
    r = a.post(url, {"current": PASSWORD, "new": "12345678901", "again": "12345678901"})
    assert r.status_code == 400  # entirely numeric: refused by the password rules
    r = a.post(url, {"current": PASSWORD, "new": "Nouveau-mot-2026", "again": "Nouveau-mot-2026"})
    assert r.status_code == 302
    me = User.objects.get(phone="+237677000001")
    assert me.check_password("Nouveau-mot-2026")
    assert AuditLog.objects.filter(action="Mot de passe modifié").exists()
    # This browser stays in; the other session is closed.
    from django.contrib.sessions.models import Session

    assert a.get("/bo/").status_code == 200
    assert not Session.objects.filter(session_key=other.session_key).exists()
    assert not BackofficeSession.objects.filter(session_key=other.session_key).exists()
