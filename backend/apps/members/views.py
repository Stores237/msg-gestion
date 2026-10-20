

from django.db import transaction
from django.db.models import Count, Q
from django.shortcuts import get_object_or_404
from django.utils import timezone
from drf_spectacular.utils import extend_schema
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.accounts.models import Role, RoleAssignment, User
from apps.accounts.permissions import require
from apps.accounts.services import assign_role, reset_pin, temporary_pin
from apps.core import audit
from apps.core.notify import notify

from .serializers import BureauEntrySerializer, MemberCreateSerializer, MemberDetailSerializer, MemberListSerializer

VISIBLE = ~Q(status=User.Status.ARCHIVED)
STATUS_FILTERS = {"actif", "conge", "classe", "suspendu"}


def _members():
    return User.objects.filter(VISIBLE).prefetch_related("assignments__role")


class MemberListView(APIView):
    """GET: the member list with the counts for the filter chips.
    POST: register a new member (secrétaire général by default)."""

    def get_permissions(self):
        action = "create" if self.request.method == "POST" else "view"
        return [require("members.profile", action)()]

    @extend_schema(responses=MemberListSerializer(many=True))
    def get(self, request):
        base = User.objects.filter(VISIBLE)
        counts = base.aggregate(
            all=Count("id"),
            actif=Count("id", filter=Q(status=User.Status.ACTIVE)),
            conge=Count("id", filter=Q(status=User.Status.LEAVE)),
            classe=Count("id", filter=Q(status=User.Status.RETIRED)),
            diaspora=Count("id", filter=Q(is_diaspora=True)),
        )
        qs = _members()
        q = request.query_params.get("q", "").strip()
        if q:
            digits = "".join(ch for ch in q if ch.isdigit())
            match = Q(last_name__icontains=q) | Q(first_name__icontains=q)
            if len(digits) >= 3:
                match |= Q(phone__contains=digits)
            qs = qs.filter(match)
        st = request.query_params.get("status")
        if st in STATUS_FILTERS:
            qs = qs.filter(status=st)
        if request.query_params.get("diaspora") in ("1", "true"):
            qs = qs.filter(is_diaspora=True)
        data = MemberListSerializer(qs, many=True, context={"today": timezone.localdate()}).data
        return Response({"counts": counts, "results": data})

    @extend_schema(request=MemberCreateSerializer, responses=MemberDetailSerializer)
    def post(self, request):
        s = MemberCreateSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        pin = temporary_pin()
        with transaction.atomic():
            user = User(**s.validated_data)
            user.set_unusable_password()  # app only; back-office access is a separate step
            user.set_pin(pin, temporary=True)
            user.save()
            assign_role(user, Role.objects.get(slug="membre"), reason="Inscription", by=request.user, request=request)
        audit.record("Membre inscrit", actor=request.user, obj=user, request=request)
        bureau = [a.user for a in RoleAssignment.objects.active().filter(role__slug__in=["president", "secretaire-general"]).select_related("user")]
        notify([u for u in bureau if u.pk != request.user.pk], "member", "Nouveau membre",
               f"{user.full_name} a rejoint le mouvement", {"type": "member", "id": user.pk})
        user = _members().get(pk=user.pk)
        body = dict(MemberDetailSerializer(user, context={"today": timezone.localdate(), "viewer": request.user}).data)
        # Shown once to whoever registered the member, who passes it on in
        # person. Replaced by an SMS once Twilio is set up (TODOS.md).
        body["temporary_pin"] = pin
        return Response(body, status=status.HTTP_201_CREATED)


class MemberDetailView(APIView):
    permission_classes = [require("members.profile", "view")]

    @extend_schema(responses=MemberDetailSerializer)
    def get(self, request, pk):
        user = get_object_or_404(_members(), pk=pk)
        return Response(MemberDetailSerializer(user, context={"today": timezone.localdate(), "viewer": request.user}).data)


class BureauView(APIView):
    """Everyone currently holding a bureau (mandate) role."""

    permission_classes = [require("members.profile", "view")]

    @extend_schema(responses=BureauEntrySerializer(many=True))
    def get(self, request):
        rows = (
            RoleAssignment.objects.active()
            .filter(role__kind=Role.Kind.BUREAU)
            .select_related("role", "user")
            .prefetch_related("user__assignments__role")
            .order_by("role__sort_order", "user__last_name")
        )
        data = [{"member": a.user, "role": a.role, "ends_on": a.ends_on} for a in rows]
        return Response(BureauEntrySerializer(data, many=True, context={"today": timezone.localdate()}).data)


class ResetPinView(APIView):
    """The secretary gives a member a new temporary PIN (shown once)."""

    permission_classes = [require("members.profile", "change")]

    def post(self, request, pk):
        member = get_object_or_404(User.objects.filter(VISIBLE), pk=pk)
        return Response({"temporary_pin": reset_pin(member, by=request.user, request=request)})
