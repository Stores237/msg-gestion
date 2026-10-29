"""The platform's groups (back-office → Groupes): list, create, edit,
delete (two super admins), switch."""

from django.contrib import messages
from django.db.models import Count, Q
from django.shortcuts import get_object_or_404, redirect, render
from django.utils.http import url_has_allowed_host_and_scheme
from django.views.decorators.http import require_POST

from apps.core import audit
from apps.core.group_admin import (
    DELETION_WINDOW,
    GroupAdminError,
    cancel_deletion,
    confirm_deletion,
    create_group,
    last_deletion,
    pending_deletion,
    request_deletion,
    restore_group,
    update_group,
)
from apps.core.models import APP_COLORS, Group, Settings

from .access import SESSION_GROUP, backoffice_view


@backoffice_view("backoffice.groups", "view")
def groups(request):
    if request.method == "POST":
        if not request.user.can("backoffice.groups", "create"):
            return render(request, "backoffice/forbidden.html", status=403)
        name = request.POST.get("name", "").strip()
        if not name:
            messages.error(request, "Le nom du groupe est obligatoire.")
            return redirect("backoffice:groups")
        g = create_group(name=name, place=request.POST.get("place", ""), motto=request.POST.get("motto", ""),
                         welcome_message=request.POST.get("welcome_message", ""), by=request.user, request=request)
        request.session[SESSION_GROUP] = g.pk
        messages.success(request, f"Groupe « {g.name} » créé avec les rôles par défaut. Vous travaillez maintenant sur ce groupe.")
        return redirect("backoffice:groups")
    rows = list(Group.objects.annotate(n=Count("memberships", filter=Q(memberships__is_active=True))).order_by("name"))
    for g in rows:
        g.st = Settings.get(g)
        g.pending = pending_deletion(g) if g.is_active else None
        if g.pending is not None:
            g.pending.expires = g.pending.requested_at + DELETION_WINDOW
        g.deletion = None if g.is_active else last_deletion(g)
    return render(request, "backoffice/groups.html", {
        "nav": "groups", "rows": [g for g in rows if g.is_active], "palette": APP_COLORS,
        "deleted": [g for g in rows if not g.is_active],
    })


def _refused(request, group, action, err):
    # Outside any transaction, so the trace stays.
    audit.record(action, actor=request.user, obj=group, request=request, platform=True, sensitive=True,
                 refused=True, detail={"raison": str(err)})
    messages.error(request, str(err))
    return redirect("backoffice:groups")


@require_POST
@backoffice_view("backoffice.groups", "change")
def group_edit(request, pk):
    g = get_object_or_404(Group, pk=pk)
    try:
        changed = update_group(g, by=request.user, request=request, name=request.POST.get("name"),
                               **{f: request.POST.get(f) for f in ("parish", "motto", "welcome_message", "color", "color2")})
    except GroupAdminError as e:
        return _refused(request, g, "Modification de groupe refusée", e)
    messages.success(request, f"Groupe « {g.name} » enregistré." if changed else "Aucun changement.")
    return redirect("backoffice:groups")


@require_POST
@backoffice_view("backoffice.groups", "delete")
def group_delete(request, pk):
    """action=request (1st super admin), confirm (another one), cancel;
    restore brings a deleted group back."""
    g = get_object_or_404(Group, pk=pk)
    action = request.POST.get("action")
    typed = request.POST.get("confirm_name", "")
    try:
        if action == "request":
            request_deletion(g, by=request.user, reason=request.POST.get("reason", ""), typed_name=typed, request=request)
            messages.success(request, f"Suppression de « {g.name} » demandée. Un autre super admin doit la confirmer "
                                      f"dans les {DELETION_WINDOW.days} jours ; rien n’est supprimé d’ici là.")
        elif action == "confirm":
            name = confirm_deletion(g, by=request.user, typed_name=typed, request=request)
            messages.success(request, f"Groupe « {name} » supprimé : il n’apparaît plus, ses données sont conservées. "
                                      "Vous pouvez le restaurer depuis « Groupes supprimés ».")
        elif action == "cancel":
            cancel_deletion(g, by=request.user, request=request)
            messages.success(request, "Demande de suppression annulée.")
        elif action == "restore":
            restore_group(g, by=request.user, request=request)
            messages.success(request, f"Groupe « {g.name} » restauré, avec toutes ses données.")
        else:
            return redirect("backoffice:groups")
    except GroupAdminError as e:
        return _refused(request, g, "Suppression de groupe refusée", e)
    return redirect("backoffice:groups")


@require_POST
@backoffice_view(None)
def group_switch(request):
    g = get_object_or_404(Group, pk=request.POST.get("group"), is_active=True)
    request.session[SESSION_GROUP] = g.pk
    nxt = request.POST.get("next") or ""
    if not url_has_allowed_host_and_scheme(nxt, allowed_hosts={request.get_host()}):
        nxt = ""
    return redirect(nxt or "backoffice:dashboard")


PLATFORM_FIELDS = ["support_phone", "support_whatsapp", "support_email", "website", "privacy_text", "terms_text"]


@backoffice_view("backoffice.platform", "view")
def platform(request):
    """The partner's contacts and the legal texts shown in the app's Aide /
    À propos (owner, 2026-10-26)."""
    from apps.core.models import PlatformSettings

    p = PlatformSettings.get()
    if request.method == "POST":
        if not request.user.can("backoffice.platform", "change"):
            return render(request, "backoffice/forbidden.html", status=403)
        changed = {}
        for f in PLATFORM_FIELDS:
            if f not in request.POST:
                continue
            field = PlatformSettings._meta.get_field(f)
            value = request.POST[f].strip().replace("\r\n", "\n")  # browsers send CRLF; don't count it as a new text
            try:
                field.run_validators(value) if value else None
            except Exception:
                messages.error(request, f"Valeur invalide : {field.verbose_name}.")
                return redirect("backoffice:platform")
            if getattr(p, f) != value:
                changed[f] = value if f not in ("privacy_text", "terms_text") else "(texte modifié)"
                setattr(p, f, value)
        if "terms_text" in changed:
            p.terms_version += 1  # everyone accepts the new text at their next login
            changed["terms_version"] = p.terms_version
        p.save()
        if changed:
            audit.record("Réglages de la plateforme modifiés", actor=request.user, request=request, platform=True, detail=changed)
        messages.success(request, "Enregistré. L’application l’affiche dans Mon compte → Aide.")
        return redirect("backoffice:platform")
    return render(request, "backoffice/platform.html", {"nav": "platform", "p": p})
