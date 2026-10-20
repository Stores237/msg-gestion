import secrets
import string

from django.core.management.base import BaseCommand
from django.db import transaction

from apps.accounts.models import Role, User
from apps.accounts.phone import normalize_phone
from apps.accounts.services import assign_role


class Command(BaseCommand):
    """Create a back-office super admin when nobody can log in yet (a fresh
    environment has no super admin to do it from the back-office).

    Goes through services.assign_role, so the assignment is dated, has a
    reason and is in the audit log like any other. Idempotent: an existing
    member keeps their credentials and only gains the missing roles.
    Prints the generated temporary password and PIN once.
    """

    help = "Create (or complete) a super admin with a temporary password and PIN."

    def add_arguments(self, parser):
        parser.add_argument("phone")
        parser.add_argument("last_name")
        parser.add_argument("first_name")
        parser.add_argument("--reason", default="Mise en place : premier super admin")

    def handle(self, phone, last_name, first_name, reason, **options):
        phone = normalize_phone(phone)
        with transaction.atomic():
            user, created = User.objects.get_or_create(phone=phone, defaults={"last_name": last_name, "first_name": first_name})
            password = pin = None
            if created:
                alphabet = string.ascii_letters + string.digits
                password = "".join(secrets.choice(alphabet) for _ in range(16))
                pin = f"{secrets.randbelow(10**4):04d}"
                user.set_password(password)
                user.set_pin(pin)
                user.save()
            held = user.role_slugs()
            for slug in ("super-admin", "membre"):
                if slug not in held:
                    assign_role(user, Role.objects.get(slug=slug), reason=reason, by=None)
        if created:
            self.stdout.write(f"{user.full_name}\t{user.phone}\tpassword={password}\tpin={pin}")
        else:
            self.stdout.write(f"{user.full_name}\t{user.phone}\talready existed — credentials unchanged")
