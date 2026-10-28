"""Versioning and the developer's signature (owner, 2026-10-28)."""

import re
from pathlib import Path

import pytest
from django.test import Client

from config.version import VERSION

PUBSPEC = Path(__file__).resolve().parents[3] / "app" / "pubspec.yaml"


def test_server_and_app_share_one_version():
    """RELEASING.md: bump both together. app/pubspec.yaml is `X.Y.Z+BUILD`."""
    m = re.search(r"^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$", PUBSPEC.read_text(encoding="utf-8"), re.M)
    assert m, "app/pubspec.yaml needs version: X.Y.Z+BUILD"
    assert m.group(1) == VERSION


@pytest.mark.django_db
def test_back_office_shows_powered_by_stores_and_the_version():
    page = Client().get("/bo/connexion/").content.decode()
    assert "STORES" in page and f"MSG {VERSION}" in page
