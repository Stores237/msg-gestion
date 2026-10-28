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
