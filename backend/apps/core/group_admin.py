"""The platform's groups (back-office → Groupes): create, edit, delete."""

from datetime import timedelta

from django.core.exceptions import ValidationError
from django.db import transaction
from django.utils import timezone
from django.utils.text import slugify

from . import audit
from .models import Group, GroupDeletion, Settings


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
                                          mandate_months=role.mandate_months, sort_order=role.sort_order,
                                          daily=role.daily)
            RolePermission.objects.bulk_create([RolePermission(role=copy, resource=r, action=a) for r, a in perms])
            roles += 1
    if template is not None:
        from apps.events.models import ActivityType, DressCode

        for a in ActivityType.all_groups.filter(group=template, is_archived=False):
            ActivityType.all_groups.create(group=group, slug=a.slug, name=a.name, needs_lineup=a.needs_lineup,
                                           counts_presence=a.counts_presence, has_scope=a.has_scope,
                                           needs_chef=a.needs_chef, sort_order=a.sort_order)
        for d in DressCode.all_groups.filter(group=template, is_archived=False):
            DressCode.all_groups.create(group=group, slug=d.slug, name=d.name, description=d.description,
                                        sort_order=d.sort_order)
        from apps.finances.models import ExpenseDomain

        # Expense domains keep their lead role, by slug, in the new group.
        new_roles = {r.slug: r for r in Role.all_groups.filter(group=group)}
        for x in ExpenseDomain.all_groups.filter(group=template, is_archived=False).select_related("lead_role"):
            ExpenseDomain.all_groups.create(group=group, name=x.name, sort_order=x.sort_order,
                                            lead_role=new_roles.get(x.lead_role.slug) if x.lead_role else None)
    audit.record("Groupe créé", actor=by, obj=group, request=request, sensitive=True, platform=True,
                 detail={"nom": group.name, "roles": roles})
    return group


# --- Editing and deleting (owner, 2026-10-23) -------------------------------------------

DELETION_WINDOW = timedelta(days=3)


class GroupAdminError(Exception):
    """A refused change; the message is shown to the super admin as is."""


def update_group(group, *, by, request=None, name=None, **fields):
    """Name (on the group) and place, motto, welcome message, colour (on its
    settings), from the Groupes page. Returns what changed."""
    st = Settings.get(group)
    values = {}
    for f, value in fields.items():
        if value is None:
            continue
        field = Settings._meta.get_field(f)
        value = field.to_python(value.strip())
        try:
            field.run_validators(value)
        except ValidationError as e:
            raise GroupAdminError(f"{field.verbose_name.capitalize()} : {e.messages[0]}") from None
        values[f] = value
    # All checked: nothing is saved when one value is refused.
    changed = {}
    name = (name or "").strip()
    if name and name != group.name:
        changed["nom"] = name
        group.name = name
        group.save(update_fields=["name"])
    for f, value in values.items():
        if getattr(st, f) != value:
            changed[f] = value
            setattr(st, f, value)
    if changed:
        st.save()
        audit.record("Groupe modifié", actor=by, obj=group, request=request, platform=True, detail=changed)
    return changed


def pending_deletion(group):
    """The open request for this group, if still within the window."""
    d = group.deletions.filter(status=GroupDeletion.Status.PENDING).first()
    if d is not None and timezone.now() - d.requested_at > DELETION_WINDOW:
        d.status = GroupDeletion.Status.CANCELLED
        d.decided_at = timezone.now()
        d.save(update_fields=["status", "decided_at"])
        audit.record("Suppression de groupe expirée", obj=group, platform=True, sensitive=True)
        return None
    return d


def _check_name(group, typed):
    if (typed or "").strip() != group.name:
        raise GroupAdminError("Recopiez exactement le nom du groupe pour confirmer.")


def request_deletion(group, *, by, reason, typed_name, request=None):
    """First super admin: asks for the deletion. Nothing is deleted yet."""
    _check_name(group, typed_name)
    reason = (reason or "").strip()
    if not reason:
        raise GroupAdminError("Le motif est obligatoire.")
    if not group.is_active:
        raise GroupAdminError("Ce groupe est déjà supprimé.")
    if not Group.objects.filter(is_active=True).exclude(pk=group.pk).exists():
        raise GroupAdminError("C’est le seul groupe de la plateforme : il ne peut pas être supprimé.")
    if pending_deletion(group) is not None:
        raise GroupAdminError("Une demande de suppression est déjà en attente pour ce groupe.")
    d = GroupDeletion.objects.create(group=group, reason=reason, requested_by=by)
    audit.record("Suppression de groupe demandée", actor=by, obj=group, request=request, platform=True,
                 sensitive=True, detail={"motif": reason})
    return d


def cancel_deletion(group, *, by, request=None):
    d = pending_deletion(group)
    if d is None:
        raise GroupAdminError("Aucune demande de suppression en attente.")
    d.status = GroupDeletion.Status.CANCELLED
    d.decided_by, d.decided_at = by, timezone.now()
    d.save(update_fields=["status", "decided_by", "decided_at"])
    audit.record("Suppression de groupe annulée", actor=by, obj=group, request=request, platform=True, sensitive=True)


@transaction.atomic
def confirm_deletion(group, *, by, typed_name, request=None):
    """Second super admin: the group is hidden (members can no longer open
    it, it leaves the back-office's group list). Nothing is erased; it can
    be restored."""
    d = pending_deletion(group)
    if d is None:
        raise GroupAdminError("Aucune demande de suppression en attente : un super admin doit d’abord la demander.")
    if d.requested_by_id == by.pk:
        raise GroupAdminError("La suppression doit être confirmée par un autre super admin que celui qui l’a demandée.")
    _check_name(group, typed_name)
    now = timezone.now()
    d.status, d.decided_by, d.decided_at = GroupDeletion.Status.DONE, by, now
    d.save(update_fields=["status", "decided_by", "decided_at"])
    group.is_active, group.deleted_at, group.deleted_by = False, now, by
    group.save(update_fields=["is_active", "deleted_at", "deleted_by"])
    asked = d.requested_by
    audit.record("Groupe supprimé", actor=by, obj=group, request=request, platform=True, sensitive=True,
                 detail={"motif": d.reason, "membres": group.memberships.count(),
                         "demandé par": asked.full_name if asked else "", "confirmé par": by.full_name,
                         "données": "conservées (groupe masqué)"})
    return group.name


def last_deletion(group):
    return group.deletions.filter(status=GroupDeletion.Status.DONE).first()


def restore_group(group, *, by, request=None):
    """Brings a deleted group back as it was."""
    if group.is_active:
        raise GroupAdminError("Ce groupe n’est pas supprimé.")
    group.is_active, group.deleted_at, group.deleted_by = True, None, None
    group.save(update_fields=["is_active", "deleted_at", "deleted_by"])
    audit.record("Groupe restauré", actor=by, obj=group, request=request, platform=True, sensitive=True)
