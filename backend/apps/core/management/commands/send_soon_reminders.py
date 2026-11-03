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
    reminds the same event twice. Also the chefs de groupe's reports: a
    reminder when the event ends, and the formateur and copies told when
    the 24 h pass without one (apps.events.reports.remind)."""

    help = "Create 2-hours-before reminders and chef de groupe report reminders."

    def handle(self, *args, **options):
        # Once per group: each group's events go to its own members.
        for group in Group.objects.filter(is_active=True):
            with in_group(group):
                self.run_for_group()

    def run_for_group(self):
        from apps.core.models import Settings

        now = timezone.now()
        # The group's delay (Settings.remind_before_hours, 2 h by default),
        # within the half-hour either side this job runs.
        ahead = timedelta(hours=Settings.get().remind_before_hours)
        from apps.core.groups import current_group_id
        from apps.core.network import visible
        from apps.events.contingents import named_here

        gid = current_group_id()
        # Also the events sent down from above (build 45).
        events = visible(Event, gid).filter(starts_at__gte=now + ahead - timedelta(minutes=30),
                                            starts_at__lt=now + ahead + timedelta(minutes=30)).select_related("group")
        members = list(User.objects.members().filter(gstatus__in=[User.Status.ACTIVE, User.Status.LEAVE], is_active=True, remind_2h=True))
        sent = 0
        for e in events:
            if Notification.objects.filter(kind="reminder", target__type="event", target__id=e.pk, target__when="2h").exists():
                continue
            when = timezone.localtime(e.starts_at)
            target = {"type": "event", "id": e.pk, "when": "2h"}
            named = named_here(e, gid) if e.group_id != gid else []
            if named:
                sent += notify(named, "reminder", f"Rappel : vous êtes attendu(e) à {when:%H:%M}",
                               " · ".join(x for x in [e.title, e.group.name, e.place] if x), target)
            ids = {u.pk for u in named}
            sent += notify([m for m in members if m.pk not in ids], "reminder", f"Rappel : {e.title} à {when:%H:%M}", e.place, target)
        self.stdout.write(f"{sent} reminders for {events.count()} event(s).")
        from apps.events import reports

        # Events of the last few days with a chef: ended, or past the 24 h.
        recent = Event.objects.select_related("chef", "report").filter(
            chef__isnull=False, starts_at__gte=now - timedelta(days=7), starts_at__lte=now,
        )
        self.stdout.write(f"{reports.remind(recent, now)} report notification(s).")
