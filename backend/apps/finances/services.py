from datetime import date

from django.db import transaction
from django.db.models import Q, Sum
from django.utils import timezone

from apps.accounts.models import User
from apps.core import audit
from apps.core.notify import notify

from .models import Collection, Due, Entry, QuarterReport


class FinanceRule(Exception):
    def __init__(self, code, message):
        super().__init__(message)
        self.code = code


def quarter_bounds(year, quarter):
    start = date(year, 3 * (quarter - 1) + 1, 1)
    end = date(year + (quarter == 4), (3 * quarter) % 12 + 1, 1)
    return start, end  # [start, end)


def balance(qs):
    agg = qs.aggregate(i=Sum("amount", filter=Q(direction="in")), o=Sum("amount", filter=Q(direction="out")))
    return (agg["i"] or 0) - (agg["o"] or 0)


def record_entry(*, by, request=None, **fields):
    """Create a cash-book line, idempotent on client_uuid (offline retries)."""
    uuid = fields.get("client_uuid")
    if uuid:
        existing = Entry.objects.filter(client_uuid=uuid).first()
        if existing:
            return existing, False
    entry = Entry.objects.create(created_by=by, **fields)
    audit.record("Opération saisie", actor=by, obj=entry, request=request,
                 detail={"sens": entry.direction, "montant": entry.amount, "categorie": entry.category})
    return entry, True


def validate_entry(entry, *, by, request=None):
    if entry.status == Entry.Status.VALIDATED:
        raise FinanceRule("already_validated", "Cette opération est déjà validée.")
    if entry.created_by_id == by.pk:
        # Separation of duties at the level of the line: nobody validates
        # what they entered, whatever their roles.
        audit.record("Refus · validation de sa propre saisie", actor=by, obj=entry, request=request, refused=True)
        raise FinanceRule("own_entry", "On ne peut pas valider sa propre saisie.")
    entry.status = Entry.Status.VALIDATED
    entry.validated_by = by
    entry.validated_at = timezone.now()
    entry.save(update_fields=["status", "validated_by", "validated_at"])
    audit.record("Opération validée", actor=by, obj=entry, request=request, detail={"montant": entry.amount})
    if entry.member_id:
        notify([entry.member], "payment", "Paiement validé", f"{entry.label} · {entry.amount} FCFA", {"type": "dues"})


def open_collection(*, by, kind, title, amount_per_member, installments=3, opened_on=None, request=None):
    """Every active or on-leave member owes the same share."""
    with transaction.atomic():
        c = Collection.objects.create(kind=kind, title=title, amount_per_member=amount_per_member, installments=installments,
                                      opened_on=opened_on or timezone.localdate(), created_by=by)
        members = User.objects.members().filter(status__in=[User.Status.ACTIVE, User.Status.LEAVE], is_active=True)
        Due.objects.bulk_create([
            Due(member=m, kind=Due.Kind.SOLIDARITY, label=title, amount=amount_per_member, collection=c, created_by=by) for m in members
        ])
    audit.record("Collecte ouverte", actor=by, obj=c, request=request, detail={"montant": amount_per_member, "membres": members.count()})
    return c


def collection_rows(c):
    """Per member: paid so far and how many thirds are covered."""
    tranches = c.tranches()
    paid = dict(
        Entry.objects.filter(collection=c).values("member").annotate(t=Sum("amount")).values_list("member", "t")
    )
    rows = []
    for due in c.dues.filter(cancelled=False).select_related("member").order_by("member__last_name", "member__first_name"):
        p = paid.get(due.member_id, 0)
        done = sum(1 for t in tranches if p >= t)
        nxt = next((t - p for t in tranches if p < t), 0)
        rows.append({"member": due.member_id, "full_name": due.member.full_name, "is_diaspora": due.member.is_diaspora,
                     "paid": p, "thirds": done, "next_amount": nxt})
    return rows


def pay_collection(c, payments, *, by, request=None):
    """payments: [{"member": id, "amount": n, "client_uuid"?}] → pending entries."""
    if not c.is_open:
        raise FinanceRule("collection_closed", "Cette collecte est clôturée.")
    dues = {d.member_id: d for d in c.dues.filter(cancelled=False)}
    created = []
    with transaction.atomic():
        for p in payments:
            due = dues.get(p["member"])
            if due is None or p["amount"] <= 0:
                continue
            entry, new = record_entry(
                by=by, request=request, direction=Entry.Direction.IN, amount=p["amount"], category=Entry.Category.SOLIDARITY,
                label=c.title, member_id=due.member_id, collection=c, due=due, date=timezone.localdate(),
                client_uuid=p.get("client_uuid"),
            )
            if new:
                created.append(entry)
    return created


def report(year, quarter):
    start, end = quarter_bounds(year, quarter)
    validated = Entry.objects.filter(status=Entry.Status.VALIDATED)
    in_q = Entry.objects.filter(date__gte=start, date__lt=end)
    in_q_validated = in_q.filter(status=Entry.Status.VALIDATED)
    by_cat = {}
    for row in in_q_validated.values("direction", "category").annotate(t=Sum("amount")):
        by_cat.setdefault(row["direction"], {})[row["category"]] = row["t"]
    opening = balance(validated.filter(date__lt=start))
    entries_in = in_q_validated.filter(direction="in").aggregate(t=Sum("amount"))["t"] or 0
    entries_out = in_q_validated.filter(direction="out").aggregate(t=Sum("amount"))["t"] or 0
    done = QuarterReport.objects.filter(year=year, quarter=quarter).select_related("validated_by").first()
    return {
        "year": year, "quarter": quarter, "start": start, "end": end,
        "opening": opening, "in": entries_in, "out": entries_out, "closing": opening + entries_in - entries_out,
        "in_by_category": by_cat.get("in", {}), "out_by_category": by_cat.get("out", {}),
        "pending": in_q.filter(status=Entry.Status.PENDING).count(),
        "validated_by": done.validated_by.short_name if done else None,
        "validated_at": done.validated_at if done else None,
    }


def validate_report(year, quarter, *, by, request=None):
    data = report(year, quarter)
    if data["pending"]:
        raise FinanceRule("pending_entries", f"{data['pending']} opération(s) restent à vérifier avant de valider.")
    rep, created = QuarterReport.objects.get_or_create(
        year=year, quarter=quarter, defaults={"validated_by": by, "closing_balance": data["closing"]}
    )
    if not created:
        raise FinanceRule("already_validated", "Ce rapport est déjà validé.")
    audit.record("Rapport trimestriel validé", actor=by, obj=rep, request=request, detail={"annee": year, "trimestre": quarter})
    return rep


# --- Members' balance statement ("bilan") -----------------------------------------------


def statement_rows(members=None):
    """Bilan général: per member, what they owe (fines, shares, registration),
    what they paid (validated, and still waiting for validation) and what is
    left to pay. Members with nothing at all are listed too, at zero."""
    if members is None:
        members = User.objects.members().exclude(status=User.Status.ARCHIVED)
    members = list(members.order_by("last_name", "first_name"))
    ids = [m.pk for m in members]
    dues = Due.objects.filter(member_id__in=ids, cancelled=False).annotate(p=Sum("entries__amount"))
    owed, left = {}, {}
    for d in dues:
        owed[d.member_id] = owed.get(d.member_id, 0) + d.amount
        left[d.member_id] = left.get(d.member_id, 0) + max(d.amount - (d.p or 0), 0)
    paid_in = Entry.objects.filter(member_id__in=ids, direction=Entry.Direction.IN)
    validated = dict(paid_in.filter(status=Entry.Status.VALIDATED).values("member").annotate(t=Sum("amount")).values_list("member", "t"))
    pending = dict(paid_in.filter(status=Entry.Status.PENDING).values("member").annotate(t=Sum("amount")).values_list("member", "t"))
    return [{
        "member": m.pk, "full_name": m.full_name, "phone": m.phone, "status": m.status,
        "owed": owed.get(m.pk, 0), "paid": validated.get(m.pk, 0), "pending": pending.get(m.pk, 0), "remaining": left.get(m.pk, 0),
    } for m in members]


def statement_totals(rows):
    return {k: sum(r[k] for r in rows) for k in ("owed", "paid", "pending", "remaining")}


def member_statement(member):
    """Bilan of one member: the totals, each debt, and every cash-book line
    in their name."""
    row = statement_rows(User.objects.filter(pk=member.pk))[0]
    dues = []
    for d in Due.objects.filter(member=member, cancelled=False).annotate(p=Sum("entries__amount")).order_by("created_at"):
        paid = d.p or 0
        dues.append({"id": d.pk, "kind": d.kind, "kind_label": d.get_kind_display(), "label": d.label, "amount": d.amount,
                     "paid": paid, "remaining": max(d.amount - paid, 0), "created_at": d.created_at})
    entries = [{
        "id": e.pk, "date": e.date, "direction": e.direction, "amount": e.amount, "category": e.category,
        "category_label": e.get_category_display(), "label": e.label, "status": e.status,
        "created_by": e.created_by.short_name, "validated_by": e.validated_by.short_name if e.validated_by else None,
    } for e in Entry.objects.filter(member=member).select_related("created_by", "validated_by").order_by("date", "created_at")]
    return {**row, "dues": dues, "entries": entries}
