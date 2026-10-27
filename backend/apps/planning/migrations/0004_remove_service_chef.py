from django.db import migrations


class Migration(migrations.Migration):
    """The chef de groupe now lives on the event (events.0006 copied it)."""

    dependencies = [
        ("planning", "0003_albrotation_owner_group_servicegroup_group_and_more"),
        ("events", "0006_messe_scope_and_chef"),
    ]

    operations = [migrations.RemoveField(model_name="service", name="chef")]
