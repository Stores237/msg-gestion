from django.db.models import Count
from django.shortcuts import get_object_or_404
from drf_spectacular.utils import extend_schema
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.accounts.models import User
from apps.accounts.permissions import require
from apps.core import audit

from .models import Announcement, Read
from .serializers import AnnouncementSerializer


def _audience():
    """Everyone an announcement goes to: active and on-leave members."""
    return User.objects.filter(status__in=[User.Status.ACTIVE, User.Status.LEAVE], is_active=True)


def _context(request, items):
    read_ids = set(Read.objects.filter(member=request.user, announcement__in=items).values_list("announcement_id", flat=True))
    return {"read_ids": read_ids, "viewer": request.user, "audience": _audience().count()}


class AnnouncementListView(APIView):
    """GET ?filter=all|convocations|unread|sent ; POST to publish."""

    def get_permissions(self):
        return [require("announcements.posts", "create" if self.request.method == "POST" else "view")()]

    @extend_schema(responses=AnnouncementSerializer(many=True))
    def get(self, request):
        # Explicit order_by: Django drops Meta.ordering from GROUP BY queries,
        # and annotate(Count) makes this one.
        qs = Announcement.objects.select_related("author", "event").annotate(read_count=Count("reads")).order_by("-pinned", "-created_at")
        f = request.query_params.get("filter", "all")
        if f == "convocations":
            qs = qs.filter(kind=Announcement.Kind.CONVOCATION)
        elif f == "sent":
            qs = qs.filter(author=request.user)
        elif f == "unread":
            qs = qs.exclude(reads__member=request.user)
        items = list(qs[:100])
        unread = Announcement.objects.exclude(reads__member=request.user).count()
        return Response({"unread": unread, "results": AnnouncementSerializer(items, many=True, context=_context(request, items)).data})

    @extend_schema(request=AnnouncementSerializer, responses=AnnouncementSerializer)
    def post(self, request):
        s = AnnouncementSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        item = s.save(author=request.user)
        Read.objects.create(announcement=item, member=request.user)  # the author has read it
        audit.record("Convocation envoyée" if item.kind == Announcement.Kind.CONVOCATION else "Annonce publiée",
                     actor=request.user, obj=item, request=request, detail={"destinataires": _audience().count()})
        return Response(AnnouncementSerializer(item, context=_context(request, [item])).data, status=status.HTTP_201_CREATED)


class AnnouncementDetailView(APIView):
    def get_permissions(self):
        return [require("announcements.posts", "delete" if self.request.method == "DELETE" else "view")()]

    def get(self, request, pk):
        item = get_object_or_404(Announcement.objects.select_related("author", "event"), pk=pk)
        return Response(AnnouncementSerializer(item, context=_context(request, [item])).data)

    def delete(self, request, pk):
        item = get_object_or_404(Announcement, pk=pk)
        audit.record("Annonce supprimée", actor=request.user, obj=item, request=request)
        item.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class MarkReadView(APIView):
    permission_classes = [require("announcements.posts", "view")]

    def post(self, request, pk):
        item = get_object_or_404(Announcement, pk=pk)
        Read.objects.get_or_create(announcement=item, member=request.user)
        return Response(status=status.HTTP_204_NO_CONTENT)


class ReadReceiptsView(APIView):
    """Who has / hasn't read it — the author, or anyone who manages
    announcements (design: "Accusés de lecture")."""

    permission_classes = [require("announcements.posts", "view")]

    def get(self, request, pk):
        item = get_object_or_404(Announcement, pk=pk)
        if not (item.author_id == request.user.pk or request.user.can("announcements.posts", "change")):
            return Response({"detail": "Réservé à l’expéditeur.", "code": "author_only"}, status=403)
        read_ids = set(item.reads.values_list("member_id", flat=True))
        rows = [{"member": m.pk, "full_name": m.full_name, "read": m.pk in read_ids} for m in _audience().order_by("last_name", "first_name")]
        return Response({"read": sum(r["read"] for r in rows), "total": len(rows), "rows": rows})
