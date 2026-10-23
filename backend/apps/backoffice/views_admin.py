"""Back-office pages beyond the first four: account security, user detail
and its actions, new user, import, assignments, settings, role requests,
role management, bulk actions and CSV exports. Every change goes through
the same services as the API (rules + audit log)."""

import csv
import io
import secrets
import string
from datetime import date, timedelta

from django.contrib import messages
from django.contrib.sessions.models import Session
from django.core.cache import cache
from django.db import transaction
from django.db.models import F, Q
from django.http import HttpResponse
from django.shortcuts import get_object_or_404, redirect, render
from django.utils import timezone
from django.utils.dateparse import parse_date
from django.views.decorators.http import require_POST

from apps.accounts import registry
from apps.accounts.models import Role, RoleAssignment, RolePermission, RoleRequest, User
from apps.accounts.phone import InvalidPhone, format_phone, normalize_phone
from apps.accounts.services import RuleViolation, assign_role, default_end, reset_pin, revoke_assignment, temporary_pin
from apps.core import audit
from apps.core.models import AuditLog, Membership, Settings
from apps.core.notify import notify
from apps.planning.models import ServiceGroup

from .access import backoffice_view
from .models import BackofficeSession, BackupCode


def _deny(request):
    return render(request, "backoffice/forbidden.html", status=403)


# --- Account security ------------------------------------------------------------


@backoffice_view("backoffice.users", "view")
def security(request):
    """"Sécurité du compte" (design: BSessions): sessions, 2FA, backup codes."""
    me = request.user
    new_codes = None
    if request.method == "POST":
        action = request.POST.get("action")
        if action == "close":
            row = BackofficeSession.objects.filter(user=me, pk=request.POST.get("id")).exclude(session_key=request.session.session_key).first()
            if row:
                Session.objects.filter(session_key=row.session_key).delete()
                row.delete()
                audit.record("Session fermée", actor=me, obj=me, request=request, detail={"appareil": row.device[:60]})
                messages.success(request, "Session fermée.")
        elif action == "close_others":
            others = BackofficeSession.objects.filter(user=me).exclude(session_key=request.session.session_key)
            n = others.count()
            Session.objects.filter(session_key__in=others.values_list("session_key", flat=True)).delete()
            others.delete()
            audit.record("Autres sessions fermées", actor=me, obj=me, request=request, detail={"sessions": n})
            messages.success(request, f"{n} autre(s) session(s) fermée(s).")
        elif action == "codes":
            new_codes = BackupCode.regenerate(me)
            audit.record("Codes de secours régénérés", actor=me, obj=me, request=request, sensitive=True)
        if new_codes is None:
            return redirect("backoffice:security")
    sessions = BackofficeSession.objects.filter(user=me)
    return render(request, "backoffice/security.html", {
        "nav": "", "sessions": sessions, "current": request.session.session_key,
        "codes_left": BackupCode.remaining(me), "codes_total": BackupCode.COUNT, "new_codes": new_codes,
        "phone": format_phone(me.phone),
    })


# --- Users ---------------------------------------------------------------------------


def _random_password():
    alphabet = string.ascii_letters + string.digits
    return "".join(secrets.choice(alphabet) for _ in range(14))


def _active_roles(user):
    today = timezone.localdate()
    return [a for a in user.assignments.all() if a.revoked_at is None and a.starts_on <= today and (a.ends_on is None or a.ends_on >= today)]


@backoffice_view("backoffice.users", "view")
def user_detail(request, pk):
    member = get_object_or_404(User, pk=pk)
    once = None  # secrets shown once after an action
    if request.method == "POST":
        if not request.user.can("backoffice.users", "change"):
            return _deny(request)
        action = request.POST.get("action")
        reason = (request.POST.get("reason") or "").strip()
        try:
            if action == "assign":
                role = get_object_or_404(Role, slug=request.POST.get("role"), is_archived=False)
                start = parse_date(request.POST.get("starts_on") or "") or timezone.localdate()
                if request.POST.get("one_day"):
                    _assign_for_the_day(member, role, start, reason=reason, by=request.user, request=request)
                    messages.success(request, f"{member.short_name} est {role.name} le {start:%d/%m/%Y} (rôle du jour).")
                else:
                    end = parse_date(request.POST.get("ends_on") or "") if request.POST.get("ends_on") else None
                    assign_role(member, role, reason=reason, by=request.user, starts_on=start, ends_on=end, request=request)
                    messages.success(request, f"Rôle « {role.name} » affecté.")
            elif action == "revoke":
                a = get_object_or_404(RoleAssignment, pk=request.POST.get("assignment"), user=member, revoked_at__isnull=True)
                revoke_assignment(a, by=request.user, reason=reason, request=request)
                messages.success(request, f"Rôle « {a.role.name} » retiré.")
            elif action == "reset_pin":
                once = {"label": "Nouveau code PIN provisoire", "value": reset_pin(member, by=request.user, request=request)}
            elif action in ("suspend", "reactivate"):
                if not reason:
                    raise RuleViolation("Le motif est obligatoire : il est inscrit au journal.")
                member.status = User.Status.SUSPENDED if action == "suspend" else User.Status.ACTIVE
                member.save(update_fields=["status"])
                audit.record("Utilisateur suspendu" if action == "suspend" else "Utilisateur réactivé", actor=request.user, obj=member,
                             request=request, sensitive=True, detail={"motif": reason})
                messages.success(request, "Statut mis à jour.")
            elif action == "password":
                if not member.is_super_admin:
                    raise RuleViolation("Le back-office est réservé aux super admins : affectez d’abord le rôle Super admin.")
                pw = _random_password()
                member.set_password(pw)
                member.save(update_fields=["password"])
                audit.record("Mot de passe back-office défini", actor=request.user, obj=member, request=request, sensitive=True)
                codes = BackupCode.regenerate(member)
                once = {"label": "Mot de passe provisoire et codes de secours", "value": pw, "codes": codes}
            elif action == "groups":
                ids = [int(x) for x in request.POST.getlist("groups")]
                for g in ServiceGroup.objects.all():
                    (g.members.add if g.pk in ids else g.members.remove)(member)
                messages.success(request, "Groupes mis à jour.")
        except RuleViolation as e:
            messages.error(request, str(e))
        if once is None:
            return redirect("backoffice:user", pk=member.pk)
    assignments = member.assignments.select_related("role").order_by("revoked_at", "-starts_on")
    today = timezone.localdate()
    rows = []
    for a in assignments:
        active = a.revoked_at is None and a.starts_on <= today and (a.ends_on is None or a.ends_on >= today)
        progress = None
        if a.ends_on and a.ends_on > a.starts_on:
            total = (a.ends_on - a.starts_on).days
            progress = max(0, min(100, round(100 * (today - a.starts_on).days / total)))
        rows.append({"a": a, "active": active, "progress": progress,
                     "left_days": (a.ends_on - today).days if a.ends_on and active else None,
                     "expired": a.ends_on is not None and a.ends_on < today})
    roles = Role.objects.filter(is_archived=False)
    return render(request, "backoffice/user_detail.html", {
        "nav": "users", "member": member, "rows": rows, "roles": roles,
        "role_ends": {r.slug: (default_end(r, today).isoformat() if r.mandate_months else "") for r in roles},
        "groups": ServiceGroup.objects.all(), "member_groups": set(member.service_groups.values_list("pk", flat=True)),
        "once": once, "can_edit": request.user.can("backoffice.users", "change"), "today": today,
        "phone": format_phone(member.phone), "backoffice": member.has_usable_password(),
        "codes_left": BackupCode.remaining(member), "now": timezone.now(),
    })


@backoffice_view("backoffice.users", "create")
def user_new(request):
    ctx = {"nav": "users", "form": request.POST}
    if request.method == "POST":
        try:
            phone = normalize_phone(request.POST.get("phone"))
        except InvalidPhone as e:
            ctx["error"] = str(e)
            return render(request, "backoffice/user_new.html", ctx, status=400)
        last, first = request.POST.get("last_name", "").strip(), request.POST.get("first_name", "").strip()
        if not last or not first:
            ctx["error"] = "Nom et prénoms sont obligatoires."
            return render(request, "backoffice/user_new.html", ctx, status=400)
        if User.objects.filter(phone=phone).exists():
            ctx["error"] = "Ce numéro est déjà celui d’un membre."
            return render(request, "backoffice/user_new.html", ctx, status=400)
        pin = temporary_pin()
        with transaction.atomic():
            u = User(phone=phone, last_name=last, first_name=first, is_diaspora=bool(request.POST.get("is_diaspora")),
                     city=request.POST.get("city", "").strip(), birth_date=parse_date(request.POST.get("birth_date") or ""))
            u.set_unusable_password()
            u.set_pin(pin, temporary=True)
            u.save()
            assign_role(u, Role.objects.get(slug="membre"), reason="Création au back-office", by=request.user, request=request)
        audit.record("Utilisateur créé", actor=request.user, obj=u, request=request)
        return render(request, "backoffice/user_created.html", {"nav": "users", "member": u, "pin": pin})
    return render(request, "backoffice/user_new.html", ctx)


@require_POST
@backoffice_view("backoffice.users", "change")
def users_bulk(request):
    ids = [int(x) for x in request.POST.getlist("ids") if x.isdigit()]
    qs = User.objects.members().filter(pk__in=ids)
    action = request.POST.get("action")
    if action == "export":
        return _users_csv(qs, "selection")
    if action == "suspend":
        n = qs.exclude(status=User.Status.SUSPENDED).update(status=User.Status.SUSPENDED)
        audit.record("Suspension groupée", actor=request.user, request=request, sensitive=True, detail={"utilisateurs": n})
        messages.success(request, f"{n} utilisateur(s) suspendu(s).")
    elif action == "reset_pin":
        pins = [(u, reset_pin(u, by=request.user, request=request)) for u in qs]
        return _pins_csv(pins)
    return redirect("backoffice:users")


def _users_csv(qs, name):
    buf = io.StringIO()
    w = csv.writer(buf, delimiter=";")
    w.writerow(["Nom", "Prénoms", "Téléphone", "Statut", "Diaspora", "Ville", "Date de naissance", "Adhésion", "Rôles"])
    for u in qs.prefetch_related("assignments__role"):
        w.writerow([u.last_name, u.first_name, u.phone, u.get_status_display(), "oui" if u.is_diaspora else "non", u.city,
                    u.birth_date or "", u.joined_on, ", ".join(a.role.name for a in _active_roles(u))])
    resp = HttpResponse("﻿" + buf.getvalue(), content_type="text/csv; charset=utf-8")
    resp["Content-Disposition"] = f'attachment; filename="membres-{name}.csv"'
    return resp


def _pins_csv(pins):
    """Temporary PINs to hand over — the only time they're visible."""
    buf = io.StringIO()
    w = csv.writer(buf, delimiter=";")
    w.writerow(["Nom", "Téléphone", "Code PIN provisoire"])
    for u, pin in pins:
        w.writerow([u.full_name, format_phone(u.phone), pin])
    resp = HttpResponse("﻿" + buf.getvalue(), content_type="text/csv; charset=utf-8")
    resp["Content-Disposition"] = 'attachment; filename="codes-pin-provisoires.csv"'
    return resp


@backoffice_view("backoffice.users", "export")
def users_export(request):
    return _users_csv(User.objects.members().exclude(status=User.Status.ARCHIVED), "tous")


# --- Import -----------------------------------------------------------------------------

IMPORT_COLUMNS = {
    "nom": "last_name", "prénoms": "first_name", "prenoms": "first_name", "prénom": "first_name", "téléphone": "phone",
    "telephone": "phone", "groupe": "group", "date de naissance": "birth_date", "parent": "parent_name",
    "téléphone du parent": "parent_phone", "telephone du parent": "parent_phone", "ville": "city",
}


def _read_rows(upload):
    name = (upload.name or "").lower()
    if name.endswith(".xlsx"):
        from openpyxl import load_workbook

        ws = load_workbook(upload, read_only=True, data_only=True).active
        rows = [[("" if c is None else str(c)).strip() for c in r] for r in ws.iter_rows(values_only=True)]
    else:
        text = upload.read().decode("utf-8-sig", errors="replace")
        dialect = csv.Sniffer().sniff(text[:2000], delimiters=";,\t") if text.strip() else csv.excel
        rows = [[c.strip() for c in r] for r in csv.reader(io.StringIO(text), dialect)]
    rows = [r for r in rows if any(r)]
    if not rows:
        return []
    header = [IMPORT_COLUMNS.get(h.strip().lower(), "") for h in rows[0]]
    return [{k: v for k, v in zip(header, r, strict=False) if k} for r in rows[1:]]


def _check(row, seen):
    from datetime import datetime

    out = {"last_name": row.get("last_name", ""), "first_name": row.get("first_name", ""), "raw_phone": row.get("phone", ""),
           "group": row.get("group", ""), "city": row.get("city", ""), "parent_name": row.get("parent_name", ""), "error": None}
    if not out["last_name"] or not out["first_name"]:
        out["error"] = "Nom ou prénoms manquant"
        return out
    try:
        out["phone"] = normalize_phone(out["raw_phone"])
    except InvalidPhone:
        out["error"] = "Téléphone incomplet"
        return out
    if out["phone"] in seen:
        out["error"] = "Numéro en double dans le fichier"
        return out
    existing = User.objects.filter(phone=out["phone"]).first()
    if existing:
        out["error"] = f"Numéro déjà utilisé ({existing.short_name})"
        return out
    bd = row.get("birth_date", "")
    if bd:
        for fmt in ("%d/%m/%Y", "%Y-%m-%d", "%Y-%m-%d %H:%M:%S"):
            try:
                out["birth_date"] = datetime.strptime(bd, fmt).date().isoformat()
                break
            except ValueError:
                continue
        else:
            out["error"] = "Date de naissance illisible"
            return out
    if row.get("parent_phone"):
        try:
            out["parent_phone"] = normalize_phone(row["parent_phone"])
        except InvalidPhone:
            out["error"] = "Téléphone du parent incomplet"
            return out
    seen.add(out["phone"])
    return out


@backoffice_view("backoffice.users", "create")
def users_import(request):
    """Design: BImport — file, columns, check; error lines are skipped,
    never half-imported. Temporary PINs come back as a CSV to hand out."""
    key = f"bo-import:{request.session.session_key}"
    if request.method == "POST" and request.FILES.get("file"):
        upload = request.FILES["file"]
        try:
            rows = _read_rows(upload)
        except Exception:
            messages.error(request, "Fichier illisible. Utilisez un CSV (séparateur ;) ou un classeur .xlsx.")
            return redirect("backoffice:users_import")
        seen = set()
        checked = [_check(r, seen) for r in rows]
        cache.set(key, {"name": upload.name, "rows": checked}, 3600)
        return redirect("backoffice:users_import")
    data = cache.get(key)
    if request.method == "POST" and request.POST.get("action") == "errors" and data:
        buf = io.StringIO()
        w = csv.writer(buf, delimiter=";")
        w.writerow(["Nom", "Prénoms", "Téléphone", "Erreur"])
        for r in data["rows"]:
            if r["error"]:
                w.writerow([r["last_name"], r["first_name"], r["raw_phone"], r["error"]])
        resp = HttpResponse("﻿" + buf.getvalue(), content_type="text/csv; charset=utf-8")
        resp["Content-Disposition"] = 'attachment; filename="import-erreurs.csv"'
        return resp
    if request.method == "POST" and request.POST.get("action") == "import" and data:
        groups = {g.name.lower(): g for g in ServiceGroup.objects.all()}
        pins = []
        membre = Role.objects.get(slug="membre")
        with transaction.atomic():
            for r in data["rows"]:
                if r["error"] or User.objects.filter(phone=r["phone"]).exists():
                    continue
                u = User(phone=r["phone"], last_name=r["last_name"], first_name=r["first_name"], city=r["city"],
                         birth_date=parse_date(r.get("birth_date") or ""), parent_name=r["parent_name"], parent_phone=r.get("parent_phone", ""))
                u.set_unusable_password()
                pin = temporary_pin()
                u.set_pin(pin, temporary=True)
                u.save()
                RoleAssignment.objects.create(user=u, role=membre, reason=f"Import {data['name']}", assigned_by=request.user)
                Membership.join(u, membre.group_id)
                g = groups.get(r["group"].lower()) if r["group"] else None
                if g:
                    g.members.add(u)
                pins.append((u, pin))
        audit.record("Import d’utilisateurs", actor=request.user, request=request, sensitive=True,
                     detail={"fichier": data["name"], "importés": len(pins)})
        cache.delete(key)
        return _pins_csv(pins)
    if request.method == "POST" and request.POST.get("action") == "cancel":
        cache.delete(key)
        return redirect("backoffice:users_import")
    valid = [r for r in (data or {}).get("rows", []) if not r["error"]]
    return render(request, "backoffice/users_import.html", {
        "nav": "users", "data": data, "valid": len(valid), "invalid": len((data or {}).get("rows", [])) - len(valid),
    })


# --- Assignments ------------------------------------------------------------------------


@backoffice_view("backoffice.users", "view")
def assignments(request):
    """Design: BAssignments — every dated role, time elapsed, alerts 30
    days before a mandate ends."""
    today = timezone.localdate()
    horizon = request.GET.get("echeance")
    qs = RoleAssignment.objects.active().select_related("user", "role").exclude(role__slug="membre").order_by("ends_on", "user__last_name")
    if horizon in ("30", "90"):
        qs = qs.filter(ends_on__isnull=False, ends_on__lte=today + timedelta(days=int(horizon)))
    rows = []
    for a in qs:
        progress, state, label = None, "ok", "sans fin"
        if a.ends_on:
            total = max((a.ends_on - a.starts_on).days, 1)
            progress = max(0, min(100, round(100 * (today - a.starts_on).days / total)))
            left = (a.ends_on - today).days
            if a.is_one_day:
                state, label = "off", "rôle du jour" if left == 0 else f"rôle du jour · dans {(a.starts_on - today).days} j"
            elif a.role.kind == Role.Kind.TEMPORARY:
                state, label = "off", "expire ce soir" if left == 0 else f"expire dans {left} j"
            elif left <= 30:
                state, label = "warn", f"dans {left} jours"
            else:
                label = f"{left // 30} mois"
        rows.append({"a": a, "progress": progress, "state": state, "label": label})
    soon = [r for r in rows if r["state"] == "warn"]
    upcoming = (
        RoleAssignment.objects.filter(revoked_at__isnull=True, starts_on__gt=today, ends_on=F("starts_on"))
        .select_related("user", "role").order_by("starts_on")
    )
    return render(request, "backoffice/assignments.html", {
        "nav": "assign", "rows": rows, "soon": soon, "horizon": horizon, "upcoming": upcoming, "today": today,
        "can_edit": request.user.can("backoffice.users", "change"),
        "day_roles": Role.objects.filter(is_archived=False).exclude(slug__in=["membre", registry.SUPER_ADMIN_SLUG]),
        "members": User.objects.members().filter(status=User.Status.ACTIVE, is_active=True),
    })


def _assign_for_the_day(member, role, day, *, reason, by, request=None):
    """Any role except super admin, for one day only (owner, 2026-10-23:
    the censeur du jour, and every bureau role, can be given to someone for
    one activity). It ends by itself at midnight; the member is told."""
    if role.slug == registry.SUPER_ADMIN_SLUG:
        raise RuleViolation("Le rôle de super admin ne peut pas être donné pour une journée.")
    a = assign_role(member, role, reason=reason, by=by, starts_on=day, ends_on=day, request=request)
    when = "aujourd’hui" if day == timezone.localdate() else f"le {day:%d/%m/%Y}"
    notify([member], "member", "Rôle du jour", f"Vous êtes {role.name} {when}.", {"type": "role"})
    return a


@require_POST
@backoffice_view("backoffice.users", "change")
def assignment_day(request):
    member = get_object_or_404(User.objects.members(), pk=request.POST.get("member"), status=User.Status.ACTIVE)
    role = get_object_or_404(Role, slug=request.POST.get("role"), is_archived=False)
    day = parse_date(request.POST.get("day") or "") or timezone.localdate()
    if day < timezone.localdate():
        messages.error(request, "Choisissez aujourd’hui ou une date à venir.")
        return redirect("backoffice:assignments")
    try:
        _assign_for_the_day(member, role, day, reason=request.POST.get("reason", ""), by=request.user, request=request)
        messages.success(request, f"{member.short_name} est {role.name} le {day:%d/%m/%Y} (rôle du jour).")
    except RuleViolation as e:
        messages.error(request, str(e))
    return redirect("backoffice:assignments")


@require_POST
@backoffice_view("backoffice.users", "change")
def assignment_renew(request, pk):
    a = get_object_or_404(RoleAssignment.objects.select_related("role", "user"), pk=pk)
    start = (a.ends_on or timezone.localdate()) + timedelta(days=1)
    try:
        assign_role(a.user, a.role, reason=request.POST.get("reason") or "Renouvellement du mandat", by=request.user, starts_on=start, request=request)
        messages.success(request, f"Mandat de {a.user.short_name} renouvelé à partir du {start:%d/%m/%Y}.")
    except RuleViolation as e:
        messages.error(request, str(e))
    return redirect("backoffice:assignments")


# --- Role requests ------------------------------------------------------------------------


@require_POST
@backoffice_view("backoffice.users", "change")
def role_request_decide(request, pk):
    rr = get_object_or_404(RoleRequest.objects.select_related("member", "role"), pk=pk, status=RoleRequest.Status.PENDING)
    if request.POST.get("approve"):
        try:
            assign_role(rr.member, rr.role, reason=f"Demande approuvée : {rr.reason}", by=request.user,
                        starts_on=rr.starts_on, ends_on=rr.ends_on, request=request)
        except RuleViolation as e:
            messages.error(request, str(e))
            return redirect("backoffice:dashboard")
        rr.status = RoleRequest.Status.APPROVED
        messages.success(request, f"{rr.role.name} affecté à {rr.member.short_name}.")
    else:
        rr.status = RoleRequest.Status.REFUSED
        audit.record("Demande de rôle refusée", actor=request.user, obj=rr.member, request=request, detail={"role": rr.role.name})
        messages.success(request, "Demande refusée.")
    rr.decided_by = request.user
    rr.save(update_fields=["status", "decided_by"])
    return redirect("backoffice:dashboard")


# --- Roles management --------------------------------------------------------------------


@require_POST
@backoffice_view("backoffice.users", "change")
def role_manage(request, slug=None):
    """New / rename / duplicate / archive (design: BRoles toolbar)."""
    from django.utils.text import slugify

    action = request.POST.get("action")
    name = (request.POST.get("name") or "").strip()
    if action == "new":
        if not name:
            messages.error(request, "Nom requis.")
            return redirect("backoffice:roles")
        base = slugify(name) or "role"
        s, i = base, 2
        while Role.objects.filter(slug=s).exists():
            s, i = f"{base}-{i}", i + 1
        role = Role.objects.create(slug=s, name=name, kind=request.POST.get("kind") or Role.Kind.STANDARD)
        audit.record("Rôle créé", actor=request.user, obj=role, request=request, sensitive=True)
        return redirect("backoffice:role", slug=role.slug)
    role = get_object_or_404(Role, slug=slug)
    if action == "rename" and name:
        old = role.name
        role.name = name
        role.save(update_fields=["name"])
        audit.record("Rôle renommé", actor=request.user, obj=role, request=request, detail={"avant": old, "après": name})
    elif action == "duplicate":
        base = f"{role.slug}-copie"
        s, i = base, 2
        while Role.objects.filter(slug=s).exists():
            s, i = f"{base}-{i}", i + 1
        copy = Role.objects.create(slug=s, name=f"{role.name} (copie)", kind=role.kind, mandate_months=role.mandate_months)
        RolePermission.objects.bulk_create([RolePermission(role=copy, resource=p.resource, action=p.action) for p in role.permissions.all()])
        audit.record("Rôle dupliqué", actor=request.user, obj=copy, request=request, detail={"depuis": role.name})
        return redirect("backoffice:role", slug=copy.slug)
    elif action == "archive":
        if role.slug in ("super-admin", "membre", registry.SUPER_ADMIN_SLUG):
            messages.error(request, "Ce rôle ne peut pas être archivé.")
        elif RoleAssignment.objects.active().filter(role=role).exists():
            messages.error(request, "Des personnes ont encore ce rôle : retirez-le d’abord.")
        else:
            role.is_archived = True
            role.save(update_fields=["is_archived"])
            audit.record("Rôle archivé", actor=request.user, obj=role, request=request, sensitive=True)
            return redirect("backoffice:roles")
    return redirect("backoffice:role", slug=role.slug)


# --- Settings ----------------------------------------------------------------------------


SETTING_FIELDS = ["parish", "welcome_message", "motto", "fee_registration", "fee_medal", "fee_illness", "fee_death", "installments",
                  "assise_time", "vigil_time", "reminder_time", "duty_template"]


@backoffice_view("backoffice.users", "view")
def settings_view(request):
    st = Settings.get()
    if request.method == "POST":
        if not request.user.can("backoffice.users", "change"):
            return _deny(request)
        changed = {}
        name = request.POST.get("name", "").strip()
        if name and name != st.group.name:
            changed["name"] = name
            st.group.name = name
            st.group.save(update_fields=["name"])
        for f in SETTING_FIELDS:
            if f not in request.POST:
                continue
            raw = request.POST[f].strip()
            field = Settings._meta.get_field(f)
            try:
                value = field.to_python(raw)
            except Exception:
                messages.error(request, f"Valeur invalide : {field.verbose_name}.")
                return redirect("backoffice:settings")
            if getattr(st, f) != value:
                changed[f] = str(value)
                setattr(st, f, value)
        st.save()
        if changed:
            audit.record("Paramètres modifiés", actor=request.user, obj=None, request=request, detail=changed)
        messages.success(request, "Paramètres enregistrés.")
        return redirect("backoffice:settings")
    from apps.events.models import ActivityType, DressCode

    return render(request, "backoffice/settings.html", {
        "nav": "settings", "s": st, "today": date.today(),
        "activity_types": ActivityType.objects.all(), "dress_codes": DressCode.objects.all(),
    })


def _new_slug(model, name, max_length):
    from django.utils.text import slugify

    base = slugify(name)[:max_length - 3] or "x"
    slug, n = base, 2
    while model.objects.filter(slug=slug).exists():
        slug, n = f"{base}-{n}"[:max_length], n + 1
    return slug


@require_POST
@backoffice_view("backoffice.users", "change")
def settings_lists(request):
    """The group's own activity types and dress codes."""
    from apps.events.models import ActivityType, DressCode

    P = request.POST
    changed = []
    for a in ActivityType.objects.all():
        k = f"a{a.pk}"
        new = (P.get(f"{k}_name", a.name).strip() or a.name, bool(P.get(f"{k}_lineup")), bool(P.get(f"{k}_presence")), bool(P.get(f"{k}_archived")))
        if new != (a.name, a.needs_lineup, a.counts_presence, a.is_archived):
            a.name, a.needs_lineup, a.counts_presence, a.is_archived = new
            a.save()
            changed.append(a.name)
    if P.get("a_new_name", "").strip():
        name = P["a_new_name"].strip()[:60]
        ActivityType.objects.create(slug=_new_slug(ActivityType, name, 20), name=name, needs_lineup=bool(P.get("a_new_lineup")),
                                    counts_presence=bool(P.get("a_new_presence")), sort_order=ActivityType.objects.count() * 10)
        changed.append(name)
    for d in DressCode.objects.all():
        k = f"d{d.pk}"
        new = (P.get(f"{k}_name", d.name).strip() or d.name, bool(P.get(f"{k}_archived")))
        if new != (d.name, d.is_archived):
            d.name, d.is_archived = new
            d.save()
            changed.append(d.name)
    if P.get("d_new_name", "").strip():
        name = P["d_new_name"].strip()[:60]
        DressCode.objects.create(slug=_new_slug(DressCode, name, 12), name=name, sort_order=DressCode.objects.count() * 10)
        changed.append(name)
    if changed:
        audit.record("Listes du groupe modifiées", actor=request.user, request=request, detail={"elements": ", ".join(changed)[:300]})
    messages.success(request, "Listes enregistrées.")
    return redirect("backoffice:settings")


@backoffice_view("backoffice.audit", "export")
def audit_export(request):
    buf = io.StringIO()
    w = csv.writer(buf, delimiter=";")
    w.writerow(["Date", "Auteur", "Action", "Objet", "Détail", "Refusé", "IP", "Appareil"])
    for e in AuditLog.objects.filter(Q(group=request.group) | Q(group__isnull=True)).select_related("actor")[:20000]:
        w.writerow([timezone.localtime(e.created_at).strftime("%d/%m/%Y %H:%M"), e.actor.short_name if e.actor else "Système", e.action,
                    e.object_repr, " · ".join(f"{k}: {v}" for k, v in e.detail.items()), "oui" if e.refused else "", e.ip or "", e.device])
    audit.record("Export du journal d’audit", actor=request.user, request=request)
    resp = HttpResponse("﻿" + buf.getvalue(), content_type="text/csv; charset=utf-8")
    resp["Content-Disposition"] = 'attachment; filename="journal-audit.csv"'
    return resp
