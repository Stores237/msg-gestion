"""Owner, 2026-10-26: every bureau member posts announcements (their role is
shown on them) and acts on the calendar. Given to every bureau role of every
group; the back-office matrix can still adjust it afterwards."""

from django.db import migrations

GRANTS = [
    ("announcements.posts", "view"), ("announcements.posts", "create"),
    ("calendar.events", "view"), ("calendar.events", "create"),
    ("calendar.events", "change"), ("calendar.events", "delete"),
]


def grant(apps, schema_editor):
    Role = apps.get_model("accounts", "Role")
    RolePermission = apps.get_model("accounts", "RolePermission")
    for role in Role.objects.filter(kind="bureau", is_archived=False):
        for resource, action in GRANTS:
            RolePermission.objects.get_or_create(role=role, resource=resource, action=action)


class Migration(migrations.Migration):
    dependencies = [("accounts", "0011_daily_roles")]
    operations = [migrations.RunPython(grant, migrations.RunPython.noop)]
