"""Finance rights (owner, 2026-10-23): the commissaire aux comptes gets every
finance right; the trésorier keeps only view and export (registry.LOCKED now
locks the rest, so the matrix can't hand them back)."""

from django.db import migrations

FINANCE = {
    "finances.cashbook": ["view", "create", "change", "validate", "delete", "export"],
    "finances.solidarity": ["view", "create", "change", "validate", "delete", "export"],
    "finances.report": ["view", "validate", "export"],
}
READ = {"view", "export"}


def forward(apps, schema_editor):
    Role = apps.get_model("accounts", "Role")
    RolePermission = apps.get_model("accounts", "RolePermission")
    cac = Role.objects.filter(slug="commissaire-aux-comptes").first()
    if cac:
        for res, acts in FINANCE.items():
            for act in acts:
                RolePermission.objects.get_or_create(role=cac, resource=res, action=act)
    tre = Role.objects.filter(slug="tresorier").first()
    if tre:
        RolePermission.objects.filter(role=tre, resource__in=FINANCE).exclude(action__in=READ).delete()
        for res in FINANCE:
            for act in READ:
                RolePermission.objects.get_or_create(role=tre, resource=res, action=act)


class Migration(migrations.Migration):
    dependencies = [("accounts", "0006_lineup_roles")]

    operations = [migrations.RunPython(forward, migrations.RunPython.noop)]
