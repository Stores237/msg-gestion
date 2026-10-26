"""Intégrations et services (owner, 2026-10-26: IT helpdesk and integration
ops): what the platform is connected to, whether each part is configured,
and a live storage test. Never shows a secret."""

import os

from django.conf import settings
from django.shortcuts import render

from .access import backoffice_view


def check_storage():
    """(ok, message) — writes, reads back and deletes a tiny file."""
    from django.core.files.base import ContentFile
    from django.core.files.storage import default_storage

    name = "diagnostic/msg-check.txt"
    try:
        saved = default_storage.save(name, ContentFile(b"ok"))
        default_storage.delete(saved)
    except Exception as e:  # botocore errors, network, permissions
        code = getattr(e, "response", {}).get("ResponseMetadata", {}).get("HTTPStatusCode") if hasattr(e, "response") else None
        return False, f"Stockage des fichiers : refusé{f' ({code})' if code else ''}. Vérifiez la clé d’accès et la région."
    return True, "Stockage des fichiers : écriture et suppression réussies."


def _services():
    storage = settings.STORAGES["default"]["BACKEND"]
    s3 = storage.endswith("S3Storage")
    opts = settings.STORAGES["default"].get("OPTIONS", {})
    sms = bool(settings.TWILIO_ACCOUNT_SID and settings.TWILIO_VERIFY_SERVICE_SID)
    push = bool(getattr(settings, "FIREBASE_CREDENTIALS", "") or getattr(settings, "FCM_CREDENTIALS", ""))
    email = getattr(settings, "EMAIL_BACKEND", "")
    return [
        {"name": "Stockage des fichiers", "what": "Photos de profil, pièces jointes des annonces",
         "state": "ok" if s3 and opts.get("access_key") else ("warn" if not s3 else "off"),
         "detail": f"Supabase Storage · bucket {opts.get('bucket_name')} · région {opts.get('region_name')}" if s3
         else "Disque du serveur (développement)", "testable": True},
        {"name": "SMS", "what": "Codes de connexion, PIN oublié, rappels",
         "state": "ok" if sms else "off", "detail": "Twilio configuré" if sms else "En attente (Twilio non configuré) : "
         "les codes de secours remplacent le SMS au back-office"},
        {"name": "Notifications push", "what": "Rappels et annonces sur le téléphone",
         "state": "ok" if push else "off", "detail": "Firebase configuré" if push else "En attente (Firebase non configuré)"},
        {"name": "E-mail", "what": "Messages au partenaire",
         "state": "ok" if "smtp" in email.lower() else "off", "detail": email.rsplit(".", 1)[-1] or "—"},
        {"name": "Suivi des erreurs", "what": "Sentry",
         "state": "ok" if os.environ.get("SENTRY_DSN") else "off",
         "detail": "Actif" if os.environ.get("SENTRY_DSN") else "Non configuré"},
        {"name": "API de l’application", "what": "Documentation pour les futures intégrations",
         "state": "ok", "detail": "/api/docs/", "link": "/api/docs/"},
    ]


@backoffice_view("backoffice.integrations", "view")
def integrations(request):
    return render(request, "backoffice/integrations.html", {
        "nav": "integrations", "services": _services(),
        "can_change": request.user.can("backoffice.integrations", "change"),
    })
