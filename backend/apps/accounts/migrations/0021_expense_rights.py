"""Owner, 2026-10-30: expense requests. The commissaire aux comptes sees
them all and approves (view, validate); the trésorier sees them all and pays
(view, change). The first step belongs to each domain's lead role."""

from django.db import migrations

RIGHTS = {
    "commissaire-aux-comptes": ["view", "validate"],
    "tresorier": ["view", "change"],
}


def forward(apps, schema_editor):
    Role = apps.get_model("accounts", "Role")
    RolePermission = apps.get_model("accounts", "RolePermission")
    for slug, acts in RIGHTS.items():
        for role in Role.objects.filter(slug=slug):
            for act in acts:
                RolePermission.objects.get_or_create(role=role, resource="finances.expenses", action=act)


class Migration(migrations.Migration):
    dependencies = [("accounts", "0020_finance_code")]

    operations = [migrations.RunPython(forward, migrations.RunPython.noop)]
