"""
Starting configuration of roles and permissions (design: "Navigation par
rôle" table). After this runs, the super admin owns these rows and edits
them in the back-office; this migration only ever creates what's missing,
so re-running it (or a later migrate) never undoes an admin's edit.
"""

from django.db import migrations

V, C, M, VA, D, E = "view", "create", "change", "validate", "delete", "export"

ROLES = [
    # slug, name, kind, mandate_months, {resource: [actions]}
    ("super-admin", "Super admin", "systeme", None, {
        "members.profile": [V],
        "backoffice.users": [V, C, M, D, E],
        "backoffice.audit": [V, E],
    }),
    ("president", "Président", "bureau", 24, {
        "members.profile": [V, C, M, D, E],
        "members.minor_contacts": [V, M, E],
        "finances.cashbook": [V, E],
        "finances.solidarity": [V, E],
        "finances.report": [V, VA, E],
        "calendar.events": [V, C, M, D, E],
        "calendar.attendance": [V, M, E],
        "calendar.planning": [V, C, M, VA, D, E],
        "announcements.posts": [V, C, M, D],
    }),
    ("secretaire-general", "Secrétaire général", "bureau", 24, {
        "members.profile": [V, C, M, E],
        "members.minor_contacts": [V, M],
        "calendar.events": [V, C, M, D],
        "calendar.attendance": [V],
        "calendar.planning": [V, C, M],
        "announcements.posts": [V, C, M, D],
    }),
    ("tresorier", "Trésorier", "bureau", 24, {
        "members.profile": [V],
        "finances.cashbook": [V, C, M, E],
        "finances.solidarity": [V, C, M, E],
        "finances.report": [V, E],
        "calendar.events": [V],
        "calendar.planning": [V],
        "announcements.posts": [V],
    }),
    ("commissaire-aux-comptes", "Commissaire aux comptes", "bureau", 24, {
        "members.profile": [V],
        "finances.cashbook": [V, VA, E],
        "finances.solidarity": [V, VA, E],
        "finances.report": [V, VA, E],
        "calendar.events": [V],
        "announcements.posts": [V],
    }),
    ("censeur-general", "Censeur général", "bureau", 24, {
        "members.profile": [V],
        "calendar.events": [V],
        "calendar.attendance": [V, M],
        "calendar.planning": [V, C, M],
        "announcements.posts": [V],
    }),
    ("formateur", "Formateur", "bureau", 24, {
        "members.profile": [V],
        "calendar.events": [V],
        "calendar.attendance": [V, M],
        "calendar.planning": [V, C, M],
        "announcements.posts": [V],
    }),
    ("conseiller", "Conseiller", "bureau", 24, {
        "members.profile": [V],
        "calendar.events": [V],
        "calendar.attendance": [V],
        "announcements.posts": [V],
    }),
    ("chef-de-groupe", "Chef de groupe", "standard", None, {
        "calendar.events": [V],
        "calendar.planning": [V, M],
        "announcements.posts": [V],
    }),
    ("censeur-du-jour", "Censeur du jour", "temporaire", None, {
        "calendar.events": [V],
        "calendar.attendance": [V, M],
        "announcements.posts": [V],
    }),
    ("membre", "Membre", "standard", None, {
        "calendar.events": [V],
        "announcements.posts": [V],
    }),
]


def seed(apps, schema_editor):
    Role = apps.get_model("accounts", "Role")
    RolePermission = apps.get_model("accounts", "RolePermission")
    for order, (slug, name, kind, months, perms) in enumerate(ROLES):
        role, created = Role.objects.get_or_create(
            slug=slug, defaults={"name": name, "kind": kind, "mandate_months": months, "sort_order": order * 10}
        )
        if not created:
            continue
        RolePermission.objects.bulk_create(
            [RolePermission(role=role, resource=res, action=act) for res, acts in perms.items() for act in acts]
        )


class Migration(migrations.Migration):
    dependencies = [("accounts", "0001_initial")]

    operations = [migrations.RunPython(seed, migrations.RunPython.noop)]
