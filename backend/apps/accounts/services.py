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


# --- PIN management ------------------------------------------------------------

WEAK_PINS = {"1234", "4321", "0123", "3210", "1212", "2580", "0852"}


def pin_problem(pin):
    """Return an error code for a PIN members shouldn't pick, else None."""
    if not (isinstance(pin, str) and len(pin) == 4 and pin.isdigit()):
        return "pin_format"
    if len(set(pin)) == 1 or pin in WEAK_PINS:
        return "pin_too_simple"
    return None


def temporary_pin():
    """A random PIN that passes pin_problem (so it's never 1234)."""
    import secrets

    while True:
        pin = f"{secrets.randbelow(10**4):04d}"
        if pin_problem(pin) is None:
            return pin


def reset_pin(member, *, by, request=None):
    """The secretary gives the member a new temporary PIN (forgotten PIN,
    locked account). Unlocks the account; the member must change it."""
    pin = temporary_pin()
    member.set_pin(pin, temporary=True)
    member.save(update_fields=["pin", "pin_failed_attempts", "pin_locked_until", "pin_must_change"])
    audit.record("PIN réinitialisé", actor=by, obj=member, request=request, sensitive=True)
    return pin


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


# --- Finance code ------------------------------------------------------------------
# (owner, 2026-10-30) A second 4-digit code, separate from the PIN, opens
# Finances when the group requires it (Settings.finance_code_required). Set
# and reset with the PIN; 3 misses lock it for the PIN's lockout time.

FINANCE_CODE_MAX_ATTEMPTS = 3


def set_finance_code(user, code, request=None):
    from django.contrib.auth.hashers import make_password

    user.finance_code = make_password(code)
    user.finance_code_fails = 0
    user.finance_code_locked_until = None
    user.save(update_fields=["finance_code", "finance_code_fails", "finance_code_locked_until"])
    audit.record("Code finances défini", actor=user, obj=user, request=request, sensitive=True)


def check_finance_code(user, code, request=None):
    """PinResult: ok, attempts left, lock. Counted under a row lock."""
    from django.contrib.auth.hashers import check_password

    now = timezone.now()
    with transaction.atomic():
        user = User.objects.select_for_update().get(pk=user.pk)
        if user.finance_code_locked_until and user.finance_code_locked_until > now:
            return PinResult(user, False, attempts_left=0, locked_until=user.finance_code_locked_until)
        if user.finance_code and check_password(code, user.finance_code):
            user.finance_code_fails, user.finance_code_locked_until = 0, None
            user.save(update_fields=["finance_code_fails", "finance_code_locked_until"])
            return PinResult(user, True)
        user.finance_code_fails += 1
        left = max(FINANCE_CODE_MAX_ATTEMPTS - user.finance_code_fails, 0)
        if left == 0:
            user.finance_code_fails = 0
            user.finance_code_locked_until = now + timedelta(minutes=settings.PIN_LOCKOUT_MINUTES)
        user.save(update_fields=["finance_code_fails", "finance_code_locked_until"])
    audit.record("Code finances incorrect" + (" · bloqué" if left == 0 else ""), actor=user, obj=user, request=request,
                 refused=True, detail={"essais_restants": left})
    return PinResult(user, False, attempts_left=left, locked_until=user.finance_code_locked_until)


# --- One phone at a time ---------------------------------------------------------
# (owner, 2026-10-30) An account is used on one phone: signing in on another
# phone opens a new session there, and the first phone is signed out at its
# next request. The newest phone wins, so a lost phone never locks anyone out.

SESSION_CLAIM = "sid"


def _blacklist_refresh_tokens(user):
    from rest_framework_simplejwt.token_blacklist.models import BlacklistedToken, OutstandingToken

    live = OutstandingToken.objects.filter(user=user).exclude(blacklistedtoken__isnull=False)
    BlacklistedToken.objects.bulk_create([BlacklistedToken(token=t) for t in live], ignore_conflicts=True)


def open_app_session(user, *, request=None):
    """A sign-in on a phone: the other phones' refresh tokens are revoked and
    a new session id goes into the returned token pair (the access tokens
    derived from it carry it too)."""
    import secrets

    from rest_framework_simplejwt.tokens import RefreshToken

    had_one = bool(user.app_session)
    with transaction.atomic():
        _blacklist_refresh_tokens(user)
        user.app_session = secrets.token_hex(16)
        user.app_session_at = timezone.now()
        user.save(update_fields=["app_session", "app_session_at"])
    if had_one:
        audit.record("Connexion sur un autre téléphone", actor=user, obj=user, request=request,
                     detail={"effet": "l’autre téléphone est déconnecté"})
    refresh = RefreshToken.for_user(user)
    refresh[SESSION_CLAIM] = user.app_session
    return refresh


def session_ended(user, token):
    """True when [token] belongs to a phone signed out by a newer sign-in.
    Tokens from before this rule (no session id on the account yet) stay
    valid until the member signs in again."""
    return bool(user.app_session) and token.get(SESSION_CLAIM) != user.app_session


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


def needs_end(role):
    """Every role but the open-ended ones is given for a set time."""
    return role.slug not in registry.OPEN_ENDED_ROLES


def assign_role(user, role, *, reason, by, starts_on=None, ends_on=None, request=None):
    if not reason or not reason.strip():
        raise RuleViolation("Le motif est obligatoire : il est inscrit au journal.")
    starts_on = starts_on or timezone.localdate()
    if ends_on is None:
        ends_on = default_end(role, starts_on)
    if ends_on is None and needs_end(role):
        audit.record("Refus · durée du rôle", actor=by, obj=user, request=request, refused=True, detail={"role": role.name})
        raise RuleViolation(f"Le rôle « {role.name} » n’a pas de durée : définissez-la d’abord "
                            "(Rôles et permissions → Durée). Seul le super admin garde un rôle sans fin.")
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
    if role.group_id:
        # A role in a group makes you one of its members.
        from apps.core.models import Membership

        Membership.join(user, role.group_id)
    audit.record(
        "Rôle affecté",
        actor=by,
        obj=user,
        request=request,
        sensitive=True,
        detail={"role": role.name, "debut": str(starts_on), "fin": str(ends_on) if ends_on else None, "motif": reason.strip(),
                **({"role_du_jour": True} if assignment.is_one_day else {})},
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


def set_role_duration(role, months, *, by, reason, request=None):
    """How long the role is given for, in months (owner, 2026-10-29).
    Applies to the next assignments; current ones keep their end date."""
    if not reason or not reason.strip():
        raise RuleViolation("Le motif est obligatoire : il est inscrit au journal.")
    if not needs_end(role):
        raise RuleViolation(f"Le rôle « {role.name} » est sans fin : il n’a pas de durée.")
    try:
        months = int(months)
    except (TypeError, ValueError):
        months = 0
    if not 1 <= months <= registry.ROLE_MONTHS_MAX:
        raise RuleViolation(f"La durée va de 1 à {registry.ROLE_MONTHS_MAX} mois.")
    old = role.mandate_months
    if old == months:
        return False
    role.mandate_months = months
    role.save(update_fields=["mandate_months"])
    audit.record("Durée du rôle modifiée", actor=by, obj=role, request=request, sensitive=True,
                 detail={"role": role.name, "avant": old, "apres": months, "motif": reason.strip()})
    return True


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


# --- Identity (back-office "Modifier") -----------------------------------------

IDENTITY_FIELDS = {
    "last_name": "Nom",
    "first_name": "Prénoms",
    "birth_date": "Date de naissance",
    "joined_on": "Membre depuis",
    "is_diaspora": "Diaspora",
    "city": "Ville",
    "parent_name": "Parent ou tuteur",
    "parent_relation": "Lien",
    "parent_phone": "Téléphone du parent",
}


def _age(birth, today):
    return today.year - birth.year - ((today.month, today.day) < (birth.month, birth.day))


def update_identity(member, changes, *, by, request=None):
    """Corrects a person's details (owner, 2026-10-28). `changes` holds the
    fields of IDENTITY_FIELDS, already parsed; only those that differ are
    saved and journaled, each with its old and new value. Returns the labels
    of the fields changed."""
    today = timezone.localdate()
    data = {f: getattr(member, f) for f in IDENTITY_FIELDS} | changes
    if not (data["last_name"] or "").strip() or not (data["first_name"] or "").strip():
        raise RuleViolation("Nom et prénoms sont obligatoires.")
    if data["birth_date"] and data["birth_date"] > today:
        raise RuleViolation("La date de naissance est dans le futur.")
    if data["joined_on"] and data["joined_on"] > today:
        raise RuleViolation("La date d’adhésion est dans le futur.")
    if data["birth_date"] and _age(data["birth_date"], today) < 18 and not data["parent_phone"]:
        raise RuleViolation("Le téléphone d’un parent est obligatoire pour un mineur.")
    if not data["is_diaspora"]:
        data["city"] = ""
    diff = {f: (getattr(member, f), data[f]) for f in IDENTITY_FIELDS if getattr(member, f) != data[f]}
    if not diff:
        return []
    for f, (_, new) in diff.items():
        setattr(member, f, new)
    member.save(update_fields=list(diff))

    def show(v):
        return "" if v is None else str(v)

    audit.record("Identité modifiée", actor=by, obj=member, request=request,
                 detail={IDENTITY_FIELDS[f]: {"avant": show(old), "apres": show(new)} for f, (old, new) in diff.items()})
    return [IDENTITY_FIELDS[f] for f in diff]


def change_phone(member, phone, *, by, reason, request=None):
    """The phone number is the login: it must stay unique, the change is
    journaled with its reason, and the person's phones are signed out (their
    refresh tokens are blacklisted; the 15-minute access token runs out).
    `phone` is already normalised (E.164)."""
    if not reason or not reason.strip():
        raise RuleViolation("Le motif est obligatoire : il est inscrit au journal.")
    if phone == member.phone:
        raise RuleViolation("C’est déjà le numéro de cette personne.")
    if User.objects.filter(phone=phone).exclude(pk=member.pk).exists():
        audit.record("Changement de numéro refusé", actor=by, obj=member, request=request, sensitive=True, refused=True,
                     detail={"motif": "numéro déjà utilisé"})
        raise RuleViolation("Ce numéro est déjà celui d’un autre compte.")
    old = member.phone
    with transaction.atomic():
        member.phone = phone
        member.save(update_fields=["phone"])
        _blacklist_refresh_tokens(member)
        audit.record("Numéro de téléphone modifié", actor=by, obj=member, request=request, sensitive=True,
                     detail={"avant": old, "apres": phone, "motif": reason.strip()})
