"""Owner, 2026-11-02: the président changes the group's name and logo in the
app (Huddle: each group shows its own, like a Slack workspace)."""

from django.db import migrations


def forward(apps, schema_editor):
    Role = apps.get_model("accounts", "Role")
    RolePermission = apps.get_model("accounts", "RolePermission")
    for role in Role.objects.filter(slug="president"):
        RolePermission.objects.get_or_create(role=role, resource="group.profile", action="change")


class Migration(migrations.Migration):
    dependencies = [("accounts", "0023_group_profile_resource")]

    operations = [migrations.RunPython(forward, migrations.RunPython.noop)]
