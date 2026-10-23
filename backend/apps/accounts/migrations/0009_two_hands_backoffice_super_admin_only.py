"""Owner, 2026-10-23:

- Finances, two hands: the commissaire aux comptes enters (view, create,
  change, delete, export); the trésorier, who keeps the money, validates
  (view, validate, export). registry.LOCKED enforces it.
- The back-office belongs to the super admin alone: back-office permissions
  are removed from every other role (registry.BACKOFFICE_CELLS locks them).
"""

from django.db import migrations

FINANCE = {
    "finances.cashbook": ["view", "create", "change", "validate", "delete", "export"],
    "finances.solidarity": ["view", "create", "change", "validate", "delete", "export"],
    "finances.report": ["view", "validate", "export"],
}
KEEP = {
    "commissaire-aux-comptes": {"view", "create", "change", "delete", "export"},
    "tresorier": {"view", "validate", "export"},
}


def forward(apps, schema_editor):
    Role = apps.get_model("accounts", "Role")
    RolePermission = apps.get_model("accounts", "RolePermission")
    for slug, keep in KEEP.items():
        role = Role.objects.filter(slug=slug).first()
        if role is None:
            continue
        RolePermission.objects.filter(role=role, resource__in=FINANCE).exclude(action__in=keep).delete()
        for res, acts in FINANCE.items():
            for act in acts:
                if act in keep:
                    RolePermission.objects.get_or_create(role=role, resource=res, action=act)
    RolePermission.objects.filter(resource__startswith="backoffice.").exclude(role__slug="super-admin").delete()


class Migration(migrations.Migration):
    dependencies = [("accounts", "0008_super_admin_everything")]

    operations = [migrations.RunPython(forward, migrations.RunPython.noop)]
