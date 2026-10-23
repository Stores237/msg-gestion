"""The super admin can do and see everything, finances included (owner,
2026-10-23). The code grants it regardless (User.permission_set); this ticks
every cell in the database too, so the roles matrix shows it."""

from django.db import migrations

CELLS = {
    "members.profile": ["view", "create", "change", "delete", "export"],
    "members.minor_contacts": ["view", "change", "export"],
    "finances.cashbook": ["view", "create", "change", "validate", "delete", "export"],
    "finances.solidarity": ["view", "create", "change", "validate", "delete", "export"],
    "finances.report": ["view", "validate", "export"],
    "calendar.events": ["view", "create", "change", "delete", "export"],
    "calendar.attendance": ["view", "change", "export"],
    "calendar.planning": ["view", "create", "change", "validate", "delete", "export"],
    "announcements.posts": ["view", "create", "change", "delete"],
    "backoffice.users": ["view", "create", "change", "delete", "export"],
    "backoffice.audit": ["view", "export"],
}


def forward(apps, schema_editor):
    Role = apps.get_model("accounts", "Role")
    RolePermission = apps.get_model("accounts", "RolePermission")
    role = Role.objects.filter(slug="super-admin").first()
    if role is None:
        return
    for res, acts in CELLS.items():
        for act in acts:
            RolePermission.objects.get_or_create(role=role, resource=res, action=act)


class Migration(migrations.Migration):
    dependencies = [("accounts", "0007_finance_rights")]

    operations = [migrations.RunPython(forward, migrations.RunPython.noop)]
