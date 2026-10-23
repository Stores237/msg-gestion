"""Access requests from the groups' leaders (back-office → Demandes
d'accès): the partner opens the account or refuses, with a reason."""

from django.contrib import messages
from django.shortcuts import get_object_or_404, redirect, render
from django.views.decorators.http import require_POST

from apps.accounts.services import RuleViolation
from apps.members import services as access
from apps.members.models import AccessRequest

from .access import backoffice_view


@backoffice_view("backoffice.users", "view")
def access_requests(request):
    pending = AccessRequest.objects.filter(status=AccessRequest.Status.PENDING).select_related("role", "requested_by")
    done = AccessRequest.objects.exclude(status=AccessRequest.Status.PENDING).select_related("role", "requested_by", "decided_by")[:30]
    return render(request, "backoffice/access_requests.html", {
        "nav": "access", "pending": pending, "done": done, "can_edit": request.user.can("backoffice.users", "create"),
    })


@require_POST
@backoffice_view("backoffice.users", "create")
def access_request_decide(request, pk):
    req = get_object_or_404(AccessRequest, pk=pk)
    try:
        if request.POST.get("approve"):
            access.approve(req, by=request.user, request=request)
            messages.success(request, f"Accès créé pour {req.full_name}. "
                             + ("Le code provisoire attend le responsable dans l’application." if req.temp_pin
                                else "Ce numéro avait déjà un compte : il est ajouté au groupe."))
        else:
            access.refuse(req, by=request.user, reason=request.POST.get("reason", ""), request=request)
            messages.success(request, "Demande refusée ; le responsable est prévenu.")
    except RuleViolation as e:
        messages.error(request, str(e))
    return redirect("backoffice:access_requests")
