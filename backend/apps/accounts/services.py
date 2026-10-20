from dataclasses import dataclass
from datetime import timedelta

from django.conf import settings
from django.db import transaction
from django.utils import timezone

from apps.core import audit

from . import registry
from .models import Role, RoleAssignment, RolePermission, User


class RuleViolation(Exception):
    """A fixed rule refused the change. The message is shown to the user."""


# --- PIN login ---------------------------------------------------------------


@dataclass
class PinResult:
    user: User | None
    ok: bool
    attempts_left: int | None = None
    locked_until: object = None


def check_pin_login(user, pin, request=None):
    """Check a PIN, counting failures. Locking happens on the Nth miss.

    The row is locked for the read-modify-write so two parallel guesses
    can't both read "2 attempts left".
    """
    now = timezone.now()
    with transaction.atomic():
        user = User.objects.select_for_update().get(pk=user.pk)
        if user.pin_locked(now):
            return PinResult(user, False, attempts_left=0, locked_until=user.pin_locked_until)
        if user.pin_locked_until is not None:  # a past lock has run out
            user.pin_failed_attempts = 0
            user.pin_locked_until = None
        if user.check_pin(pin):
            user.pin_failed_attempts = 0
            user.save(update_fields=["pin_failed_attempts", "pin_locked_until"])
            return PinResult(user, True)
        user.pin_failed_attempts += 1
        left = max(settings.PIN_MAX_ATTEMPTS - user.pin_failed_attempts, 0)
        if left == 0:
            user.pin_locked_until = now + timedelta(minutes=settings.PIN_LOCKOUT_MINUTES)
        user.save(update_fields=["pin_failed_attempts", "pin_locked_until"])
    if left == 0:
        audit.record("Compte bloqué (PIN)", obj=user, request=request, detail={"minutes": settings.PIN_LOCKOUT_MINUTES})
    return PinResult(user, False, attempts_left=left, locked_until=user.pin_locked_until)


# --- Role assignments ----------------------------------------------------------


def default_end(role, starts_on):
    """Bureau mandate: start + N months − 1 day (design: AssignDialog)."""
    if not role.mandate_months:
        return None
    month = starts_on.month - 1 + role.mandate_months
    year = starts_on.year + month // 12
    month = month % 12 + 1
    from calendar import monthrange

    day = min(starts_on.day, monthrange(year, month)[1])
    return starts_on.replace(year=year, month=month, day=day) - timedelta(days=1)


def assign_role(user, role, *, reason, by, starts_on=None, ends_on=None, request=None):
    if not reason or not reason.strip():
        raise RuleViolation("Le motif est obligatoire : il est inscrit au journal.")
    starts_on = starts_on or timezone.localdate()
    if ends_on is None:
        ends_on = default_end(role, starts_on)
    held = user.role_slugs(on=starts_on)
    for a, b in registry.INCOMPATIBLE_ROLES:
        if (role.slug == a and b in held) or (role.slug == b and a in held):
            other = b if role.slug == a else a
            other_name = Role.objects.filter(slug=other).values_list("name", flat=True).first() or other
            audit.record(
                "Refus · séparation des tâches",
                actor=by,
                obj=user,
                request=request,
                refused=True,
                detail={"role": role.name, "conflit": other_name},
            )
            raise RuleViolation(f"{user.short_name} est déjà {other_name} : ce rôle ne peut pas être cumulé avec {role.name}.")
    assignment = RoleAssignment.objects.create(
        user=user, role=role, starts_on=starts_on, ends_on=ends_on, reason=reason.strip(), assigned_by=by
    )
    audit.record(
        "Rôle affecté",
        actor=by,
        obj=user,
        request=request,
        sensitive=True,
        detail={"role": role.name, "debut": str(starts_on), "fin": str(ends_on) if ends_on else None, "motif": reason.strip()},
    )
    return assignment


def revoke_assignment(assignment, *, by, reason, request=None):
    if not reason or not reason.strip():
        raise RuleViolation("Le motif est obligatoire : il est inscrit au journal.")
    refused = False
    with transaction.atomic():
        if assignment.role.slug == registry.SUPER_ADMIN_SLUG:
            # Lock every active super-admin row so two admins removing each
            # other at the same moment can't both pass the count check.
            active = list(
                RoleAssignment.objects.active().filter(role__slug=registry.SUPER_ADMIN_SLUG).select_for_update()
            )
            holders = {a.user_id for a in active}
            refused = len(holders - {assignment.user_id}) < registry.MIN_SUPER_ADMINS
        if not refused:
            assignment.revoked_at = timezone.now()
            assignment.revoked_by = by
            assignment.save(update_fields=["revoked_at", "revoked_by"])
    if refused:
        # Recorded after the transaction, not inside it: an audit row
        # written in a block that then raises is rolled back with it.
        audit.record(
            "Refus · garde-fou",
            actor=by,
            obj=assignment.user,
            request=request,
            refused=True,
            detail={"role": assignment.role.name, "minimum": registry.MIN_SUPER_ADMINS},
        )
        raise RuleViolation(
            f"Il faut au moins {registry.MIN_SUPER_ADMINS} super admins en permanence. "
            "Nommez d’abord un autre super admin, puis retirez ce rôle."
        )
    audit.record(
        "Rôle retiré",
        actor=by,
        obj=assignment.user,
        request=request,
        sensitive=True,
        detail={"role": assignment.role.name, "motif": reason.strip()},
    )


# --- Permission matrix ---------------------------------------------------------


def set_role_permissions(role, changes, *, by, reason, request=None):
    """Apply {(resource, action): bool} to a role in one audited step."""
    if not reason or not reason.strip():
        raise RuleViolation("Le motif est obligatoire : il est inscrit au journal.")
    diff = []
    with transaction.atomic():
        current = set(role.permissions.values_list("resource", "action"))
        for (res, act), on in changes.items():
            if not registry.is_applicable(res, act):
                raise RuleViolation(f"Action sans objet : {res} › {act}.")
            if on and registry.is_locked(role.slug, res, act):
                raise RuleViolation("Case bloquée par la séparation des tâches.")
            if on and (res, act) not in current:
                RolePermission.objects.create(role=role, resource=res, action=act)
                diff.append([res, act, False, True])
            elif not on and (res, act) in current:
                role.permissions.filter(resource=res, action=act).delete()
                diff.append([res, act, True, False])
    if diff:
        audit.record("Permission modifiée", actor=by, obj=role, request=request, sensitive=True, detail={"diff": diff, "motif": reason.strip()})
    return diff
