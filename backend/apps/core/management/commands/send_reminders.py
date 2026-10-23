from datetime import datetime, time, timedelta

from django.core.management.base import BaseCommand
from django.utils import timezone

from apps.accounts.models import User
from apps.core.groups import in_group
from apps.core.models import Group, Notification
from apps.core.notify import notify
from apps.events.models import Event, dress_names


class Command(BaseCommand):
    """Day-before reminders (design: "Rappel : assise samedi 15:00",
    "La veille à 20:00"). Run once a day in the evening — staging via
    /internal/tasks/reminders/, production as a Render Cron Job. Safe to run
    twice: an event already reminded today is skipped."""

    help = "Create reminder notifications for tomorrow's events."

    def handle(self, *args, **options):
        # Once per group: each group's events go to its own members.
        for group in Group.objects.filter(is_active=True):
            with in_group(group):
                self.run_for_group()

    def run_for_group(self):
        tomorrow = timezone.localdate() + timedelta(days=1)
        lo = timezone.make_aware(datetime.combine(tomorrow, time.min))
        events = Event.objects.filter(starts_at__gte=lo, starts_at__lt=lo + timedelta(days=1))
        members = list(User.objects.members().filter(status__in=[User.Status.ACTIVE, User.Status.LEAVE], is_active=True, remind_eve=True))
        today_start = timezone.make_aware(datetime.combine(timezone.localdate(), time.min))
        sent = 0
        dresses = dress_names()
        for e in events:
            if Notification.objects.filter(kind="reminder", target__type="event", target__id=e.pk, created_at__gte=today_start).exists():
                continue
            when = timezone.localtime(e.starts_at)
            body = " · ".join(x for x in [dresses.get(e.dress, "") if e.dress else "", e.place] if x)
            sent += notify(members, "reminder", f"Rappel : {e.title} demain {when:%H:%M}", body, {"type": "event", "id": e.pk})
        self.stdout.write(f"{sent} reminders for {events.count()} event(s).")
