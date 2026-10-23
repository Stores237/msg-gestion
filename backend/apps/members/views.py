

from django.db.models import Count, F, Q
from django.shortcuts import get_object_or_404
from django.utils import timezone
from django.utils.dateparse import parse_date
from drf_spectacular.utils import extend_schema
from rest_framework import status
from rest_framework.parsers import MultiPartParser
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.accounts.models import Role, RoleAssignment, User
from apps.accounts.permissions import require
from apps.accounts.services import reset_pin
from apps.core import audit

from . import services as access
from .models import AccessRequest
from .serializers import (
    AccessRequestCreateSerializer,
    AccessRequestSerializer,
    BureauEntrySerializer,
    MemberDetailSerializer,
    MemberListSerializer,
)

VISIBLE = ~Q(gstatus=User.Status.ARCHIVED)  # status in the current group (members())
STATUS_FILTERS = {"actif", "conge", "classe", "suspendu"}


def _members():
    return User.objects.members().filter(VISIBLE).prefetch_related("assignments__role")


class MemberListView(APIView):
    """GET: the member list with the counts for the filter chips.
    POST: gone — see AccessRequestListView."""

    def get_permissions(self):
        action = "create" if self.request.method == "POST" else "view"
        return [require("members.profile", action)()]

    @extend_schema(responses=MemberListSerializer(many=True))
    def get(self, request):
        base = User.objects.members().filter(VISIBLE)
        counts = base.aggregate(
            all=Count("id"),
            actif=Count("id", filter=Q(gstatus=User.Status.ACTIVE)),
            conge=Count("id", filter=Q(gstatus=User.Status.LEAVE)),
            classe=Count("id", filter=Q(gstatus=User.Status.RETIRED)),
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
            qs = qs.filter(gstatus=st)
        if request.query_params.get("diaspora") in ("1", "true"):
            qs = qs.filter(is_diaspora=True)
        data = MemberListSerializer(qs, many=True, context={"today": timezone.localdate(), "request": request}).data
        return Response({"counts": counts, "results": data})

    @extend_schema(responses={410: None})
    def post(self, request):
        # Accounts are now opened by the platform's partner, on the group
        # leader's request (AccessRequestListView).
        return Response({"detail": "Les nouveaux membres passent par une demande d’accès. Mettez l’application à jour.",
                         "code": "use_access_request"}, status=status.HTTP_410_GONE)


class MemberDetailView(APIView):
    permission_classes = [require("members.profile", "view")]

    @extend_schema(responses=MemberDetailSerializer)
    def get(self, request, pk):
        user = get_object_or_404(_members(), pk=pk)
        return Response(MemberDetailSerializer(user, context={"today": timezone.localdate(), "viewer": request.user, "request": request}).data)


class BureauView(APIView):
    """Everyone currently holding a bureau (mandate) role."""

    permission_classes = [require("members.profile", "view")]

    @extend_schema(responses=BureauEntrySerializer(many=True))
    def get(self, request):
        rows = (
            RoleAssignment.objects.active()
            .filter(role__kind=Role.Kind.BUREAU)
            .exclude(ends_on=F("starts_on"))  # roles of the day aren't the bureau
            .select_related("role", "user")
            .prefetch_related("user__assignments__role")
            .order_by("role__sort_order", "user__last_name")
        )
        data = [{"member": a.user, "role": a.role, "ends_on": a.ends_on} for a in rows]
        return Response(BureauEntrySerializer(data, many=True, context={"today": timezone.localdate(), "request": request}).data)


class ResetPinView(APIView):
    """The secretary gives a member a new temporary PIN (shown once)."""

    permission_classes = [require("members.profile", "change")]

    def post(self, request, pk):
        member = get_object_or_404(User.objects.members().filter(VISIBLE), pk=pk)
        return Response({"temporary_pin": reset_pin(member, by=request.user, request=request)})


REQUESTABLE_KINDS = ["temporaire", "standard"]


class RoleRequestView(APIView):
    """A bureau member proposes a role for someone; the super admin decides
    in the back-office (design: dashboard → "Demandes de rôle")."""

    def post(self, request, pk):
        from apps.accounts.models import RoleRequest

        u = request.user
        if not (u.can("members.profile", "change") or u.can("calendar.planning", "change")):
            return Response({"detail": "Votre rôle ne donne pas accès à cette action.", "code": "forbidden"}, status=403)
        member = get_object_or_404(User.objects.members().filter(VISIBLE), pk=pk)
        role = Role.objects.filter(slug=request.data.get("role"), kind__in=REQUESTABLE_KINDS, is_archived=False).first()
        if role is None or role.slug == "membre":
            return Response({"detail": "Ce rôle ne se demande pas ainsi.", "code": "bad_role"}, status=400)
        reason = (request.data.get("reason") or "").strip()
        if not reason:
            return Response({"detail": "Le motif est obligatoire.", "code": "reason_required"}, status=400)
        starts = parse_date(str(request.data.get("starts_on") or "")) or timezone.localdate()
        ends = parse_date(str(request.data.get("ends_on") or "")) if request.data.get("ends_on") else None
        rr = RoleRequest.objects.create(member=member, role=role, starts_on=starts, ends_on=ends, reason=reason, requested_by=u)
        audit.record("Demande de rôle", actor=u, obj=member, request=request, detail={"role": role.name, "motif": reason})
        return Response({"id": rr.pk, "status": rr.status}, status=201)


class RequestableRolesView(APIView):
    def get(self, request):
        return Response([{"slug": r.slug, "name": r.name, "kind": r.kind}
                         for r in Role.objects.filter(kind__in=REQUESTABLE_KINDS, is_archived=False).exclude(slug="membre")])


class PhotoView(APIView):
    """POST multipart `photo` (JPEG/PNG ≤ 5 MB) — design: "Ajouter une photo"."""

    permission_classes = [require("members.profile", "change")]
    parser_classes = [MultiPartParser]

    def post(self, request, pk):
        from apps.announcements.files import sniff

        member = get_object_or_404(User.objects.members().filter(VISIBLE), pk=pk)
        upload = request.FILES.get("photo")
        if upload is None:
            return Response({"detail": "Aucune photo.", "code": "no_file"}, status=400)
        if upload.size > 5 * 1024 * 1024:
            return Response({"detail": "Photo trop lourde (5 Mo maximum).", "code": "file_too_large"}, status=400)
        if sniff(upload) not in ("image/jpeg", "image/png"):
            return Response({"detail": "JPEG ou PNG uniquement.", "code": "file_type"}, status=400)
        if member.photo:
            member.photo.delete(save=False)
        member.photo.save(f"{member.pk}-{upload.name.rsplit('/', 1)[-1]}", upload, save=True)
        audit.record("Photo modifiée", actor=request.user, obj=member, request=request)
        return Response({"photo": _photo_url(request, member)})


def _photo_url(request, member):
    if not member.photo:
        return None
    url = member.photo.url
    return request.build_absolute_uri(url) if url.startswith("/") else url


class AccessRequestListView(APIView):
    """The group leader's access requests (owner, 2026-10-23): GET the
    group's requests, POST a new one for the partner to process."""

    permission_classes = [require("members.profile", "create")]

    @extend_schema(responses=AccessRequestSerializer(many=True))
    def get(self, request):
        items = AccessRequest.objects.select_related("role")[:50]
        return Response(AccessRequestSerializer(items, many=True).data)

    @extend_schema(request=AccessRequestCreateSerializer, responses=AccessRequestSerializer)
    def post(self, request):
        s = AccessRequestCreateSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        data = dict(s.validated_data)
        data.pop("joined_on", None)
        req = access.submit(by=request.user, request=request, **data)
        return Response(AccessRequestSerializer(req).data, status=status.HTTP_201_CREATED)


class AccessRequestPinView(APIView):
    """POST: the temporary PIN of an approved request, shown once to the
    leader who hands it over; erased afterwards."""

    permission_classes = [require("members.profile", "create")]

    def post(self, request, pk):
        req = get_object_or_404(AccessRequest, pk=pk, status=AccessRequest.Status.APPROVED)
        pin = access.reveal(req, by=request.user, request=request)
        if pin is None:
            return Response({"detail": "Code déjà remis ou expiré. Demandez une réinitialisation au partenaire.", "code": "pin_gone"},
                            status=status.HTTP_410_GONE)
        return Response({"full_name": req.user.full_name, "phone": req.user.phone, "pin": pin})
