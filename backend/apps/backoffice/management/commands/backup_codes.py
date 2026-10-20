from django.core.management.base import BaseCommand, CommandError

from apps.accounts.models import User
from apps.accounts.phone import normalize_phone
from apps.backoffice.models import BackupCode


class Command(BaseCommand):
    """Print a fresh set of back-office backup codes for someone (replaces
    the old set). How a super admin first gets in before SMS exists."""

    help = "Generate 10 one-time back-office backup codes for a user."

    def add_arguments(self, parser):
        parser.add_argument("phone")

    def handle(self, phone, **options):
        try:
            user = User.objects.get(phone=normalize_phone(phone))
        except User.DoesNotExist as exc:
            raise CommandError(f"No member with phone {phone}.") from exc
        for c in BackupCode.regenerate(user):
            self.stdout.write(c)
