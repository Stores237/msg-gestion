from datetime import timedelta

from django.contrib import messages
from django.contrib.auth import authenticate, login, logout
from django.core.paginator import Paginator
from django.db.models import Count, F, Q
from django.shortcuts import get_object_or_404, redirect, render
from django.utils import timezone
from django.views.decorators.http import require_http_methods, require_POST

from apps.accounts import registry
from apps.accounts.models import Role, RoleAssignment, RoleRequest, User
from apps.accounts.phone import InvalidPhone, mask_phone, normalize_phone
from apps.accounts.services import RuleViolation, set_role_permissions
from apps.core import audit, sms
from apps.core.audit import client_ip
from apps.core.models import AuditLog
from apps.planning.models import ServiceGroup

from .access import (
    SESSION_OTP_OK,
    SESSION_PENDING,
    SESSION_SMS_OK,
    TRUST_COOKIE,
    backoffice_view,
    can_enter,
    is_trusted,
    rate_limited,
    trust_token,
)
from .models import BackofficeSession, BackupCode

BAD_LOGIN = "Numéro ou mot de passe incorrect."


# --- Login ---------------------------------------------------------------------


@require_http_methods(["GET", "POST"])
def login_view(request):
    if request.user.is_authenticated and request.session.get(SESSION_OTP_OK):
        return redirect("backoffice:dashboard")
    ctx = {"phone": request.POST.get("phone", "")}
    if request.method == "POST":
        if rate_limited(request, "login", 20):
            ctx["error"] = "Trop de tentatives. Réessayez dans une heure."
            return render(request, "backoffice/login.html", ctx, status=429)
        try:
            phone = normalize_phone(request.POST.get("phone"))
        except InvalidPhone:
            phone = None
        user = authenticate(request, phone=phone, password=request.POST.get("password", "")) if phone else None
        if user is None or not can_enter(user):
            audit.record("Échec de connexion back-office", request=request, detail={"phone": mask_phone(phone) if phone else "invalide"})
            ctx["error"] = BAD_LOGIN
            return render(request, "backoffice/login.html", ctx, status=401)
        if is_trusted(request, user):
            return _complete_login(request, user, trusted=True)
        sms_ok = True
        try:
            sms.send_code(user.phone)
        except sms.SmsUnavailable:
            sms_ok = False
            if not BackupCode.remaining(user):
                ctx["error"] = "Le code de vérification n’a pas pu être envoyé. Réessayez dans quelques minutes."
                return render(request, "backoffice/login.html", ctx, status=503)
        request.session[SESSION_PENDING] = user.pk
        request.session[SESSION_SMS_OK] = sms_ok
        return redirect("backoffice:otp")
    return render(request, "backoffice/login.html", ctx)


@require_http_methods(["GET", "POST"])
def otp_view(request):
    user = User.objects.filter(pk=request.session.get(SESSION_PENDING)).first()
    if user is None:
        return redirect("backoffice:login")
    sms_ok = request.session.get(SESSION_SMS_OK, True)
    ctx = {"masked": mask_phone(user.phone), "sms_ok": sms_ok, "backup": request.GET.get("secours") == "1" or not sms_ok}
    if request.method == "POST" and request.POST.get("backup_code") is not None:
        if rate_limited(request, "otp", 20):
            ctx["error"] = "Trop de tentatives. Réessayez dans une heure."
            return render(request, "backoffice/otp.html", ctx, status=429)
        if BackupCode.consume(user, request.POST.get("backup_code")):
            audit.record("Connexion avec un code de secours", actor=user, obj=user, request=request,
                         detail={"restants": BackupCode.remaining(user)})
            return _complete_login(request, user)
        audit.record("Code de secours refusé", obj=user, request=request)
        ctx["error"] = "Code de secours incorrect ou déjà utilisé."
        ctx["backup"] = True
        return render(request, "backoffice/otp.html", ctx, status=401)
    if request.method == "POST":
        if rate_limited(request, "otp", 20):
            ctx["error"] = "Trop de tentatives. Réessayez dans une heure."
            return render(request, "backoffice/otp.html", ctx, status=429)
        if request.POST.get("resend"):
            try:
                sms.send_code(user.phone)
                ctx["info"] = "Nouveau code envoyé."
            except sms.SmsUnavailable:
                ctx["error"] = "Le code n’a pas pu être renvoyé."
            return render(request, "backoffice/otp.html", ctx)
        code = "".join(request.POST.getlist("d")) or request.POST.get("code", "")
        try:
            ok = sms.check_code(user.phone, code)
        except sms.SmsUnavailable:
            ctx["error"] = "Vérification impossible pour le moment. Réessayez."
            return render(request, "backoffice/otp.html", ctx, status=503)
        if not ok:
            audit.record("Code 2FA refusé", obj=user, request=request)
            ctx["error"] = "Code incorrect ou expiré."
            return render(request, "backoffice/otp.html", ctx, status=401)
        response = _complete_login(request, user)
        if request.POST.get("trust"):
            response.set_cookie(
                TRUST_COOKIE,
                trust_token(user),
                max_age=30 * 86400,
                httponly=True,
                secure=request.is_secure(),
                samesite="Lax",
            )
        return response
    return render(request, "backoffice/otp.html", ctx)


def _complete_login(request, user, trusted=False):
    login(request, user, backend="django.contrib.auth.backends.ModelBackend")
    request.session.pop(SESSION_PENDING, None)
    request.session.pop(SESSION_SMS_OK, None)
    request.session[SESSION_OTP_OK] = True
    request.session.save()
    BackofficeSession.objects.update_or_create(
        session_key=request.session.session_key,
        defaults={"user": user, "device": request.META.get("HTTP_USER_AGENT", "")[:200], "ip": client_ip(request)},
    )
    audit.record("Connexion back-office", actor=user, obj=user, request=request, detail={"appareil_de_confiance": trusted})
    return redirect("backoffice:dashboard")


@require_POST
def logout_view(request):
    BackofficeSession.objects.filter(session_key=request.session.session_key).delete()
    logout(request)
    return redirect("backoffice:login")


# --- Pages -----------------------------------------------------------------------


def _finances():
    """The dashboard's Finances panel."""
    from apps.finances.models import Collection, Entry
    from apps.finances.services import balance, statement_rows, statement_totals

    totals = statement_totals(statement_rows())
    return {
        "balance": balance(Entry.objects.filter(status=Entry.Status.VALIDATED)),
        "pending": Entry.objects.exclude(status=Entry.Status.VALIDATED).count(),
        "open_collections": Collection.objects.filter(closed_at__isnull=True).count(),
        **totals,
    }


@backoffice_view(None)
def dashboard(request):
    today = timezone.localdate()
    active = User.objects.members().filter(gstatus=User.Status.ACTIVE, is_active=True)
    soon = (
        RoleAssignment.objects.active()
        .filter(ends_on__isnull=False, ends_on__lte=today + timedelta(days=30), role__kind=Role.Kind.BUREAU)
        .exclude(ends_on=F("starts_on"))  # a role of the day isn't a mandate
    )
    super_admins = RoleAssignment.objects.active().filter(role__slug=registry.SUPER_ADMIN_SLUG).values("user").distinct().count()
    ctx = {
        "nav": "dash",
        "kpi_active": active.count(),
        "kpi_diaspora": active.filter(is_diaspora=True).count(),
        "kpi_suspended": User.objects.members().filter(gstatus=User.Status.SUSPENDED).count(),
        "kpi_expiring": soon.count(),
        "kpi_super_admins": super_admins,
        "min_super_admins": registry.MIN_SUPER_ADMINS,
        "recent": AuditLog.objects.filter(sensitive=True).select_related("actor")[:6] if request.user.can("backoffice.audit", "view") else [],
        "can_audit": request.user.can("backoffice.audit", "view"),
        "can_roles": request.user.can("backoffice.roles", "change"),
        "can_create_users": request.user.can("backoffice.users", "create"),
        "can_see_finances": request.user.can("finances.cashbook", "view"),
        "fin": _finances() if request.user.can("finances.cashbook", "view") else None,
        "requests": RoleRequest.objects.filter(status=RoleRequest.Status.PENDING).select_related("member", "role", "requested_by")[:10],
        "expiring": soon.select_related("user", "role")[:5],
        "users_total": User.objects.members().exclude(gstatus=User.Status.ARCHIVED).count(),
        "active_roles": Role.objects.filter(is_archived=False).count(),
        "last_activity": AuditLog.objects.first(),
    }
    return render(request, "backoffice/dashboard.html", ctx)


@backoffice_view("backoffice.users", "view")
def users(request):
    q = request.GET.get("q", "").strip()
    status = request.GET.get("statut", "")
    qs = User.objects.members().exclude(gstatus=User.Status.ARCHIVED).prefetch_related("assignments__role")
    if q:
        qs = qs.filter(Q(last_name__icontains=q) | Q(first_name__icontains=q) | Q(phone__icontains=q.replace(" ", "")))
    if status:
        qs = qs.filter(gstatus=status)
    role = request.GET.get("role", "")
    if role == registry.SUPER_ADMIN_SLUG:
        # Super admins run the platform: they belong to no group.
        qs = User.objects.filter(assignments__role__slug=role, assignments__role__group__isnull=True,
                                 assignments__revoked_at__isnull=True).distinct().prefetch_related("assignments__role")
    elif role:
        qs = qs.filter(assignments__role__slug=role, assignments__revoked_at__isnull=True).distinct()
    group = request.GET.get("groupe", "")
    if group.isdigit():
        qs = qs.filter(service_groups__pk=int(group))
    diaspora = request.GET.get("diaspora", "")
    if diaspora in ("1", "0"):
        qs = qs.filter(is_diaspora=diaspora == "1")
    page = Paginator(qs, 25).get_page(request.GET.get("page"))
    today = timezone.localdate()
    rows = []
    for u in page:
        roles = [a for a in u.assignments.all() if a.revoked_at is None and a.starts_on <= today and (a.ends_on is None or a.ends_on >= today)]
        rows.append((u, roles))
    return render(
        request,
        "backoffice/users.html",
        {"nav": "users", "rows": rows, "page": page, "q": q, "statut": status, "statuses": User.Status.choices, "total": qs.count(),
         "role": role, "groupe": group, "diaspora": diaspora, "roles": Role.objects.filter(is_archived=False),
         "groups": ServiceGroup.objects.all(), "can_edit": request.user.can("backoffice.users", "change"),
         "can_create": request.user.can("backoffice.users", "create")},
    )


@backoffice_view("backoffice.roles", "view")
def roles(request, slug=None):
    all_roles = Role.objects.filter(is_archived=False)
    role = get_object_or_404(Role, slug=slug) if slug else all_roles.first()
    counts = {
        r["role"]: r["n"]
        for r in RoleAssignment.objects.active().values("role").annotate(n=Count("user", distinct=True))
    }
    if request.method == "POST":
        if not request.user.can("backoffice.roles", "change"):
            return render(request, "backoffice/forbidden.html", status=403)
        wanted = {tuple(v.split(":", 1)) for v in request.POST.getlist("perm")}
        changes = {}
        for res, spec in registry.RESOURCES.items():
            for act in spec[2]:
                if registry.is_locked(role.slug, res, act):
                    continue
                changes[(res, act)] = (res, act) in wanted
        try:
            diff = set_role_permissions(role, changes, by=request.user, reason=request.POST.get("reason", ""), request=request)
        except RuleViolation as exc:
            messages.error(request, str(exc))
        else:
            messages.success(request, f"{len(diff)} modification(s) enregistrée(s)." if diff else "Aucune modification.")
        return redirect("backoffice:role", slug=role.slug)

    granted = set(role.permissions.values_list("resource", "action"))
    matrix = []
    for module_key, module_label in registry.MODULES.items():
        matrix.append({"module": module_label})
        for res, (mod, label, actions, sensitive) in registry.RESOURCES.items():
            if mod != module_key:
                continue
            cells = []
            for act in registry.ACTIONS:
                if act not in actions:
                    cells.append({"state": "na"})
                elif registry.is_locked(role.slug, res, act):
                    cells.append({"state": "lock"})
                else:
                    cells.append({"state": "on" if (res, act) in granted else "off", "value": f"{res}:{act}"})
            matrix.append({"label": label, "sensitive": sensitive, "cells": cells})
    holders = RoleAssignment.objects.active().filter(role=role).select_related("user")
    return render(
        request,
        "backoffice/roles.html",
        {
            "nav": "roles",
            "roles": [(r, counts.get(r.pk, 0)) for r in all_roles],
            "role": role,
            "matrix": matrix,
            "actions": registry.ACTION_LABELS.values(),
            "holders": holders,
            "can_edit": request.user.can("backoffice.roles", "change"),
            "open_ended": role.slug in registry.OPEN_ENDED_ROLES,
            "months_max": registry.ROLE_MONTHS_MAX,
        },
    )


@backoffice_view("backoffice.audit", "view")
def audit_log(request):
    # This group's entries plus the platform's own (logins, groups, super admins).
    qs = AuditLog.objects.filter(Q(group=request.group) | Q(group__isnull=True)).select_related("actor")
    if request.GET.get("sensibles"):
        qs = qs.filter(Q(sensitive=True) | Q(refused=True))
    page = Paginator(qs, 50).get_page(request.GET.get("page"))
    return render(request, "backoffice/audit.html", {"nav": "audit", "page": page, "total": qs.count(), "only_sensitive": bool(request.GET.get("sensibles"))})
