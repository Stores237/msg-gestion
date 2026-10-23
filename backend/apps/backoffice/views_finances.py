"""Finances in the back-office: the members' balance statement ("bilan"),
for the super admin. The group's officers (commissaire aux comptes,
trésorier, président) download the same statements from the app."""

import csv
import io

from django.db.models import Q
from django.http import HttpResponse
from django.shortcuts import get_object_or_404, render
from django.utils import timezone

from apps.accounts.models import User
from apps.core import audit
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


@backoffice_view("finances.cashbook", "view")
def statement(request):
    q, qs = _members(request)
    rows = services.statement_rows(qs)
    only = request.GET.get("reste", "")
    if only == "1":
        rows = [r for r in rows if r["remaining"]]
    validated = Entry.objects.filter(status=Entry.Status.VALIDATED)
    return render(request, "backoffice/finances.html", {
        "nav": "finances", "rows": rows, "totals": services.statement_totals(rows), "q": q, "only": only,
        "balance": services.balance(validated), "pending": Entry.objects.filter(status=Entry.Status.PENDING).count(),
        "can_export": request.user.can("finances.cashbook", "export"),
    })


@backoffice_view("finances.cashbook", "view")
def member_statement(request, pk):
    member = get_object_or_404(User.objects.members(), pk=pk)
    return render(request, "backoffice/finance_member.html", {
        "nav": "finances", "member": member, "st": services.member_statement(member),
        "can_export": request.user.can("finances.cashbook", "export"),
    })


def _file(body, name, content_type):
    resp = HttpResponse(body, content_type=content_type)
    resp["Content-Disposition"] = f'attachment; filename="{name}"'
    return resp


@backoffice_view("finances.cashbook", "export")
def statement_pdf_view(request):
    rows = services.statement_rows()
    audit.record("Export PDF du bilan général", actor=request.user, request=request, detail={"membres": len(rows)})
    return _file(statement_pdf(rows, services.statement_totals(rows)), f"bilan-general-{timezone.localdate():%Y-%m-%d}.pdf", "application/pdf")


@backoffice_view("finances.cashbook", "export")
def statement_csv(request):
    rows = services.statement_rows()
    buf = io.StringIO()
    w = csv.writer(buf, delimiter=";")
    w.writerow(["Nom", "Téléphone", "Statut", "Dû (FCFA)", "Versé validé (FCFA)", "À valider (FCFA)", "Reste à payer (FCFA)"])
    status = dict(User.Status.choices)
    for r in rows:
        w.writerow([r["full_name"], r["phone"], status.get(r["status"], r["status"]), r["owed"], r["paid"], r["pending"], r["remaining"]])
    t = services.statement_totals(rows)
    w.writerow(["Total", "", "", t["owed"], t["paid"], t["pending"], t["remaining"]])
    audit.record("Export CSV du bilan général", actor=request.user, request=request, detail={"membres": len(rows)})
    return _file("﻿" + buf.getvalue(), f"bilan-general-{timezone.localdate():%Y-%m-%d}.csv", "text/csv; charset=utf-8")


@backoffice_view("finances.cashbook", "export")
def member_statement_pdf_view(request, pk):
    member = get_object_or_404(User.objects.members(), pk=pk)
    audit.record("Export PDF du bilan individuel", actor=request.user, obj=member, request=request)
    slug = f"{member.last_name}-{member.first_name}".lower().replace(" ", "-")
    return _file(member_statement_pdf(services.member_statement(member)), f"bilan-{slug}-{timezone.localdate():%Y-%m-%d}.pdf", "application/pdf")
