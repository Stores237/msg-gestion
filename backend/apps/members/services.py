"""Access requests: from the group leader in the app to the partner in the
back-office, and back (see models.AccessRequest)."""

from datetime import timedelta

from django.db import transaction
from django.utils import timezone

from apps.accounts.models import Role, User
from apps.accounts.services import RuleViolation, assign_role, temporary_pin
from apps.core import audit
from apps.core.models import Membership, Settings
from apps.core.notify import notify
from apps.finances.models import Due, Entry
from apps.finances.services import record_entry

from .models import AccessRequest

# A temporary PIN not collected by then is dropped; the partner resets it.
PIN_KEPT_FOR = timedelta(days=7)


def submit(*, by, request=None, **fields):
    req = AccessRequest.objects.create(requested_by=by, **fields)
    audit.record("Demande d’accès envoyée", actor=by, obj=req, request=request,
                 detail={"role": req.role.name, "telephone": req.phone})
    return req


@transaction.atomic
def approve(req, *, by, request=None):
    """Create the account (or add an existing one to the group), give the
    role, and keep a temporary PIN for the leader when the account is new."""
    if req.status != AccessRequest.Status.PENDING:
        raise RuleViolation("Cette demande a déjà été traitée.")
    user = User.objects.filter(phone=req.phone).first()
    pin = ""
    if user is None:
        user = User(phone=req.phone, last_name=req.last_name, first_name=req.first_name, birth_date=req.birth_date,
                    is_diaspora=req.is_diaspora, city=req.city, parent_name=req.parent_name,
                    parent_relation=req.parent_relation, parent_phone=req.parent_phone)
        user.set_unusable_password()  # the app only; the back-office is the super admin's
        pin = temporary_pin()
        user.set_pin(pin, temporary=True)
        user.save()
    elif user.is_platform_account:
        raise RuleViolation("Ce numéro est celui d’un compte du back-office (super admin ou équipe) : "
                            "il ne peut pas être membre d’un groupe.")
    Membership.join(user, req.group_id)
    reason = f"Demande d’accès de {req.requested_by.short_name if req.requested_by else 'un responsable'}"
    held = user.role_slugs()
    for role in {Role.objects.get(slug="membre"), req.role}:
        if role.slug not in held:
            assign_role(user, role, reason=reason, by=by, request=request)
    fee = Settings.get().fee_registration
    if fee and not Due.objects.filter(member=user, kind=Due.Kind.REGISTRATION).exists():
        due = Due.objects.create(member=user, kind=Due.Kind.REGISTRATION, label="Inscription", amount=fee, created_by=by)
        if req.registration_paid and req.requested_by:
            # Paid to the leader: into the cash book, for the trésorier to validate.
            record_entry(by=req.requested_by, request=request, direction=Entry.Direction.IN, amount=fee,
                         category=Entry.Category.REGISTRATION, label=f"Inscription · {user.full_name}", member=user,
                         due=due, date=timezone.localdate())
    req.status, req.decided_by, req.decided_at, req.user, req.temp_pin = AccessRequest.Status.APPROVED, by, timezone.now(), user, pin
    req.save()
    audit.record("Accès créé", actor=by, obj=user, request=request, sensitive=True,
                 detail={"role": req.role.name, "nouveau_compte": bool(pin)})
    if req.requested_by:
        body = ("Le code provisoire est à récupérer dans l’application, puis à lui remettre." if pin
                else "Ce numéro a déjà un compte : il se connecte avec son code habituel.")
        notify([req.requested_by], "member", f"Accès créé pour {user.full_name}", body, {"type": "access_request", "id": req.pk})
    return req


def refuse(req, *, by, reason, request=None):
    if req.status != AccessRequest.Status.PENDING:
        raise RuleViolation("Cette demande a déjà été traitée.")
    if not reason.strip():
        raise RuleViolation("Le motif est obligatoire : il est transmis au responsable.")
    req.status, req.decided_by, req.decided_at, req.decision_note = AccessRequest.Status.REFUSED, by, timezone.now(), reason.strip()
    req.save()
    audit.record("Demande d’accès refusée", actor=by, obj=req, request=request, detail={"motif": reason.strip()})
    if req.requested_by:
        notify([req.requested_by], "member", f"Demande refusée : {req.full_name}", reason.strip(), {"type": "access_request", "id": req.pk})
    return req


def pin_available(req):
    return bool(req.temp_pin) and req.decided_at is not None and timezone.now() - req.decided_at < PIN_KEPT_FOR


@transaction.atomic
def reveal(req, *, by, request=None):
    """The leader sees the temporary PIN once; then it is erased."""
    req = AccessRequest.objects.select_for_update().get(pk=req.pk)
    if not pin_available(req):
        return None
    pin = req.temp_pin
    req.temp_pin, req.pin_revealed_at = "", timezone.now()
    req.save(update_fields=["temp_pin", "pin_revealed_at"])
    audit.record("Code provisoire remis au responsable", actor=by, obj=req.user, request=request, sensitive=True)
    return pin
