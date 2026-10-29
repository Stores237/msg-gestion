from django.db.models import Count
from django.shortcuts import get_object_or_404
from drf_spectacular.utils import extend_schema
from rest_framework import status
from rest_framework.parsers import MultiPartParser
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.accounts.models import User
from apps.accounts.permissions import require
from apps.core import audit
from apps.core.notify import notify

from .files import MAX_BYTES, PHOTOS_PER_ANNOUNCEMENT, photo_problem, sniff
from .models import Announcement, Attachment, Read
from .serializers import AnnouncementSerializer, AttachmentSerializer


def _audience():
    """Everyone an announcement goes to: active and on-leave members."""
    return User.objects.members().filter(gstatus__in=[User.Status.ACTIVE, User.Status.LEAVE], is_active=True)


def _notify_new(item, users):
    """Tells [users] about a new announcement or convocation: everyone, or
    only the members it is for."""
    conv = item.kind == Announcement.Kind.CONVOCATION
    kind = "convocation" if conv else "announcement"
    target = {"type": "announcement", "id": item.pk}
    if item.tagged.exists():
        # Its own title, with a small "Pour vous" mark in the app (owner, 2026-10-29).
        body = " ".join(item.body.split()) or ("Convocation" if conv else "Annonce")
        return notify(users, kind, item.title, body, target | {"for_me": True})
    title = "Nouvelle convocation" if conv else "Nouvelle annonce"
    return notify(users, kind, title, item.title, target)


def _context(request, items):
    read_ids = set(Read.objects.filter(member=request.user, announcement__in=items).values_list("announcement_id", flat=True))
    return {"read_ids": read_ids, "viewer": request.user, "audience": _audience().count(), "request": request}


class AnnouncementListView(APIView):
    """GET ?filter=all|convocations|unread|sent ; POST to publish."""

    def get_permissions(self):
        return [require("announcements.posts", "create" if self.request.method == "POST" else "view")()]

    @extend_schema(responses=AnnouncementSerializer(many=True))
    def get(self, request):
        # Explicit order_by: Django drops Meta.ordering from GROUP BY queries,
        # and annotate(Count) makes this one.
        qs = (
            Announcement.objects.select_related("author", "event")
            .prefetch_related("attachments", "tagged")
            .annotate(read_count=Count("reads"))
            .order_by("-pinned", "-created_at")
        )
        f = request.query_params.get("filter", "all")
        if f == "convocations":
            qs = qs.filter(kind=Announcement.Kind.CONVOCATION)
        elif f == "sent":
            qs = qs.filter(author=request.user)
        elif f == "unread":
            qs = qs.exclude(reads__member=request.user)
        elif f == "for_me":
            qs = qs.filter(tagged=request.user)
        items = list(qs[:100])
        unread = Announcement.objects.exclude(reads__member=request.user).count()
        return Response({"unread": unread, "results": AnnouncementSerializer(items, many=True, context=_context(request, items)).data})

    @extend_schema(request=AnnouncementSerializer, responses=AnnouncementSerializer)
    def post(self, request):
        s = AnnouncementSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        item = s.save(author=request.user, author_role=request.user.display_role())
        Read.objects.create(announcement=item, member=request.user)  # the author has read it
        tagged = item.tagged.all()
        n = _notify_new(item, (tagged if tagged else _audience()).exclude(pk=request.user.pk))
        audit.record("Convocation envoyée" if item.kind == Announcement.Kind.CONVOCATION else "Annonce publiée",
                     actor=request.user, obj=item, request=request,
                     detail={"notifiés": n, **({"mentionnés": len(tagged)} if tagged else {})})
        return Response(AnnouncementSerializer(item, context=_context(request, [item])).data, status=status.HTTP_201_CREATED)


class AnnouncementDetailView(APIView):
    """GET; PATCH and DELETE by the author, or by someone who manages
    announcements (owner, 2026-10-26)."""

    permission_classes = [require("announcements.posts", "view")]

    def get(self, request, pk):
        item = get_object_or_404(Announcement.objects.select_related("author", "event").prefetch_related("tagged"), pk=pk)
        return Response(AnnouncementSerializer(item, context=_context(request, [item])).data)

    @extend_schema(request=AnnouncementSerializer, responses=AnnouncementSerializer)
    def patch(self, request, pk):
        item = get_object_or_404(Announcement.objects.select_related("author", "event"), pk=pk)
        if not (item.author_id == request.user.pk or request.user.can("announcements.posts", "change")):
            return Response({"detail": "Seul l’auteur peut modifier cette annonce.", "code": "author_only"}, status=403)
        data = {k: v for k, v in request.data.items() if k in ("title", "body", "kind", "event", "pinned", "tagged")}
        if "pinned" in data and not request.user.can("announcements.posts", "change"):
            data.pop("pinned")  # pinning stays with whoever manages announcements
        s = AnnouncementSerializer(item, data=data, partial=True, context=_context(request, [item]))
        s.is_valid(raise_exception=True)
        before = set(item.tagged.values_list("pk", flat=True))
        s.save()
        if "tagged" in data:
            # Members added afterwards are told; the others already were.
            _notify_new(item, item.tagged.exclude(pk__in=before | {request.user.pk}))
        audit.record("Annonce modifiée", actor=request.user, obj=item, request=request, detail={"champs": sorted(data)})
        return Response(AnnouncementSerializer(item, context=_context(request, [item])).data)

    def delete(self, request, pk):
        item = get_object_or_404(Announcement, pk=pk)
        if not (item.author_id == request.user.pk or request.user.can("announcements.posts", "delete")):
            return Response({"detail": "Seul l’auteur peut supprimer cette annonce.", "code": "author_only"}, status=403)
        audit.record("Annonce supprimée", actor=request.user, obj=item, request=request, detail={"titre": item.title})
        for att in item.attachments.all():
            att.file.delete(save=False)
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
        tagged = set(item.tagged.values_list("pk", flat=True))
        rows = [{"member": m.pk, "full_name": m.full_name, "read": m.pk in read_ids, "tagged": m.pk in tagged}
                for m in _audience().order_by("last_name", "first_name")]
        return Response({"read": sum(r["read"] for r in rows), "total": len(rows), "rows": rows})


def _may_edit(user, item):
    return item.author_id == user.pk or user.can("announcements.posts", "change")


class AttachmentUploadView(APIView):
    """POST multipart `file` to an announcement you wrote (or manage)."""

    permission_classes = [require("announcements.posts", "create")]
    parser_classes = [MultiPartParser]

    @extend_schema(request={"multipart/form-data": {"type": "object", "properties": {"file": {"type": "string", "format": "binary"}}}},
                   responses=AttachmentSerializer)
    def post(self, request, pk):
        item = get_object_or_404(Announcement, pk=pk)
        if not _may_edit(request.user, item):
            return Response({"detail": "Réservé à l’expéditeur.", "code": "author_only"}, status=403)
        upload = request.FILES.get("file")
        if upload is None:
            return Response({"detail": "Aucun fichier.", "code": "no_file"}, status=400)
        if upload.size > MAX_BYTES:
            return Response({"detail": "Fichier trop lourd (10 Mo maximum).", "code": "file_too_large"}, status=400)
        content_type = sniff(upload)
        if content_type is None:
            return Response({"detail": "Seuls les PDF, JPEG et PNG sont acceptés.", "code": "file_type"}, status=400)
        if content_type.startswith("image/"):
            # Photos keep one frame and size (owner, 2026-10-28).
            problem = photo_problem(upload)
            if problem:
                return Response({"detail": problem[1], "code": problem[0]}, status=400)
            if item.attachments.filter(content_type__startswith="image/").count() >= PHOTOS_PER_ANNOUNCEMENT:
                return Response({"detail": f"{PHOTOS_PER_ANNOUNCEMENT} photos maximum par annonce.", "code": "too_many_photos"}, status=400)
        name = (upload.name or "fichier").rsplit("/", 1)[-1][:160]
        att = Attachment.objects.create(announcement=item, file=upload, name=name, size=upload.size, content_type=content_type, uploaded_by=request.user)
        audit.record("Pièce jointe ajoutée", actor=request.user, obj=item, request=request, detail={"fichier": name})
        return Response(AttachmentSerializer(att, context={"request": request}).data, status=status.HTTP_201_CREATED)


class AttachmentDeleteView(APIView):
    permission_classes = [require("announcements.posts", "create")]

    def delete(self, request, pk, att_pk):
        att = get_object_or_404(Attachment.objects.select_related("announcement"), pk=att_pk, announcement_id=pk)
        if not _may_edit(request.user, att.announcement):
            return Response({"detail": "Réservé à l’expéditeur.", "code": "author_only"}, status=403)
        att.file.delete(save=False)
        att.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class RemindUnreadView(APIView):
    """"Relancer les non-lecteurs" (design: read receipts sheet)."""

    permission_classes = [require("announcements.posts", "view")]

    def post(self, request, pk):
        item = get_object_or_404(Announcement, pk=pk)
        if not _may_edit(request.user, item):
            return Response({"detail": "Réservé à l’expéditeur.", "code": "author_only"}, status=403)
        read_ids = item.reads.values_list("member_id", flat=True)
        # Only the members it is for, when it names some.
        who = item.tagged.all() if item.tagged.exists() else _audience()
        n = notify(who.exclude(pk__in=read_ids), "announcement", f"Rappel : {item.title}", "Merci de lire cette annonce.",
                   {"type": "announcement", "id": item.pk})
        audit.record("Relance des non-lecteurs", actor=request.user, obj=item, request=request, detail={"relancés": n})
        return Response({"reminded": n})


class RecipientsView(APIView):
    """Who an announcement can be for (active and on-leave members), for
    the author's "Notifier" picker. Needs only the right to post, not the
    member directory."""

    permission_classes = [require("announcements.posts", "create")]

    def get(self, request):
        people = _audience().exclude(pk=request.user.pk).order_by("last_name", "first_name")
        return Response([{"id": u.pk, "name": u.full_name, "status": u.gstatus} for u in people])
