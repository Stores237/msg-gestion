"""The platform's groups (back-office → Groupes): list, create, edit,
delete (two super admins), switch."""

from django.contrib import messages
from django.db.models import Count, Q
from django.shortcuts import get_object_or_404, redirect, render
from django.utils import timezone
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


@backoffice_view("backoffice.platform", "view")
def faq(request):
    """Aide → Questions fréquentes (owner, 2026-11-02): the questions common
    to every group, the current group's own, and the members' suggestions,
    which the platform team edits and publishes or declines."""

    from apps.core.groups import in_group
    from apps.core.models import FaqEntry, FaqSuggestion
    from apps.core.notify import notify

    group = getattr(request, "group", None)
    if request.method == "POST":
        if not request.user.can("backoffice.platform", "change"):
            return render(request, "backoffice/forbidden.html", status=403)
        P = request.POST
        action = P.get("action")
        question, answer = P.get("question", "").strip()[:200], P.get("answer", "").strip().replace("\r\n", "\n")[:3000]
        scope_group = None if P.get("scope") == "common" else group
        if action in ("save", "publish") and (len(question) < 5 or not answer):
            messages.error(request, "Écrivez la question et sa réponse.")
            return redirect("backoffice:faq")
        if action == "save":
            entry = FaqEntry.objects.filter(pk=P.get("id")).first() if P.get("id") else None
            if entry is None:
                entry = FaqEntry(group=scope_group, position=FaqEntry.objects.filter(group=scope_group).count() * 10)
            entry.question, entry.answer, entry.updated_by = question, answer, request.user
            entry.save()
            audit.record("Question d’aide enregistrée", actor=request.user, obj=entry, request=request, platform=entry.group_id is None,
                         detail={"question": question})
            messages.success(request, "Question enregistrée : elle est dans l’application.")
        elif action == "delete":
            entry = get_object_or_404(FaqEntry, pk=P.get("id"))
            audit.record("Question d’aide supprimée", actor=request.user, obj=entry, request=request, platform=entry.group_id is None,
                         detail={"question": entry.question})
            entry.delete()
            messages.success(request, "Question supprimée.")
        elif action in ("publish", "decline"):
            s = get_object_or_404(FaqSuggestion, pk=P.get("id"), status=FaqSuggestion.Status.PENDING)
            s.decided_by, s.decided_at = request.user, timezone.now()
            if action == "publish":
                target = None if P.get("scope") == "common" else s.group
                s.entry = FaqEntry.objects.create(group=target, question=question, answer=answer, updated_by=request.user,
                                                  position=FaqEntry.objects.filter(group=target).count() * 10)
                s.status = FaqSuggestion.Status.PUBLISHED
                title, body = "Votre question est dans l’aide", f"« {question} » est publiée dans Aide → Questions fréquentes. Merci !"
            else:
                s.status, s.note = FaqSuggestion.Status.DECLINED, P.get("note", "").strip()[:300]
                title, body = "Votre question pour l’aide", f"« {s.question} » n’a pas été retenue." + (f" {s.note}" if s.note else "")
            s.save()
            audit.record("Suggestion d’aide " + ("publiée" if action == "publish" else "non retenue"), actor=request.user, obj=s,
                         request=request, platform=True)
            if s.author:
                with in_group(s.group):
                    notify([s.author], "faq", title, body, {"type": "faq"})
            messages.success(request, "Suggestion publiée." if action == "publish" else "Suggestion classée ; son auteur est prévenu.")
        return redirect("backoffice:faq")
    return render(request, "backoffice/faq.html", {
        "nav": "faq", "group": group,
        "common": FaqEntry.objects.filter(group__isnull=True),
        "own": FaqEntry.objects.filter(group=group) if group else [],
        "pending": FaqSuggestion.objects.filter(status=FaqSuggestion.Status.PENDING).select_related("group", "author"),
        "done": FaqSuggestion.objects.exclude(status=FaqSuggestion.Status.PENDING).select_related("group", "author", "decided_by")[:20],
    })


def _tree(network):
    """The network's groups as indented rows: umbrellas first, each followed
    by the groups attached to it."""
    groups = list(Group.objects.filter(network=network, is_active=True).select_related("parent"))
    kids = {}
    for g in groups:
        kids.setdefault(g.parent_id, []).append(g)
    ids = {g.pk for g in groups}
    roots = [g for g in groups if g.parent_id is None or g.parent_id not in ids]
    rows = []

    def walk(g, depth):
        g.depth, g.indent = depth, depth * 24
        rows.append(g)
        for c in sorted(kids.get(g.pk, []), key=lambda x: (-x.level, x.name)):
            walk(c, depth + 1)

    for r in sorted(roots, key=lambda x: (-x.level, x.name)):
        walk(r, 0)
    return rows


@backoffice_view("backoffice.groups", "view")
def networks(request):
    """Réseaux (owner, 2026-11-03): networks of groups in levels (paroisse →
    zone → diocèse…), umbrella groups' invitation codes, detaching."""
    from apps.core import network as net
    from apps.core.models import GroupInvitation, Network

    if request.method == "POST":
        if not request.user.can("backoffice.groups", "change"):
            return render(request, "backoffice/forbidden.html", status=403)
        P, action = request.POST, request.POST.get("action")
        group = Group.objects.filter(pk=P.get("group"), is_active=True).first() if P.get("group") else None
        try:
            if action == "network":
                n = Network.objects.filter(pk=P.get("id")).first() if P.get("id") else None
                n = net.save_network(by=request.user, request=request, network=n, name=P.get("name"),
                                     levels=[P.get(f"level{i}", "") for i in range(1, 5)])
                messages.success(request, f"Réseau « {n.name} » enregistré.")
            elif action == "place" and group is not None:
                n = Network.objects.filter(pk=P.get("network")).first() if P.get("network") else None
                net.place_group(group, network=n, level=P.get("level") or 1, by=request.user, request=request)
                messages.success(request, f"« {group.name} » : {n.name + ' · ' + group.level_name if n else 'hors réseau'}.")
            elif action == "invite" and group is not None:
                inv = net.create_invitation(group, by=request.user, request=request, platform=True)
                messages.success(request, f"Code d’invitation pour rejoindre « {group.name} » : {inv.pretty} "
                                          f"(valable {net.INVITATION_DAYS} jours, une seule fois). Le président du groupe invité "
                                          "le saisit dans l’application : Accueil → le nom du groupe → Réseau.")
            elif action == "revoke":
                inv = get_object_or_404(GroupInvitation, pk=P.get("id"))
                net.revoke_invitation(inv, by=request.user, request=request, platform=True)
                messages.success(request, "Invitation annulée : le code ne marche plus.")
            elif action == "detach" and group is not None:
                parent = net.detach(group, by=request.user, reason=P.get("reason"), request=request, platform=True)
                messages.success(request, f"« {group.name} » n’est plus rattaché à « {parent.name} ». Les deux présidents sont prévenus.")
        except net.NetworkRule as e:
            audit.record("Réseau : modification refusée", actor=request.user, obj=group, request=request, platform=True,
                         refused=True, detail={"action": action, "raison": e.message})
            messages.error(request, e.message)
        return redirect("backoffice:networks")
    nets = list(Network.objects.all())
    for n in nets:
        n.rows = _tree(n)
        n.levels = [(i, n.level_name(i)) for i in Network.LEVELS if n.level_name(i)]
    pending = {}
    for inv in GroupInvitation.objects.filter(status=GroupInvitation.Status.PENDING).select_related("created_by"):
        if not inv.expires_at or inv.expires_at > timezone.now():
            pending.setdefault(inv.umbrella_id, []).append(inv)
    from apps.core.sharing import LABELS, LEVEL_LABELS, settings_of

    for n in nets:
        for g in n.rows:
            g.invites = pending.get(g.pk, [])
            g.share_text = ", ".join(f"{LABELS[k]} : {LEVEL_LABELS[v].lower()}" for k, v in settings_of(g).items() if v != "none")
    return render(request, "backoffice/networks.html", {
        "nav": "networks", "networks": nets,
        "outside": Group.objects.filter(network__isnull=True, is_active=True).order_by("name"),
        "all_groups": Group.objects.filter(is_active=True).select_related("network").order_by("name"),
        "days": net.INVITATION_DAYS,
    })
