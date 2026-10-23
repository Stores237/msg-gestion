from django.core.management.base import BaseCommand
from django.db import transaction

from apps.accounts.models import Role, User
from apps.accounts.phone import normalize_phone
from apps.accounts.services import assign_role, temporary_pin

# One made-up account per staff role, so every role's screens can be
# tested on staging (owner request, 2026-10-23). Ordinary members are
# covered by add_test_members.
ROLE_TESTERS = [
    ("650300101", "Ekotto", "Bernard", ["president"]),
    ("650300102", "Mbarga", "Sylvie", ["vice-president"]),
    ("650300103", "Nyobe", "Clarisse", ["secretaire-general"]),
    ("650300104", "Tamba", "Rodrigue", ["secretaire-general-adjoint"]),
    ("650300105", "Ngono", "Pélagie", ["tresorier"]),
    ("650300106", "Fouda", "Martin", ["commissaire-aux-comptes"]),
    ("650300107", "Atangana", "Serge", ["censeur-general"]),
    ("650300108", "Biyong", "Aline", ["formateur"]),
    ("650300109", "Owono", "Paul", ["conseiller"]),
    # A plain member: the chef de groupe is designated per service now.
    ("650300110", "Essama", "Joseph", []),
    ("650300111", "Mendo", "Rosine", ["censeur-du-jour"]),
    ("650300112", "Ndzana", "Thérèse", ["formateur-adjoint"]),
]


class Command(BaseCommand):
    """Create the role testers on a shared environment. Random temporary
    PINs (changed at first login), no back-office password, roles given
    through the audited service. Existing accounts are left as they are.
    Prints each new account's PIN and roles once."""

    help = "Create one test account per staff role (staging)."

    def handle(self, *args, **options):
        for phone, last, first, slugs in ROLE_TESTERS:
            with transaction.atomic():
                user, created = User.objects.get_or_create(phone=normalize_phone(phone), defaults={"last_name": last, "first_name": first})
                if not created:
                    self.stdout.write(f"{user.full_name}\t{user.phone}\talready existed — skipped")
                    continue
                user.set_unusable_password()
                pin = temporary_pin()
                user.set_pin(pin, temporary=True)
                user.save()
                names = []
                for slug in ["membre", *slugs]:
                    role = Role.objects.get(slug=slug)
                    assign_role(user, role, reason="Compte de test (staging)", by=None)
                    if slug != "membre":
                        names.append(role.name)
            self.stdout.write(f"{user.full_name}\t{user.phone}\tpin={pin}\t{', '.join(names)}")
