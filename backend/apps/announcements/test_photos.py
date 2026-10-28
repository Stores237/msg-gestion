"""Photos in announcements (owner, 2026-10-28): one landscape 4:3 frame,
2 MB at most, 4 per announcement; checked on the server too."""

import io
import os

import pytest
from django.core.files.uploadedfile import SimpleUploadedFile
from PIL import Image

from .tests import _pdf, client_for

pytestmark = pytest.mark.django_db


def _jpeg(width, height, *, noise=False, quality=85, name="photo.jpg"):
    im = Image.frombytes("RGB", (width, height), os.urandom(width * height * 3)) if noise else Image.new("RGB", (width, height), (40, 120, 70))
    buf = io.BytesIO()
    im.save(buf, "JPEG", quality=quality)
    return SimpleUploadedFile(name, buf.getvalue(), content_type="image/jpeg")


def _post(api, aid, f):
    return api.post(f"/api/announcements/{aid}/attachments/", {"file": f}, format="multipart")


def test_a_framed_photo_is_accepted_others_are_explained():
    api, _ = client_for("secretaire-general")
    aid = api.post("/api/announcements/", {"title": "Sortie", "body": "Photos"}, format="json").json()["id"]
    ok = _post(api, aid, _jpeg(1280, 960))
    assert ok.status_code == 201 and ok.json()["content_type"] == "image/jpeg"
    assert _post(api, aid, _jpeg(1000, 1000)).json()["code"] == "photo_frame"
    assert _post(api, aid, _jpeg(960, 1280)).json()["code"] == "photo_frame"  # portrait
    assert _post(api, aid, _jpeg(240, 180)).json()["code"] == "photo_size"
    assert _post(api, aid, _jpeg(2400, 1800)).json()["code"] == "photo_size"
    heavy = _jpeg(2048, 1536, noise=True, quality=100)
    assert heavy.size > 2 * 1024 * 1024
    assert _post(api, aid, heavy).json()["code"] == "photo_too_large"
    # PDFs keep their own limit (10 MB) and don't count as photos.
    assert _post(api, aid, _pdf()).status_code == 201


def test_four_photos_per_announcement():
    api, _ = client_for("secretaire-general")
    aid = api.post("/api/announcements/", {"title": "Album", "body": ""}, format="json").json()["id"]
    for _ in range(4):
        assert _post(api, aid, _jpeg(1280, 960)).status_code == 201
    assert _post(api, aid, _jpeg(1280, 960)).json()["code"] == "too_many_photos"
