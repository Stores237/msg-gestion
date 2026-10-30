"""Expense requests (owner, 2026-10-30).

1. Any member asks (what for, amount, domain; may tag coordinators).
2. The domain's lead (its lead role, never an adjoint unless the group says
   so) or any tagged coordinator approves or refuses; the first one decides.
3. The commissaire aux comptes approves and passes it to the trésorier.
4. The trésorier pays at most the approved amount and posts the proof (a
   screenshot) in the thread; that records the Sortie in the cash book,
   counted at once (the commissaire approved the request, the trésorier
   paid: two hands).
The member may cancel before payment and ask again with the exact amount;
the cancelled request stays on record. Nobody decides on their own request.
"""

from django.db import transaction
from django.db.models import Q
from django.utils import timezone

from apps.accounts.models import RoleAssignment, User
from apps.core import audit
from apps.core.notify import notify

from .models import Entry, ExpenseDomain, ExpenseMessage, ExpenseRequest
from .services import FinanceRule

S = ExpenseRequest.Status
OPEN = (S.SUBMITTED, S.APPROVED, S.TO_PAY)


def _holders(q):
    ids = RoleAssignment.objects.active().filter(q).values("user")
    return list(User.objects.members().filter(pk__in=ids, is_active=True))


def leads(domain):
    if domain.lead_role_id is None:
        return []
    return _holders(Q(role=domain.lead_role))


def with_right(action):
    return _holders(Q(role__permissions__resource="finances.expenses", role__permissions__action=action))


def deciders(req):
    """Who may decide the first step: the domain's leads and the tagged."""
    people = {u.pk: u for u in [*leads(req.domain), *req.tagged.all()]}
    people.pop(req.requester_id, None)
    return list(people.values())


def can_see(req, user):
    return (req.requester_id == user.pk or user.can("finances.expenses", "view")
            or any(u.pk == user.pk for u in deciders(req)) or user.pk in (req.lead_by_id, req.audit_by_id, req.paid_by_id))


def visible_to(user):
    qs = ExpenseRequest.objects.select_related("domain", "requester")
    if user.can("finances.expenses", "view"):
        return qs
    lead_roles = RoleAssignment.objects.active().filter(user=user).values("role")
    return qs.filter(Q(requester=user) | Q(tagged=user) | Q(domain__lead_role__in=lead_roles) | Q(lead_by=user)).distinct()


def actions(req, user):
    """What this person may do on it now (the app shows these buttons)."""
    out = []
    if req.status == S.SUBMITTED and any(u.pk == user.pk for u in deciders(req)):
        out.append("decide")
    if (req.status == S.APPROVED and user.can("finances.expenses", "validate")
            and user.pk not in (req.requester_id, req.lead_by_id)):
        out.append("audit")
    if (req.status == S.TO_PAY and user.can("finances.expenses", "change")
            and user.pk not in (req.requester_id, req.audit_by_id)):
        out.append("pay")
    if req.status in OPEN and req.requester_id == user.pk:
        out.append("cancel")
    if req.status == S.CANCELLED and req.requester_id == user.pk and not hasattr(req, "replaced_by"):
        out.append("resubmit")
    return out


def _step(req, by, body, kind=ExpenseMessage.Kind.STEP, **file):
    return ExpenseMessage.objects.create(request=req, author=by, kind=kind, body=body, **file)


def _target(req):
    return {"type": "expense", "id": req.pk}


def _refuse(code, message, *, by, req, request):
    audit.record("Refus · demande de dépense", actor=by, obj=req, request=request, refused=True, detail={"motif": code})
    raise FinanceRule(code, message)


def submit(*, by, domain, title, amount, description="", tagged=(), replaces=None, request=None):
    if domain.is_archived:
        raise FinanceRule("domain_archived", "Ce domaine n’est plus utilisé.")
    if amount <= 0:
        raise FinanceRule("amount_required", "Indiquez le montant demandé.")
    if not (title or "").strip():
        raise FinanceRule("title_required", "Indiquez l’objet de la dépense.")
    if replaces is not None and (replaces.requester_id != by.pk or replaces.status != S.CANCELLED
                                 or hasattr(replaces, "replaced_by")):
        raise FinanceRule("bad_replaces", "Seule votre demande annulée peut être refaite, une fois.")
    tagged = [u for u in tagged if u.pk != by.pk]
    if not [u for u in [*leads(domain), *tagged] if u.pk != by.pk]:
        raise FinanceRule("no_decider", "Personne d’autre que vous ne peut approuver ce domaine : identifiez un "
                                        "coordinateur.")
    with transaction.atomic():
        req = ExpenseRequest.objects.create(requester=by, domain=domain, title=title.strip()[:140],
                                            description=(description or "").strip()[:1000], amount=amount,
                                            replaces=replaces)
        req.tagged.set(tagged)
        _step(req, by, "Demande envoyée" + (f" (remplace la demande n° {replaces.pk})" if replaces else "") + ".")
    audit.record("Demande de dépense envoyée", actor=by, obj=req, request=request,
                 detail={"montant": amount, "domaine": domain.name})
    notify(deciders(req), "payment", "Demande de dépense à approuver",
           f"{by.short_name} · {req.title} · {amount} FCFA ({domain.name}).", _target(req))
    return req


def decide(req, *, by, approve, note="", request=None):
    if req.status != S.SUBMITTED:
        raise FinanceRule("wrong_step", "Cette demande n’en est plus à cette étape.")
    if not any(u.pk == by.pk for u in deciders(req)):
        _refuse("not_decider", "Cette étape revient au responsable du domaine ou à un coordinateur identifié.",
                by=by, req=req, request=request)
    if not approve and not (note or "").strip():
        raise FinanceRule("reason_required", "Indiquez pourquoi vous refusez.")
    now = timezone.now()
    req.lead_by, req.lead_at = by, now
    if approve:
        req.status = S.APPROVED
        req.save(update_fields=["status", "lead_by", "lead_at"])
        _step(req, by, "Approuvée" + (f" : {note.strip()}" if note.strip() else "") + ". Transmise au commissaire aux comptes.")
        notify(with_right("validate"), "payment", "Demande de dépense à examiner",
               f"{req.title} · {req.amount} FCFA, approuvée par {by.short_name}.", _target(req))
    else:
        _close(req, by, S.REFUSED, note)
    notify([req.requester], "payment", "Demande approuvée par le responsable" if approve else "Demande refusée",
           f"{req.title} · {by.short_name}" + (f" : {note.strip()}" if note.strip() else ""), _target(req))
    audit.record("Demande de dépense " + ("approuvée (responsable)" if approve else "refusée"), actor=by, obj=req,
                 request=request, detail={"motif": note.strip()} if note.strip() else {})
    return req


def review(req, *, by, approve, note="", request=None):
    """The commissaire aux comptes."""
    if req.status != S.APPROVED:
        raise FinanceRule("wrong_step", "Cette demande n’en est plus à cette étape.")
    if not by.can("finances.expenses", "validate"):
        _refuse("not_auditor", "Cette étape revient au commissaire aux comptes.", by=by, req=req, request=request)
    if by.pk in (req.requester_id, req.lead_by_id):
        _refuse("own_request", "Vous avez déjà pris part à cette demande : un autre doit l’examiner.",
                by=by, req=req, request=request)
    if not approve and not (note or "").strip():
        raise FinanceRule("reason_required", "Indiquez pourquoi vous refusez.")
    req.audit_by, req.audit_at = by, timezone.now()
    if approve:
        req.status = S.TO_PAY
        req.save(update_fields=["status", "audit_by", "audit_at"])
        _step(req, by, "Approuvée par le commissaire aux comptes" + (f" : {note.strip()}" if note.strip() else "")
              + ". Transmise au trésorier pour le paiement.")
        notify(with_right("change"), "payment", "Dépense à payer",
               f"{req.title} · {req.amount} FCFA pour {req.requester.short_name}.", _target(req))
    else:
        req.save(update_fields=["audit_by", "audit_at"])
        _close(req, by, S.REFUSED, note)
    notify([req.requester, req.lead_by], "payment",
           "Demande transmise au trésorier" if approve else "Demande refusée par le commissaire",
           f"{req.title}" + (f" : {note.strip()}" if note.strip() else ""), _target(req))
    audit.record("Demande de dépense " + ("approuvée (commissaire)" if approve else "refusée (commissaire)"),
                 actor=by, obj=req, request=request, detail={"motif": note.strip()} if note.strip() else {})
    return req


def pay(req, *, by, amount, proof, content_type, note="", request=None):
    """The trésorier pays and posts the proof; the Sortie is recorded and
    counts (approved by the commissaire through the request)."""
    if req.status != S.TO_PAY:
        raise FinanceRule("wrong_step", "Cette demande n’attend pas de paiement.")
    if not by.can("finances.expenses", "change"):
        _refuse("not_treasurer", "Le paiement revient au trésorier.", by=by, req=req, request=request)
    if by.pk in (req.requester_id, req.audit_by_id):
        _refuse("own_request", "Vous avez déjà pris part à cette demande : un autre doit payer.",
                by=by, req=req, request=request)
    if not 0 < amount <= req.amount:
        raise FinanceRule("amount_over", f"Le montant payé va de 1 à {req.amount} FCFA (le montant approuvé). "
                                         "Pour plus, la demande est annulée et refaite.")
    if proof is None:
        raise FinanceRule("proof_required", "Joignez la capture de la transaction.")
    now = timezone.now()
    with transaction.atomic():
        entry = Entry.objects.create(
            direction=Entry.Direction.OUT, category=Entry.Category.EXPENSE, amount=amount,
            label=f"{req.domain.name} · {req.title}"[:160], member=req.requester, date=timezone.localdate(),
            created_by=by, status=Entry.Status.VALIDATED, validated_by=req.audit_by, validated_at=now)
        req.status, req.paid_by, req.paid_at, req.paid_amount, req.entry = S.PAID, by, now, amount, entry
        req.save(update_fields=["status", "paid_by", "paid_at", "paid_amount", "entry"])
        _step(req, by, f"Payée : {amount} FCFA." + (f" {note.strip()}" if note.strip() else ""),
              kind=ExpenseMessage.Kind.PROOF, file=proof, file_name=(proof.name or "preuve").rsplit("/", 1)[-1][:160],
              content_type=content_type)
    audit.record("Dépense payée", actor=by, obj=req, request=request, sensitive=True,
                 detail={"montant": amount, "approuve": req.amount, "operation": entry.pk})
    notify([req.requester, req.audit_by, req.lead_by], "payment", "Dépense payée",
           f"{req.title} · {amount} FCFA, payée par {by.short_name}. Preuve dans la demande.", _target(req))
    return req


def cancel(req, *, by, reason, request=None):
    if req.requester_id != by.pk:
        _refuse("not_requester", "Seul le demandeur peut annuler sa demande.", by=by, req=req, request=request)
    if req.status not in OPEN:
        raise FinanceRule("wrong_step", "Une demande payée, refusée ou annulée ne s’annule plus.")
    if not (reason or "").strip():
        raise FinanceRule("reason_required", "Indiquez pourquoi vous annulez.")
    _close(req, by, S.CANCELLED, reason)
    notify([u for u in [*deciders(req), req.lead_by, req.audit_by] if u], "payment", "Demande annulée",
           f"{req.title} · {by.short_name} : {reason.strip()}", _target(req))
    audit.record("Demande de dépense annulée", actor=by, obj=req, request=request, detail={"motif": reason.strip()})
    return req


def _close(req, by, status, reason):
    req.status, req.closed_by, req.closed_at, req.close_reason = status, by, timezone.now(), reason.strip()[:300]
    req.save(update_fields=["status", "closed_by", "closed_at", "close_reason"])
    word = "Annulée" if status == S.CANCELLED else "Refusée"
    _step(req, by, f"{word} : {reason.strip()}")


def comment(req, *, by, body, upload=None, content_type="", initial=False, request=None):
    """A message in the thread. [initial]: a file the requester joins while
    sending the request (owner, 2026-10-30: a photo or a PDF on the form);
    the request's own notice already told everyone, so no second one."""
    if not can_see(req, by):
        _refuse("not_involved", "Cette demande ne vous concerne pas.", by=by, req=req, request=request)
    if not (body or "").strip() and upload is None:
        raise FinanceRule("empty", "Écrivez un message ou joignez un fichier.")
    file = {}
    if upload is not None:
        file = {"file": upload, "file_name": (upload.name or "fichier").rsplit("/", 1)[-1][:160], "content_type": content_type}
    msg = _step(req, by, (body or "").strip()[:1000], kind=ExpenseMessage.Kind.COMMENT, **file)
    if initial and req.requester_id == by.pk and req.status == S.SUBMITTED:
        return msg
    others = [u for u in [req.requester, *req.tagged.all(), req.lead_by, req.audit_by, req.paid_by]
              if u and u.pk != by.pk]
    notify(others, "payment", "Nouveau message · demande de dépense", f"{by.short_name} · {req.title}", _target(req))
    return msg


def active_domains():
    return ExpenseDomain.objects.filter(is_archived=False).select_related("lead_role")
