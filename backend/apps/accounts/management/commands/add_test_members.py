
from datetime import date

from django.core.management.base import BaseCommand
from django.db import transaction

from apps.accounts.models import Role, RoleAssignment, User
from apps.accounts.phone import normalize_phone
from apps.accounts.services import temporary_pin

from .seed_demo import PARENTS, TESTERS


class Command(BaseCommand):
    """Load the ten made-up test members (seed_demo.TESTERS) on a shared
    environment such as staging. Unlike seed_demo, every PIN is random and
    nobody gets a back-office password, so it is safe with DEBUG off.
    Existing members are skipped. Prints each new member's PIN once."""

    help = "Create the ten demo test members with random PINs (staging)."

    def handle(self, *args, **options):
        roles = {r.slug: r for r in Role.objects.all()}
        with transaction.atomic():
            for phone, last, first, status, diaspora, city, birth, slugs in TESTERS:
                user, created = User.objects.get_or_create(
                    phone=normalize_phone(phone),
                    defaults=dict(last_name=last, first_name=first, status=status, is_diaspora=diaspora, city=city, birth_date=birth),
                )
                if not created:
                    self.stdout.write(f"{user.full_name}\t{user.phone}\talready existed — skipped")
                    continue
                if phone in PARENTS:
                    user.parent_name, user.parent_relation, user.parent_phone = PARENTS[phone]
                user.set_unusable_password()  # app only, never the back-office
                pin = temporary_pin()
                user.set_pin(pin, temporary=True)
                user.save()
                for slug in slugs:
                    RoleAssignment.objects.create(
                        user=user, role=roles[slug], starts_on=date.today(), reason="Membre de test (staging)"
                    )
                self.stdout.write(f"{user.full_name}\t{user.phone}\tpin={pin}\t{', '.join(roles[s].name for s in slugs)}")
