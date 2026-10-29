"""Only the super admin (and the membership role) is held with no end
(owner, 2026-10-29). Every other role gets a duration — the bureau keeps its
24-month mandate, the others 12 months, changeable in the back-office — and
the assignments still open-ended get the end that duration gives."""

from calendar import monthrange
from datetime import date, timedelta

from django.db import migrations

OPEN_ENDED = {"super-admin", "membre"}
DEFAULT_MONTHS = 12


def _end(start, months):
    m = start.month - 1 + months
    year, month = start.year + m // 12, m % 12 + 1
    return start.replace(year=year, month=month, day=min(start.day, monthrange(year, month)[1])) - timedelta(days=1)


def forwards(apps, schema_editor):
    Role = apps.get_model("accounts", "Role")
    RoleAssignment = apps.get_model("accounts", "RoleAssignment")
    today = date.today()
    for role in Role.objects.exclude(slug__in=OPEN_ENDED):
        if not role.mandate_months:
            role.mandate_months = DEFAULT_MONTHS
            role.save(update_fields=["mandate_months"])
        for a in RoleAssignment.objects.filter(role=role, ends_on__isnull=True, revoked_at__isnull=True):
            end = _end(a.starts_on, role.mandate_months)
            if end < today:
                # Held for longer than the duration already: a full term from
                # today rather than an end in the past.
                end = _end(today, role.mandate_months)
            a.ends_on = end
            a.save(update_fields=["ends_on"])


class Migration(migrations.Migration):
    dependencies = [("accounts", "0016_rolepermission_reports")]
    operations = [migrations.RunPython(forwards, migrations.RunPython.noop)]
