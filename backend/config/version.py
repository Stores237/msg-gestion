"""The platform's version (owner, 2026-10-28). One number for the app and the
server: it must equal `version` in app/pubspec.yaml without the build number
(test_version keeps them together). Bump both per RELEASING.md."""

import os

VERSION = "0.1.0"


def commit():
    """The deployed git commit, short; Render sets RENDER_GIT_COMMIT."""
    return os.environ.get("RENDER_GIT_COMMIT", "")[:7]
