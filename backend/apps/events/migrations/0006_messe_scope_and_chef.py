"""Owner, 2026-10-27:

- Messe has two kinds of service, intérieur and extérieur; "Service
  extérieur" goes (its events become Messe · Extérieur, the type is
  retired). Existing masses are intérieures.
- The chef de groupe is designated per event, not per service lineup: each
  service's chef moves onto its event.
- Every type has a chef de groupe except meetings (réunion).
"""

from django.db import migrations


def forward(apps, schema_editor):
    ActivityType = apps.get_model("events", "ActivityType")
    Event = apps.get_model("events", "Event")
    Service = apps.get_model("planning", "Service")
    Group = apps.get_model("core", "Group")

    ActivityType.objects.filter(slug="reunion").update(needs_chef=False)
    for group in Group.objects.all():
        types = ActivityType.objects.filter(group=group)
        outside = types.filter(slug="service_exterieur").first()
        messe = types.filter(slug="messe").first()
        if messe is None and outside is not None:
            messe = ActivityType.objects.create(group=group, slug="messe", name="Messe", needs_lineup=True,
                                                sort_order=outside.sort_order)
        if messe is not None:
            messe.has_scope = True
            messe.is_archived = False
            messe.save(update_fields=["has_scope", "is_archived"])
        if outside is not None:
            outside.is_archived = True
            outside.save(update_fields=["is_archived"])
    Event.objects.filter(kind="service_exterieur").update(kind="messe", scope="exterieur")
    Event.objects.filter(kind="messe", scope="").update(scope="interieur")
    for s in Service.objects.exclude(chef=None):
        Event.objects.filter(pk=s.event_id, chef=None).update(chef_id=s.chef_id)


class Migration(migrations.Migration):
    dependencies = [
        ("events", "0005_event_chef_scope_report"),
        ("planning", "0003_albrotation_owner_group_servicegroup_group_and_more"),
        ("core", "0011_notification_report"),
    ]
    operations = [migrations.RunPython(forward, migrations.RunPython.noop)]
