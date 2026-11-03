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
        self.end_leaves()
        self.monthly_dues()
        tomorrow = timezone.localdate() + timedelta(days=1)
        lo = timezone.make_aware(datetime.combine(tomorrow, time.min))
        from apps.core.groups import current_group_id
        from apps.core.network import visible
        from apps.events.contingents import named_here

        gid = current_group_id()
        # This group's events and those sent down from above (build 45).
        events = visible(Event, gid).filter(starts_at__gte=lo, starts_at__lt=lo + timedelta(days=1)).select_related("group")
        members = list(User.objects.members().filter(gstatus__in=[User.Status.ACTIVE, User.Status.LEAVE], is_active=True, remind_eve=True))
        today_start = timezone.make_aware(datetime.combine(timezone.localdate(), time.min))
        sent = 0
        dresses = {gid: dress_names()}
        for e in events:
            if Notification.objects.filter(kind="reminder", target__type="event", target__id=e.pk, created_at__gte=today_start).exists():
                continue
            if e.group_id not in dresses:
                with in_group(e.group_id):
                    dresses[e.group_id] = dress_names()
            when = timezone.localtime(e.starts_at)
            dress = dresses[e.group_id].get(e.dress, "") if e.dress else ""
            body = " · ".join(x for x in [dress, e.place] if x)
            target = {"type": "event", "id": e.pk}
            # The people named for it are reminded whatever their setting.
            named = named_here(e, gid) if e.group_id != gid else []
            if named:
                sent += notify(named, "reminder", f"Rappel : vous êtes attendu(e) demain {when:%H:%M}",
                               " · ".join(x for x in [e.title, e.group.name, body] if x), target)
            ids = {u.pk for u in named}
            sent += notify([m for m in members if m.pk not in ids], "reminder", f"Rappel : {e.title} demain {when:%H:%M}",
                           " · ".join(x for x in [body, e.group.name if e.group_id != gid else ""] if x), target)
        self.stdout.write(f"{sent} reminders for {events.count()} event(s).")

    def monthly_dues(self):
        """The group's monthly contribution (Settings.dues_monthly, owner
        2026-11-02): on its day, one due per active member, once a month."""
        from apps.core.models import Settings
        from apps.finances.models import Due

        st = Settings.get()
        today = timezone.localdate()
        if not st.dues_monthly or today.day < st.dues_day:
            return
        label = f"Cotisation {today:%m/%Y}"
        members = User.objects.members().filter(gstatus=User.Status.ACTIVE, is_active=True)
        have = set(Due.objects.filter(kind=Due.Kind.MONTHLY, label=label).values_list("member_id", flat=True))
        new = [m for m in members if m.pk not in have]
        Due.objects.bulk_create([Due(member=m, kind=Due.Kind.MONTHLY, label=label, amount=st.dues_monthly, due_on=today) for m in new])
        if new:
            notify(new, "payment", "Cotisation du mois", f"{label} · {st.dues_monthly} {st.currency}.", {"type": "dues"})
            self.stdout.write(f"{len(new)} monthly due(s).")

    def end_leaves(self):
        """A member whose leave ended (Membership.leave_until in the past)
        is active again in this group; they and the audit log are told."""
        from apps.core import audit
        from apps.core.models import Membership

        today = timezone.localdate()
        ended = list(Membership.objects.filter(status=User.Status.LEAVE, leave_until__lt=today).select_related("user"))
        for m in ended:
            m.status, m.leave_until = User.Status.ACTIVE, None
            m.save(update_fields=["status", "leave_until"])
            audit.record("Retour de congé", obj=m.user, detail={"automatique": True})
            notify([m.user], "member", "Retour de congé", "Votre congé est terminé : vous êtes de nouveau actif dans le groupe.")
        if ended:
            self.stdout.write(f"{len(ended)} leave(s) ended.")
