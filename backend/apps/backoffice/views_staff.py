"""Équipe du back-office (owner, 2026-10-26): the support, IT helpdesk and
integration ops teams, at two levels. The super admin creates staff
accounts, changes their role and removes them (backoffice.roles:change); the
IT helpdesk closes a staff member's sessions and issues new backup codes
(backoffice.security:change). Nobody but a super admin touches a super
admin's account."""

import secrets
import string

from django.contrib import messages
from django.contrib.sessions.models import Session
from django.db import transaction
from django.shortcuts import get_object_or_404, redirect, render
from django.views.decorators.http import require_POST

from apps.accounts import registry
from apps.accounts.models import Role, RoleAssignment, User
from apps.accounts.phone import InvalidPhone, format_phone, normalize_phone
from apps.accounts.services import RuleViolation, assign_role, revoke_assignment
from apps.core import audit

from .access import backoffice_view
from .models import BackofficeSession, BackupCode


def _staff_role(slug):
    if slug not in registry.STAFF_ROLES:
        raise RuleViolation("Choisissez une équipe et un niveau.")
    return Role.all_groups.get(group=None, slug=slug)


def _password():
    alphabet = string.ascii_letters + string.digits
    return "".join(secrets.choice(alphabet) for _ in range(14))


def _deny(request, action, target=None):
    audit.record("Action back-office refusée", actor=request.user, obj=target, request=request, sensitive=True,
                 refused=True, platform=True, detail={"action": action})
    return render(request, "backoffice/forbidden.html", status=403)


@backoffice_view(None)
def staff(request):
    me = request.user
    can_manage = me.can("backoffice.roles", "change")
    can_help = me.can("backoffice.security", "change")
    if not (can_manage or me.can("backoffice.security", "view")):
        return _deny(request, "voir l’équipe")
    once = None
    if request.method == "POST":
        action = request.POST.get("action")
        reason = (request.POST.get("reason") or "").strip()
        try:
            if action == "create":
                if not can_manage:
                    return _deny(request, action)
                once = _create(request, reason)
            else:
                target = get_object_or_404(User, pk=request.POST.get("user"))
                if target.is_super_admin and not me.is_super_admin:
                    return _deny(request, action, target)
                if action in ("change_role", "remove") and not can_manage:
                    return _deny(request, action, target)
                if action in ("close_sessions", "new_codes") and not (can_help or can_manage):
                    return _deny(request, action, target)
                once = _act(request, target, action, reason)
        except (RuleViolation, InvalidPhone) as e:
            messages.error(request, str(e))
        if once is None:
            return redirect("backoffice:staff")
    holders = (RoleAssignment.all_groups.active()
               .filter(role__group__isnull=True, role__slug__in=registry.PLATFORM_ROLES)
               .select_related("user", "role").order_by("role__sort_order", "user__last_name"))
    rows = []
    for a in holders:
        team = registry.STAFF_ROLES.get(a.role.slug, (a.role.name, "Super admin", 3))
        rows.append({"a": a, "team": team[1], "level": team[2], "phone": format_phone(a.user.phone),
                     "sessions": BackofficeSession.objects.filter(user=a.user).count(),
                     "codes": BackupCode.remaining(a.user), "password": a.user.has_usable_password()})
    roles = [(slug, *spec) for slug, spec in registry.STAFF_ROLES.items()]
    return render(request, "backoffice/staff.html", {
        "nav": "staff", "rows": rows, "roles": roles, "can_manage": can_manage, "can_help": can_help or can_manage,
        "once": once, "access": _access_summary(),
    })


def _create(request, reason):
    phone = normalize_phone(request.POST.get("phone"))
    last, first = request.POST.get("last_name", "").strip(), request.POST.get("first_name", "").strip()
    if not last or not first:
        raise RuleViolation("Nom et prénoms sont obligatoires.")
    if not reason:
        raise RuleViolation("Le motif est obligatoire : il est inscrit au journal.")
    role = _staff_role(request.POST.get("role"))
    if User.objects.filter(phone=phone).exists():
        raise RuleViolation("Ce numéro a déjà un compte. Un compte du back-office est séparé des comptes de "
                            "l’application : utilisez un autre numéro.")
    pw = _password()
    with transaction.atomic():
        u = User(phone=phone, last_name=last, first_name=first)
        u.set_password(pw)
        u.save()
        assign_role(u, role, reason=reason, by=request.user, request=request)
    codes = BackupCode.regenerate(u)
    audit.record("Compte de l’équipe créé", actor=request.user, obj=u, request=request, sensitive=True, platform=True,
                 detail={"rôle": role.name, "motif": reason})
    return {"title": f"{u.full_name} · {role.name}", "password": pw, "codes": codes,
            "hint": "Communiquez-les en main propre : le mot de passe pour se connecter, un code de secours pour la "
                    "vérification tant que les SMS ne sont pas disponibles. Ils ne seront plus affichés."}


def _act(request, target, action, reason):
    current = (RoleAssignment.all_groups.active()
               .filter(user=target, role__group__isnull=True, role__slug__in=registry.STAFF_ROLES).first())
    if action == "change_role":
        role = _staff_role(request.POST.get("role"))
        if current is None:
            raise RuleViolation("Ce compte n’est pas dans l’équipe.")
        if current.role_id == role.pk:
            return None
        with transaction.atomic():
            revoke_assignment(current, by=request.user, reason=reason or f"Nouveau rôle : {role.name}", request=request)
            assign_role(target, role, reason=reason or "Changement d’équipe ou de niveau", by=request.user, request=request)
        messages.success(request, f"{target.short_name} est maintenant {role.name}.")
    elif action == "remove":
        if current is None:
            raise RuleViolation("Ce compte n’est pas dans l’équipe.")
        if not reason:
            raise RuleViolation("Le motif est obligatoire : il est inscrit au journal.")
        revoke_assignment(current, by=request.user, reason=reason, request=request)
        _close_sessions(target)
        target.set_unusable_password()
        target.save(update_fields=["password"])
        BackupCode.objects.filter(user=target).delete()
        audit.record("Compte de l’équipe retiré", actor=request.user, obj=target, request=request, sensitive=True,
                     platform=True, detail={"motif": reason})
        messages.success(request, f"{target.short_name} n’a plus accès au back-office.")
    elif action == "close_sessions":
        n = _close_sessions(target)
        audit.record("Sessions d’un membre de l’équipe fermées", actor=request.user, obj=target, request=request,
                     sensitive=True, platform=True, detail={"sessions": n})
        messages.success(request, f"{n} session(s) fermée(s) pour {target.short_name}.")
    elif action == "new_codes":
        codes = BackupCode.regenerate(target)
        audit.record("Codes de secours d’un membre de l’équipe régénérés", actor=request.user, obj=target,
                     request=request, sensitive=True, platform=True)
        return {"title": f"Codes de secours · {target.full_name}", "codes": codes,
                "hint": "Les anciens codes ne marchent plus. Remettez ceux-ci en main propre."}
    return None


def _close_sessions(user):
    rows = BackofficeSession.objects.filter(user=user)
    n = rows.count()
    Session.objects.filter(session_key__in=rows.values_list("session_key", flat=True)).delete()
    rows.delete()
    return n


def _access_summary():
    """Each staff role's areas, from the matrix (for the page's legend)."""
    labels = {res: spec[1] for res, spec in registry.RESOURCES.items()}
    out = []
    for slug, (name, team, level) in registry.STAFF_ROLES.items():
        role = Role.all_groups.filter(group=None, slug=slug).first()
        cells = {}
        if role:
            for res, act in role.permissions.values_list("resource", "action"):
                cells.setdefault(labels.get(res, res), []).append(registry.ACTION_LABELS[act].lower())
        out.append({"slug": slug, "name": name, "team": team, "level": level, "cells": sorted(cells.items())})
    return out


@require_POST
@backoffice_view("backoffice.integrations", "change")
def integration_check(request):
    from .views_integrations import check_storage

    ok, detail = check_storage()
    audit.record("Test du stockage", actor=request.user, request=request, platform=True, detail={"résultat": detail})
    (messages.success if ok else messages.error)(request, detail)
    return redirect("backoffice:integrations")
