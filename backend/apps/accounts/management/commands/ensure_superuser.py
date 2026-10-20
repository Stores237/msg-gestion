import os

from django.core.management.base import BaseCommand

from apps.accounts.models import User
from apps.accounts.phone import normalize_phone


class Command(BaseCommand):
    """Free-tier Render has no Shell tab, so `createsuperuser` has nowhere
    interactive to run. This runs on every container start (Dockerfile CMD)
    and does nothing unless both env vars are set and no such user exists
    yet — safe to repeat on every deploy.

    This is the Django-admin account for the technical team, not a
    back-office super admin: that is a role, assigned with a reason, in the
    back-office itself.
    """

    help = "Idempotently create a Django superuser from DJANGO_SUPERUSER_PHONE / DJANGO_SUPERUSER_PASSWORD."

    def handle(self, *args, **options):
        phone = os.environ.get("DJANGO_SUPERUSER_PHONE")
        password = os.environ.get("DJANGO_SUPERUSER_PASSWORD")
        if not phone or not password:
            self.stdout.write("DJANGO_SUPERUSER_PHONE/DJANGO_SUPERUSER_PASSWORD not set — skipping.")
            return
        phone = normalize_phone(phone)
        if User.objects.filter(phone=phone).exists():
            self.stdout.write(f"A user with phone {phone} already exists — skipping.")
            return
        user = User.objects.create_superuser(phone, password, last_name="Admin", first_name="Technique")
        self.stdout.write(self.style.SUCCESS(f"Created superuser {user.phone}."))
