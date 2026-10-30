"""Owner, 2026-10-30: the trésorier and the commissaire aux comptes work
together on every operation. Both enter and both approve (each line needs
the one who didn't enter it), so both roles get the cash book and the
solidarity cells; the quarterly report is unchanged. registry.LOCKED no
longer splits them."""

from django.db import migrations

CELLS = {
    "finances.cashbook": ["view", "create", "change", "validate", "delete", "export"],
    "finances.solidarity": ["view", "create", "change", "validate", "delete", "export"],
}


def forward(apps, schema_editor):
    Role = apps.get_model("accounts", "Role")
    RolePermission = apps.get_model("accounts", "RolePermission")
    for role in Role.objects.filter(slug__in=["tresorier", "commissaire-aux-comptes"]):
        for res, acts in CELLS.items():
            for act in acts:
                RolePermission.objects.get_or_create(role=role, resource=res, action=act)


class Migration(migrations.Migration):
    dependencies = [("accounts", "0018_app_session")]

    operations = [migrations.RunPython(forward, migrations.RunPython.noop)]
