"""Money between the levels of a network (owner, 2026-11-03).

A group's finance team (finances.cashbook create) asks the groups attached
directly below it for a contribution ("quote-part"): a title, an amount, a
date. Each of those groups' finance team pays it from Finances → Réseau,
which records:

- in the payer's cash book, a money-out line "Quote-part … · Zone Nord";
- in the asker's cash book, a money-in line "Quote-part … · GS Yapoma".

Both lines are pending and approved by each group's own finance team, the
usual way (the other hand agrees). The contribution counts as received once
the asker's line is validated. The asker never touches the payer's money.
"""

from datetime import date

from django.db import transaction
from django.utils import timezone

from apps.core import audit
from apps.core.groups import in_group
from apps.core.notify import notify

from .models import Entry, NetworkDue
from .services import FinanceRule, approvers, cur


def finance_team(group):
    from apps.accounts.models import RoleAssignment, User

    with in_group(group):
        ids = RoleAssignment.objects.active().filter(
            role__group=group, role__permissions__resource="finances.cashbook", role__permissions__action="create"
        ).values("user")
        return list(User.objects.members().filter(pk__in=ids, is_active=True))


def _tell(group, people, title, body):
    with in_group(group):
        notify(people, "payment", title, body, {"type": "network_dues"})


def _money(n, group):
    with in_group(group):
        return f"{n:,} {cur()}".replace(",", " ")


@transaction.atomic
def ask(umbrella, *, title, amount, due_on=None, groups=None, by, request=None):
    title = (title or "").strip()[:120]
    if len(title) < 3:
        raise FinanceRule("title_required", "Donnez un intitulé (ex. Quote-part 2027).")
    try:
        amount = int(amount)
    except (TypeError, ValueError):
        raise FinanceRule("bad_amount", "Montant invalide.") from None
    if amount <= 0:
        raise FinanceRule("bad_amount", "Montant invalide.")
    kids = list(umbrella.children.filter(is_active=True).order_by("name"))
    if groups:
        wanted = {int(g) for g in groups}
        kids = [k for k in kids if k.pk in wanted]
        if len(kids) != len(wanted):
            raise FinanceRule("not_below", "Un des groupes n’est pas rattaché au vôtre.")
    if not kids:
        raise FinanceRule("no_groups_below", "Aucun groupe n’est rattaché au vôtre.")
    dues = [NetworkDue.objects.create(umbrella=umbrella, group=g, title=title, amount=amount, due_on=due_on, created_by=by)
            for g in kids]
    audit.record("Quote-part demandée", actor=by, obj=umbrella, request=request,
                 detail={"intitulé": title, "montant": amount, "groupes": [g.name for g in kids]})
    when = f" avant le {due_on:%d/%m/%Y}" if due_on else ""
    for d in dues:
        _tell(d.group, finance_team(d.group), f"Quote-part demandée par {umbrella.name}",
              f"{title} · {_money(amount, umbrella)}{when}. Réglez-la dans Finances → Réseau.")
    return dues


@transaction.atomic
def pay(due, *, by, on=None, request=None):
    """Called in the payer's group."""
    due = NetworkDue.objects.select_for_update().select_related("umbrella", "group").get(pk=due.pk)
    if due.cancelled:
        raise FinanceRule("due_cancelled", "Cette quote-part a été annulée.")
    if due.received_entry_id is not None:
        raise FinanceRule("due_paid", "Cette quote-part est déjà réglée.")
    on = on or timezone.localdate()
    if on > timezone.localdate():
        raise FinanceRule("date_future", "La date ne peut pas être dans le futur.")
    with in_group(due.group):
        out = Entry.objects.create(group=due.group, direction=Entry.Direction.OUT, amount=due.amount,
                                   category=Entry.Category.NETWORK, label=f"{due.title} · {due.umbrella.name}"[:160],
                                   date=on, created_by=by)
        audit.record("Quote-part réglée", actor=by, obj=out, request=request,
                     detail={"à": due.umbrella.name, "montant": due.amount, "intitulé": due.title})
        notify(approvers(exclude=by), "payment", "Opération à approuver",
               f"{out.label} · {due.amount} {cur()}, saisie par {by.short_name}.", {"type": "cashbook"})
    with in_group(due.umbrella):
        inn = Entry.objects.create(group=due.umbrella, direction=Entry.Direction.IN, amount=due.amount,
                                   category=Entry.Category.NETWORK, label=f"{due.title} · {due.group.name}"[:160],
                                   date=on, created_by=by)
        audit.record("Quote-part reçue (à valider)", actor=by, obj=inn, request=request,
                     detail={"de": due.group.name, "montant": due.amount, "intitulé": due.title})
        notify(approvers(), "payment", "Quote-part à confirmer",
               f"{due.group.name} a réglé « {due.title} » · {due.amount} {cur()}. Validez-la dans le livre de caisse.",
               {"type": "cashbook"})
    due.paid_entry, due.received_entry, due.paid_by, due.paid_at = out, inn, by, timezone.now()
    due.save(update_fields=["paid_entry", "received_entry", "paid_by", "paid_at"])
    return due


@transaction.atomic
def cancel(due, *, by, reason, request=None):
    reason = (reason or "").strip()[:300]
    if len(reason) < 3:
        raise FinanceRule("reason_required", "Indiquez le motif.")
    if due.received_entry_id is not None:
        raise FinanceRule("due_paid", "Déjà réglée : elle ne peut plus être annulée.")
    due.cancelled, due.cancel_reason = True, reason
    due.save(update_fields=["cancelled", "cancel_reason"])
    audit.record("Quote-part annulée", actor=by, obj=due.umbrella, request=request,
                 detail={"groupe": due.group.name, "intitulé": due.title, "motif": reason})
    _tell(due.group, finance_team(due.group), "Quote-part annulée",
          f"{due.umbrella.name} a annulé « {due.title} ». Motif : {reason}")


def row(due, request=None, *, side):
    from apps.core.identity import group_identity

    other = due.umbrella if side == "owed" else due.group
    return {"id": due.pk, "title": due.title, "amount": due.amount, "currency": _currency(due.umbrella),
            "due_on": due.due_on.isoformat() if due.due_on else None, "status": due.status,
            "group": group_identity(other, request), "paid_at": due.paid_at.isoformat() if due.paid_at else None,
            "late": bool(due.due_on and due.due_on < date.today() and due.status == NetworkDue.Status.OPEN),
            "cancel_reason": due.cancel_reason}


def _currency(group):
    with in_group(group):
        return cur()
