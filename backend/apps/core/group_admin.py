"""Creating a group on the platform (back-office → Groupes)."""

from django.db import transaction
from django.utils.text import slugify

from . import audit
from .models import Group, Settings


def template_group():
    """New groups start from the first group's roles and permissions — the
    default set this platform was built with."""
    return Group.objects.order_by("pk").first()


@transaction.atomic
def create_group(*, name, place="", motto="", welcome_message="", by=None, request=None):
    from apps.accounts.models import Role, RolePermission

    base = slugify(name)[:44] or "groupe"
    slug, n = base, 2
    while Group.objects.filter(slug=slug).exists():
        slug, n = f"{base}-{n}", n + 1
    template = template_group()
    group = Group.objects.create(name=name.strip(), slug=slug)
    Settings.all_groups.create(group=group, parish=place.strip(), motto=motto.strip(), welcome_message=welcome_message.strip())
    roles = 0
    if template is not None:
        for role in Role.all_groups.filter(group=template, is_archived=False):
            perms = list(role.permissions.values_list("resource", "action"))
            copy = Role.all_groups.create(group=group, slug=role.slug, name=role.name, kind=role.kind,
                                          mandate_months=role.mandate_months, sort_order=role.sort_order)
            RolePermission.objects.bulk_create([RolePermission(role=copy, resource=r, action=a) for r, a in perms])
            roles += 1
    audit.record("Groupe créé", actor=by, obj=group, request=request, sensitive=True, platform=True,
                 detail={"nom": group.name, "roles": roles})
    return group
