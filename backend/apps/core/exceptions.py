"""API error handler: DRF's, plus file storage failures as a clear 503."""

import logging

from botocore.exceptions import BotoCoreError, ClientError
from rest_framework.response import Response
from rest_framework.views import exception_handler

log = logging.getLogger(__name__)


def api_exception_handler(exc, context):
    # Staging, 2026-10-26: the storage refused every upload (403) and the
    # app only saw "Server Error (500)". Say what failed; Sentry still logs it.
    if isinstance(exc, (ClientError, BotoCoreError)):
        log.exception("File storage failure")
        try:
            import sentry_sdk

            sentry_sdk.capture_exception(exc)
        except Exception:  # pragma: no cover - Sentry is optional
            pass
        return Response({"detail": "Le stockage des fichiers est indisponible. Réessayez plus tard ; "
                                   "si cela continue, prévenez le partenaire.",
                         "code": "storage_unavailable"}, status=503)
    return exception_handler(exc, context)
