import pytest
from django.core.cache import cache
from django.test import override_settings


@pytest.fixture(autouse=True)
def _local_file_storage(tmp_path):
    """Never let a developer's real Supabase credentials in .env turn a
    test's file save into a live network call (Spekooh incident,
    2026-09-08: a transient S3 blip failed 14 unrelated tests)."""
    with override_settings(
        STORAGES={
            "default": {"BACKEND": "django.core.files.storage.FileSystemStorage", "OPTIONS": {"location": str(tmp_path)}},
            "staticfiles": {"BACKEND": "django.contrib.staticfiles.storage.StaticFilesStorage"},
        }
    ):
        yield


@pytest.fixture(autouse=True)
def _clear_cache():
    """The cache is real Redis and outlives the per-test DB rollback;
    without this, throttle counters pile up across runs and 429 tests
    that have nothing to do with rate limiting."""
    cache.clear()
    yield
