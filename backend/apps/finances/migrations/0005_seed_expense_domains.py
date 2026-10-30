"""Starting expense domains for each existing group, each with the role that
approves first. Every group renames, adds or archives its own in the
back-office (Paramètres → Domaines de dépense)."""

from django.db import migrations

DOMAINS = [
    ("Formation", "formateur"),
    ("Discipline", "censeur-general"),
    ("Secrétariat", "secretaire-general"),
    ("Fonctionnement général", "president"),
]


def forward(apps, schema_editor):
    Group = apps.get_model("core", "Group")
    Role = apps.get_model("accounts", "Role")
    ExpenseDomain = apps.get_model("finances", "ExpenseDomain")
    for g in Group.objects.all():
        if ExpenseDomain.objects.filter(group=g).exists():
            continue
        for i, (name, slug) in enumerate(DOMAINS):
            role = Role.objects.filter(group=g, slug=slug).first()
            ExpenseDomain.objects.create(group=g, name=name, lead_role=role, sort_order=(i + 1) * 10)


class Migration(migrations.Migration):
    dependencies = [
        ("finances", "0004_expensedomain_expenserequest_expensemessage"),
        ("accounts", "0021_expense_rights"),
        ("core", "0014_settings_finance_code_required"),
    ]

    operations = [migrations.RunPython(forward, migrations.RunPython.noop)]
