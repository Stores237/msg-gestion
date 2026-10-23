"""Who makes the service lineup (owner, 2026-10-23):

- the formateur, or the new formateur adjoint; on exceptional occasions the
  président or vice-président. Other roles lose create/change/validate/delete
  on calendar.planning (registry.LINEUP_ROLES now locks those cells);
- the chef de groupe is no longer a standing role: anyone can be designated
  chef for one service when the lineup is made (planning.Service.chef). The
  role is archived and its current holders' assignments end today, with an
  audit row each.
"""

from django.db import migrations
from django.utils import timezone

V, C, M, VA, D, E = "view", "create", "change", "validate", "delete", "export"
LINEUP_ROLES = {"formateur", "formateur-adjoint", "president", "vice-president"}
LINEUP_ACTIONS = [C, M, VA, D]


def forward(apps, schema_editor):
    Role = apps.get_model("accounts", "Role")
    RolePermission = apps.get_model("accounts", "RolePermission")
    RoleAssignment = apps.get_model("accounts", "RoleAssignment")
    AuditLog = apps.get_model("core", "AuditLog")

    deputy, created = Role.objects.get_or_create(
        slug="formateur-adjoint",
        defaults={"name": "Formateur adjoint", "kind": "bureau", "mandate_months": 24, "sort_order": 65},
    )
    if created:
        perms = {
            "members.profile": [V],
            "calendar.events": [V],
            "calendar.attendance": [V, M],
            "calendar.planning": [V, C, M],
            "announcements.posts": [V],
        }
        RolePermission.objects.bulk_create(
            [RolePermission(role=deputy, resource=res, action=act) for res, acts in perms.items() for act in acts]
        )

    RolePermission.objects.filter(resource="calendar.planning", action__in=LINEUP_ACTIONS).exclude(
        role__slug__in=LINEUP_ROLES
    ).delete()

    now = timezone.now()
    for a in RoleAssignment.objects.filter(role__slug="chef-de-groupe", revoked_at__isnull=True).select_related("user"):
        a.revoked_at = now
        a.save(update_fields=["revoked_at"])
        AuditLog.objects.create(
            action="Rôle retiré", object_type="accounts.roleassignment", object_id=str(a.pk),
            object_repr=f"{a.user.last_name} {a.user.first_name} · Chef de groupe"[:200], sensitive=True,
            detail={"motif": "Le chef de groupe est désormais désigné à chaque service, lors du planning."},
        )
    Role.objects.filter(slug="chef-de-groupe").update(is_archived=True)


class Migration(migrations.Migration):
    dependencies = [
        ("accounts", "0005_vice_president_sg_adjoint"),
        ("core", "0003_settings"),
    ]

    operations = [migrations.RunPython(forward, migrations.RunPython.noop)]
