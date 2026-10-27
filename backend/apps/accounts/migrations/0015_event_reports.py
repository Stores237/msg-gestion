"""Owner, 2026-10-27: the chef de groupe's report on an event goes to the
formateur, with the formateur adjoint, the secrétaire général, the censeur
général and the vice-censeur in copy. Those roles read reports
(calendar.reports); the vice-censeur role is new in every group, with the
censeur général's rights."""

from django.db import migrations

READERS = ["formateur", "formateur-adjoint", "secretaire-general", "censeur-general", "vice-censeur"]


def forward(apps, schema_editor):
    Role = apps.get_model("accounts", "Role")
    RolePermission = apps.get_model("accounts", "RolePermission")
    for censor in Role.objects.filter(slug="censeur-general"):
        vice, created = Role.objects.get_or_create(
            group=censor.group, slug="vice-censeur",
            defaults={"name": "Vice-censeur", "kind": "bureau", "mandate_months": censor.mandate_months,
                      "sort_order": censor.sort_order + 1, "daily": censor.daily},
        )
        if created:
            RolePermission.objects.bulk_create([RolePermission(role=vice, resource=p.resource, action=p.action)
                                                for p in RolePermission.objects.filter(role=censor)])
    for role in Role.objects.filter(slug__in=READERS, is_archived=False):
        RolePermission.objects.get_or_create(role=role, resource="calendar.reports", action="view")


class Migration(migrations.Migration):
    dependencies = [("accounts", "0014_terms_acceptance")]
    operations = [migrations.RunPython(forward, migrations.RunPython.noop)]
