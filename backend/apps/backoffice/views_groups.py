"""The platform's groups (back-office → Groupes): list, create, switch."""

from django.contrib import messages
from django.db.models import Count, Q
from django.shortcuts import get_object_or_404, redirect, render
from django.utils.http import url_has_allowed_host_and_scheme
from django.views.decorators.http import require_POST

from apps.core.group_admin import create_group
from apps.core.models import Group

from .access import SESSION_GROUP, backoffice_view


@backoffice_view("backoffice.users", "view")
def groups(request):
    if request.method == "POST":
        if not request.user.can("backoffice.users", "create"):
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
    rows = Group.objects.annotate(n=Count("memberships", filter=Q(memberships__is_active=True))).order_by("name")
    return render(request, "backoffice/groups.html", {"nav": "groups", "rows": rows})


@require_POST
@backoffice_view("backoffice.users", "view")
def group_switch(request):
    g = get_object_or_404(Group, pk=request.POST.get("group"), is_active=True)
    request.session[SESSION_GROUP] = g.pk
    nxt = request.POST.get("next") or ""
    if not url_has_allowed_host_and_scheme(nxt, allowed_hosts={request.get_host()}):
        nxt = ""
    return redirect(nxt or "backoffice:dashboard")
