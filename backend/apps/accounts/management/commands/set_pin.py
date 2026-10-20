from django.core.management.base import BaseCommand, CommandError

from apps.accounts.models import User
from apps.accounts.phone import normalize_phone


class Command(BaseCommand):
    """Set a member's PIN by hand. Local development and support only —
    the self-service PIN setup/reset by SMS is still to build (TODOS.md)."""

    help = "Set the 4-digit app PIN for the member with this phone number."

    def add_arguments(self, parser):
        parser.add_argument("phone")
        parser.add_argument("pin")

    def handle(self, phone, pin, **options):
        if not (pin.isdigit() and len(pin) == 4):
            raise CommandError("The PIN must be exactly 4 digits.")
        try:
            user = User.objects.get(phone=normalize_phone(phone))
        except User.DoesNotExist as exc:
            raise CommandError(f"No member with phone {phone}.") from exc
        user.set_pin(pin)
        user.save(update_fields=["pin", "pin_failed_attempts", "pin_locked_until"])
        self.stdout.write(self.style.SUCCESS(f"PIN set for {user.full_name}."))
