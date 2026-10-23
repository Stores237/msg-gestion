from datetime import timedelta

from django.core.management.base import BaseCommand
from django.utils import timezone

from apps.accounts.models import User
from apps.core.groups import in_group
from apps.core.models import Group, Notification
from apps.core.notify import notify
from apps.events.models import Event


class Command(BaseCommand):
    """"2 heures avant" reminders, for members who switched them on. Run
    every 30 minutes; covers events starting 1h30–2h30 from now, and never
    reminds the same event twice."""

    help = "Create 2-hours-before reminder notifications."

    def handle(self, *args, **options):
        # Once per group: each group's events go to its own members.
        for group in Group.objects.filter(is_active=True):
            with in_group(group):
                self.run_for_group()

    def run_for_group(self):
        now = timezone.now()
        events = Event.objects.filter(starts_at__gte=now + timedelta(minutes=90), starts_at__lt=now + timedelta(minutes=150))
        members = list(User.objects.members().filter(status__in=[User.Status.ACTIVE, User.Status.LEAVE], is_active=True, remind_2h=True))
        sent = 0
        for e in events:
            if Notification.objects.filter(kind="reminder", target__type="event", target__id=e.pk, target__when="2h").exists():
                continue
            when = timezone.localtime(e.starts_at)
            sent += notify(members, "reminder", f"Rappel : {e.title} à {when:%H:%M}", e.place, {"type": "event", "id": e.pk, "when": "2h"})
        self.stdout.write(f"{sent} reminders for {events.count()} event(s).")
