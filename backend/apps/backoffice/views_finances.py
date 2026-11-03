"""Finances in the back-office: the members' balance statement ("bilan"),
for the super admin. The group's officers (commissaire aux comptes,
trésorier, président) download the same statements from the app."""

import csv
import io

from django.contrib import messages
from django.db.models import Q
from django.http import HttpResponse
from django.shortcuts import get_object_or_404, render
from django.utils import timezone

from apps.accounts.models import User
from apps.core import audit
from apps.core.models import Settings
from apps.finances import services
from apps.finances.models import Entry
from apps.finances.pdf import member_statement_pdf, statement_pdf

from .access import backoffice_view


def _members(request):
    q = request.GET.get("q", "").strip()
    qs = User.objects.members().exclude(gstatus=User.Status.ARCHIVED)
    if q:
        qs = qs.filter(Q(last_name__icontains=q) | Q(first_name__icontains=q) | Q(phone__icontains=q.replace(" ", "")))
    return q, qs


def _period(request):
    """The period chosen in the page (GET from/to), its quick choices and the
    query string the export links carry. Wrong dates: the whole history, said."""
    from datetime import date, timedelta

    try:
        period = services.parse_period(request.GET)
    except services.FinanceRule as e:
        messages.error(request, str(e))
        period = services.Period()
    today = timezone.localdate()
    first = today.replace(day=1)
    last_end = first - timedelta(days=1)
    quick = [("Tout", "", ""),
             ("Ce mois", f"{first:%Y-%m-%d}", f"{today:%Y-%m-%d}"),
             ("Mois dernier", f"{last_end.replace(day=1):%Y-%m-%d}", f"{last_end:%Y-%m-%d}"),
             ("Cette année", f"{date(today.year, 1, 1):%Y-%m-%d}", f"{today:%Y-%m-%d}")]
    pq = "&".join(f"{k}={d:%Y-%m-%d}" for k, d in (("from", period.start), ("to", period.end)) if d)
    return period, {"period": period, "quick": quick, "pq": f"?{pq}" if pq else ""}


@backoffice_view("finances.cashbook", "view")
def statement(request):
    q, qs = _members(request)
    period, ctx = _period(request)
    rows = services.statement_rows(qs, period)
    only = request.GET.get("reste", "")
    if only == "1":
        rows = [r for r in rows if r["remaining"]]
    validated = Entry.objects.filter(status=Entry.Status.VALIDATED)
    return render(request, "backoffice/finances.html", {
        "nav": "finances", "rows": rows, "totals": services.statement_totals(rows), "q": q, "only": only,
        "balance": services.balance(validated), "pending": Entry.objects.filter(status=Entry.Status.PENDING).count(),
        "can_export": request.user.can("finances.cashbook", "export"),
        "keep": [(k, v) for k, v in (("q", q), ("reste", only)) if v], **ctx,
    })


@backoffice_view("finances.cashbook", "view")
def member_statement(request, pk):
    member = get_object_or_404(User.objects.members(), pk=pk)
    period, ctx = _period(request)
    return render(request, "backoffice/finance_member.html", {
        "nav": "finances", "member": member, "st": services.member_statement(member, period),
        "can_export": request.user.can("finances.cashbook", "export"), "keep": [], **ctx,
    })


def _file(body, name, content_type):
    resp = HttpResponse(body, content_type=content_type)
    resp["Content-Disposition"] = f'attachment; filename="{name}"'
    return resp


def _name(base, period):
    return f"{base}-{period.slug or timezone.localdate().strftime('%Y-%m-%d')}"


def _detail(period, **kw):
    return {**kw, **({"periode": period.label} if period else {})}


@backoffice_view("finances.cashbook", "export")
def statement_pdf_view(request):
    period, _ = _period(request)
    rows = services.statement_rows(period=period)
    audit.record("Export PDF du bilan général", actor=request.user, request=request, detail=_detail(period, membres=len(rows)))
    return _file(statement_pdf(rows, services.statement_totals(rows), period.label), _name("bilan-general", period) + ".pdf",
                 "application/pdf")


@backoffice_view("finances.cashbook", "export")
def cashbook_pdf_view(request):
    from apps.finances.pdf import cashbook_pdf

    period, _ = _period(request)
    lines, opening, closing = services.cashbook(period)
    audit.record("Export PDF du livre de caisse", actor=request.user, request=request, detail=_detail(period, lignes=len(lines)))
    pdf = cashbook_pdf(lines, period.label, opening if period else None, closing if period else None)
    return _file(pdf, _name("livre-de-caisse", period) + ".pdf", "application/pdf")


@backoffice_view("finances.cashbook", "export")
def statement_csv(request):
    period, _ = _period(request)
    rows = services.statement_rows(period=period)
    buf = io.StringIO()
    w = csv.writer(buf, delimiter=";")
    c = Settings.get().currency
    w.writerow(["Nom", "Téléphone", "Statut", f"Dû ({c})", f"Versé validé ({c})", f"À valider ({c})", f"Reste à payer ({c})"])
    status = dict(User.Status.choices)
    for r in rows:
        w.writerow([r["full_name"], r["phone"], status.get(r["status"], r["status"]), r["owed"], r["paid"], r["pending"], r["remaining"]])
    t = services.statement_totals(rows)
    w.writerow(["Total", "", "", t["owed"], t["paid"], t["pending"], t["remaining"]])
    if period:
        w.writerow([f"Période : {period.label}"])
    audit.record("Export CSV du bilan général", actor=request.user, request=request, detail=_detail(period, membres=len(rows)))
    return _file("﻿" + buf.getvalue(), _name("bilan-general", period) + ".csv", "text/csv; charset=utf-8")


@backoffice_view("finances.cashbook", "export")
def member_statement_pdf_view(request, pk):
    member = get_object_or_404(User.objects.members(), pk=pk)
    period, _ = _period(request)
    audit.record("Export PDF du bilan individuel", actor=request.user, obj=member, request=request, detail=_detail(period) or None)
    slug = f"{member.last_name}-{member.first_name}".lower().replace(" ", "-")
    return _file(member_statement_pdf(services.member_statement(member, period)), _name(f"bilan-{slug}", period) + ".pdf",
                 "application/pdf")


# --- Expense requests (owner, 2026-10-30): the super admin sees them all,
# with their thread and the trésorier's proof, read only. ---


@backoffice_view("finances.expenses", "view")
def expenses(request):
    from apps.finances.models import ExpenseRequest

    st = request.GET.get("statut", "")
    qs = ExpenseRequest.objects.select_related("domain", "requester", "lead_by", "audit_by", "paid_by")
    if st in ExpenseRequest.Status.values:
        qs = qs.filter(status=st)
    counts = {s: ExpenseRequest.objects.filter(status=s).count() for s in ExpenseRequest.Status.values}
    return render(request, "backoffice/expenses.html", {
        "nav": "finances", "items": qs[:300], "statut": st, "statuses": ExpenseRequest.Status.choices, "counts": counts,
    })


@backoffice_view("finances.expenses", "view")
def expense(request, pk):
    from apps.finances.models import ExpenseRequest

    r = get_object_or_404(ExpenseRequest.objects.select_related("domain", "requester", "lead_by", "audit_by", "paid_by"),
                          pk=pk)
    return render(request, "backoffice/expense.html", {"nav": "finances", "r": r, "messages_": r.messages.select_related("author")})
