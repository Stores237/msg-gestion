"""Two bureau roles the owner asked for (2026-10-23): vice-président and
secrétaire général adjoint ("Secrétaire général(e) et adjoint" in the
design's role table). Same create-if-missing rule as 0002: an admin's later
edits are never overwritten."""

from django.db import migrations

V, C, M, VA, D, E = "view", "create", "change", "validate", "delete", "export"

ROLES = [
    # Président's rights, except validating the quarterly report.
    ("vice-president", "Vice-président", 15, {
        "members.profile": [V, C, M, D, E],
        "members.minor_contacts": [V, M, E],
        "finances.cashbook": [V, E],
        "finances.solidarity": [V, E],
        "finances.report": [V, E],
        "calendar.events": [V, C, M, D, E],
        "calendar.attendance": [V, M, E],
        "calendar.planning": [V, C, M, VA, D, E],
        "announcements.posts": [V, C, M, D],
    }),
    # Same rights as the secrétaire général.
    ("secretaire-general-adjoint", "Secrétaire général adjoint", 25, {
        "members.profile": [V, C, M, E],
        "members.minor_contacts": [V, M],
        "calendar.events": [V, C, M, D],
        "calendar.attendance": [V],
        "calendar.planning": [V, C, M],
        "announcements.posts": [V, C, M, D],
    }),
]


def seed(apps, schema_editor):
    Role = apps.get_model("accounts", "Role")
    RolePermission = apps.get_model("accounts", "RolePermission")
    for slug, name, order, perms in ROLES:
        role, created = Role.objects.get_or_create(
            slug=slug, defaults={"name": name, "kind": "bureau", "mandate_months": 24, "sort_order": order}
        )
        if created:
            RolePermission.objects.bulk_create(
                [RolePermission(role=role, resource=res, action=act) for res, acts in perms.items() for act in acts]
            )


class Migration(migrations.Migration):
    dependencies = [("accounts", "0004_user_remind_2h_user_remind_eve_rolerequest")]

    operations = [migrations.RunPython(seed, migrations.RunPython.noop)]
