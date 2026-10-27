"""The chef de groupe and their report on an event (owner, 2026-10-27).

The chef is designated when the event is created, is told at once, and hands
in a report within REPORT_HOURS of the event's end, written in the app, as a
PDF, or both. It goes to the formateur, with the formateur adjoint, the
secrétaire général, the censeur général and the vice-censeur in copy.
"""

from django.utils import timezone

from apps.accounts.models import RoleAssignment, User
from apps.core import audit
from apps.core.notify import notify

from .models import EventReport

REPORT_TO = ["formateur"]
REPORT_CC = ["formateur-adjoint", "secretaire-general", "censeur-general", "vice-censeur"]


class ReportRule(Exception):
    def __init__(self, code, message, status=400):
        super().__init__(message)
        self.code, self.message, self.status = code, message, status


def holders(slugs):
    ids = RoleAssignment.objects.active().filter(role__slug__in=slugs).values("user")
    return list(User.objects.members().filter(pk__in=ids, is_active=True))


def _when(event):
    return timezone.localtime(event.starts_at)


def _due(event):
    return timezone.localtime(event.report_due_at)


def tell_chef(event):
    """The chef learns they coordinate the event and owe a report."""
    if event.chef is None:
        return
    when, due = _when(event), _due(event)
    notify([event.chef], "duty", "Chef de groupe",
           f"Vous êtes chef de groupe pour {event.title} le {when:%d/%m} à {when:%H:%M}. "
           f"Rapport à remettre au formateur avant le {due:%d/%m} à {due:%H:%M}.",
           {"type": "event", "id": event.pk})


def status(event, now=None):
    """'' (no chef), pending, submitted, late or missing."""
    if not event.chef_id:
        return ""
    report = getattr(event, "report", None) if _has_report(event) else None
    if report is not None:
        return "late" if report.late else "submitted"
    return "missing" if (now or timezone.now()) > event.report_due_at else "pending"


def _has_report(event):
    try:
        event.report  # noqa: B018 - reverse one-to-one raises when absent
        return True
    except EventReport.DoesNotExist:
        return False


def can_read(user, event):
    return event.chef_id == user.pk or user.can("calendar.reports", "view")


def is_read(event):
    """Opened by a bureau reader: the chef can no longer change it."""
    return _has_report(event) and event.report.read_at is not None


def can_submit(user, event, now=None):
    """The chef, once the event has started. Until the deadline they may
    hand it in again, unless a bureau reader has opened it; after the
    deadline, only a first (late) report is accepted."""
    now = now or timezone.now()
    if event.chef_id != user.pk or now < event.starts_at or is_read(event):
        return False
    return not (_has_report(event) and now > event.report_due_at)


def mark_read(event, user, request=None):
    """The first bureau reader to open the report locks it (owner,
    2026-10-27: no change after a board member has seen it). The chef
    opening their own report doesn't count."""
    report = event.report
    if report.read_at is not None or user.pk == event.chef_id or not user.can("calendar.reports", "view"):
        return
    report.read_at, report.read_by = timezone.now(), user
    report.save(update_fields=["read_at", "read_by"])
    audit.record("Rapport ouvert", actor=user, obj=event, request=request, detail={"verrouille": True})
    if event.chef_id:
        notify([event.chef], "report", f"Rapport lu : {event.title}",
               f"{user.short_name} a ouvert votre rapport ; il ne peut plus être modifié.",
               {"type": "event", "id": event.pk})


def submit(event, *, by, body, upload=None, request=None):
    now = timezone.now()
    if event.chef_id != by.pk:
        raise ReportRule("chef_only", "Seul le chef de groupe de l’événement remet le rapport.", status=403)
    if now < event.starts_at:
        raise ReportRule("too_early", "Le rapport se remet une fois l’événement commencé.")
    if is_read(event):
        r = event.report
        who = r.read_by.short_name if r.read_by else "un membre du bureau"
        raise ReportRule("report_read", f"Le rapport a été ouvert par {who} : il ne peut plus être modifié.", status=409)
    if _has_report(event) and now > event.report_due_at:
        raise ReportRule("report_locked", "Le délai de 24 h est passé : le rapport remis ne peut plus être modifié.", status=409)
    body = (body or "").strip()
    report = event.report if _has_report(event) else None
    if not body and upload is None and not (report and report.file):
        raise ReportRule("report_empty", "Écrivez le rapport ou joignez un PDF.")
    first = report is None
    if report is None:
        report = EventReport(event=event)
    report.author, report.body, report.submitted_at = by, body, now
    if upload is not None:
        if report.file:
            report.file.delete(save=False)
        report.file_name = (upload.name or "rapport.pdf").rsplit("/", 1)[-1][:160]
        report.file.save(f"{event.pk}-{report.file_name}", upload, save=False)
    report.save()
    event.report = report
    audit.record("Rapport remis" if first else "Rapport modifié", actor=by, obj=event, request=request,
                 detail={"en_retard": report.late, "pdf": bool(report.file)})
    when = _when(event)
    late = " (en retard)" if report.late else ""
    title = f"Rapport : {event.title} du {when:%d/%m}{late}"
    if not first:
        title = f"Rapport modifié : {event.title} du {when:%d/%m}"
    cc = "formateur adjoint, secrétaire général, censeur général, vice-censeur"
    target = {"type": "event", "id": event.pk}
    notify([u for u in holders(REPORT_TO) if u.pk != by.pk], "report", title,
           f"De {by.short_name}, chef de groupe. En copie : {cc}.", target)
    notify([u for u in holders(REPORT_CC) if u.pk != by.pk], "report", f"Copie · {title}",
           f"De {by.short_name}, chef de groupe, au formateur.", target)
    return report


def remind(events, now=None):
    """For send_soon_reminders: tell the chef when an event has ended, and
    the formateur and copies when the 24 h pass without a report."""
    now = now or timezone.now()
    sent = 0
    for e in events:
        if _has_report(e):
            continue
        end = e.ends_at or e.starts_at
        if e.report_reminded_at is None and end <= now < e.report_due_at:
            due = _due(e)
            sent += notify([e.chef], "report", f"Rapport attendu : {e.title}",
                           f"À remettre avant le {due:%d/%m} à {due:%H:%M}, dans l’application ou en PDF.",
                           {"type": "event", "id": e.pk})
            e.report_reminded_at = now
            e.save(update_fields=["report_reminded_at"])
        elif e.report_overdue_at is None and now > e.report_due_at:
            when = _when(e)
            title = f"Rapport non remis : {e.title} du {when:%d/%m}"
            body = f"{e.chef.short_name}, chef de groupe, n’a pas remis son rapport dans les 24 h."
            sent += notify([*holders(REPORT_TO), *holders(REPORT_CC), e.chef], "report", title, body,
                           {"type": "event", "id": e.pk})
            e.report_overdue_at = now
            e.save(update_fields=["report_overdue_at"])
    return sent
