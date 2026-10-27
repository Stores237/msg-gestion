from datetime import datetime, time, timedelta

from django.db import transaction
from django.shortcuts import get_object_or_404
from django.utils import timezone
from django.utils.dateparse import parse_date
from drf_spectacular.utils import extend_schema
from rest_framework import status
from rest_framework.parsers import FormParser, JSONParser, MultiPartParser
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.accounts.models import User
from apps.accounts.permissions import require
from apps.core import audit

from . import reports
from .models import Attendance, Event
from .serializers import AttendanceSheetSerializer, EventReportSerializer, EventSerializer, ExcuseSerializer

EVENT_RELATED = ("created_by", "chef", "report")

METHOD_ACTION = {"GET": "view", "POST": "create", "PATCH": "change", "DELETE": "delete"}


def _mine(user, events):
    return dict(Attendance.objects.filter(member=user, event__in=events).values_list("event_id", "status"))


def _day_start(d):
    return timezone.make_aware(datetime.combine(d, time.min))


class EventListView(APIView):
    """GET ?from=YYYY-MM-DD&to=YYYY-MM-DD (default: today → +60 days)."""

    def get_permissions(self):
        return [require("calendar.events", METHOD_ACTION[self.request.method])()]

    @extend_schema(responses=EventSerializer(many=True))
    def get(self, request):
        today = timezone.localdate()
        start = parse_date(request.query_params.get("from", "")) or today
        end = parse_date(request.query_params.get("to", "")) or start + timedelta(days=60)
        if end < start or (end - start).days > 400:
            return Response({"detail": "Période invalide.", "code": "bad_range"}, status=400)
        events = list(Event.objects.select_related(*EVENT_RELATED).filter(starts_at__gte=_day_start(start), starts_at__lt=_day_start(end + timedelta(days=1))))
        return Response(EventSerializer(events, many=True, context={"mine": _mine(request.user, events), "viewer": request.user}).data)

    @extend_schema(request=EventSerializer, responses=EventSerializer)
    def post(self, request):
        s = EventSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        event = s.save(created_by=request.user, created_by_role=request.user.display_role())
        audit.record("Événement créé", actor=request.user, obj=event, request=request,
                     detail={"chef": event.chef.short_name} if event.chef else None)
        reports.tell_chef(event)
        return Response(EventSerializer(event, context={"viewer": request.user}).data, status=status.HTTP_201_CREATED)


class EventDetailView(APIView):
    """GET; PATCH and DELETE by whoever added the event, or with the
    calendar's change / delete rights (owner, 2026-10-26)."""

    permission_classes = [require("calendar.events", "view")]

    @extend_schema(responses=EventSerializer)
    def get(self, request, pk):
        event = get_object_or_404(Event.objects.select_related(*EVENT_RELATED), pk=pk)
        body = dict(EventSerializer(event, context={"mine": _mine(request.user, [event]), "viewer": request.user}).data)
        if request.user.can("calendar.attendance", "view"):
            counts = {s: 0 for s in Attendance.Status.values}
            for st in event.attendance.values_list("status", flat=True):
                counts[st] += 1
            body["attendance_counts"] = counts
        return Response(body)

    @extend_schema(request=EventSerializer, responses=EventSerializer)
    def patch(self, request, pk):
        event = get_object_or_404(Event, pk=pk)
        if not (event.created_by_id == request.user.pk or request.user.can("calendar.events", "change")):
            return Response({"detail": "Seul l’auteur peut modifier cet événement.", "code": "author_only"}, status=403)
        previous_chef = event.chef_id
        s = EventSerializer(event, data=request.data, partial=True, context={"viewer": request.user})
        s.is_valid(raise_exception=True)
        s.save()
        audit.record("Événement modifié", actor=request.user, obj=event, request=request, detail={"champs": sorted(request.data)})
        if event.chef_id and event.chef_id != previous_chef:
            reports.tell_chef(event)
        return Response(EventSerializer(event, context={"viewer": request.user}).data)

    def delete(self, request, pk):
        event = get_object_or_404(Event, pk=pk)
        if not (event.created_by_id == request.user.pk or request.user.can("calendar.events", "delete")):
            return Response({"detail": "Seul l’auteur peut supprimer cet événement.", "code": "author_only"}, status=403)
        audit.record("Événement supprimé", actor=request.user, obj=event, request=request, detail={"titre": event.title})
        event.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class EventReportView(APIView):
    """GET the chef de groupe's report (the chef, and the roles that read
    reports); POST it, multipart `body` and/or `file` (PDF ≤ 10 MB), by the
    chef within 24 h of the event's end (owner, 2026-10-27)."""

    permission_classes = [require("calendar.events", "view")]
    parser_classes = [MultiPartParser, FormParser, JSONParser]

    def _event(self, pk):
        return get_object_or_404(Event.objects.select_related(*EVENT_RELATED), pk=pk)

    @extend_schema(responses=EventReportSerializer)
    def get(self, request, pk):
        event = self._event(pk)
        if not reports.can_read(request.user, event):
            return Response({"detail": "Réservé au chef de groupe et aux destinataires du rapport.", "code": "report_forbidden"}, status=403)
        if reports.status(event) not in ("submitted", "late"):
            return Response({"detail": "Aucun rapport remis.", "code": "no_report"}, status=404)
        return Response(EventReportSerializer(event.report, context={"request": request}).data)

    def post(self, request, pk):
        from apps.announcements.files import MAX_BYTES, sniff

        event = self._event(pk)
        upload = request.FILES.get("file")
        if upload is not None:
            if upload.size > MAX_BYTES:
                return Response({"detail": "Fichier trop lourd (10 Mo maximum).", "code": "file_too_large"}, status=400)
            if sniff(upload) != "application/pdf":
                return Response({"detail": "Le rapport joint doit être un PDF.", "code": "file_type"}, status=400)
        try:
            report = reports.submit(event, by=request.user, body=request.data.get("body", ""), upload=upload, request=request)
        except reports.ReportRule as e:
            return Response({"detail": e.message, "code": e.code}, status=e.status)
        return Response(EventReportSerializer(report, context={"request": request}).data, status=status.HTTP_201_CREATED)


class AttendanceView(APIView):
    """The roll call (design: "Appel · présences"). GET the sheet, PUT the
    marks in one go — the censeur may have taken them offline."""

    def get_permissions(self):
        return [require("calendar.attendance", "change" if self.request.method == "PUT" else "view")()]

    def _sheet(self, event):
        marks = {a.member_id: a for a in event.attendance.all()}
        members = User.objects.members().filter(gstatus__in=[User.Status.ACTIVE, User.Status.LEAVE]).order_by("last_name", "first_name")
        rows = [
            {
                "member": m.pk,
                "full_name": m.full_name,
                "is_diaspora": m.is_diaspora,
                "status": marks[m.pk].status if m.pk in marks else "",
                "reason": marks[m.pk].reason if m.pk in marks else "",
            }
            for m in members
        ]
        counts = {s: sum(1 for r in rows if r["status"] == s) for s in Attendance.Status.values}
        counts["unmarked"] = sum(1 for r in rows if not r["status"])
        return {"counts": counts, "rows": rows}

    def get(self, request, pk):
        return Response(self._sheet(get_object_or_404(Event, pk=pk)))

    @extend_schema(request=AttendanceSheetSerializer)
    def put(self, request, pk):
        event = get_object_or_404(Event, pk=pk)
        s = AttendanceSheetSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        known = set(User.objects.members().filter(pk__in=[m["member"] for m in s.validated_data["marks"]]).values_list("pk", flat=True))
        with transaction.atomic():
            for mark in s.validated_data["marks"]:
                if mark["member"] not in known:
                    continue
                if not mark["status"]:
                    Attendance.objects.filter(event=event, member_id=mark["member"]).delete()
                    continue
                Attendance.objects.update_or_create(
                    event=event, member_id=mark["member"], defaults={"status": mark["status"], "marked_by": request.user}
                )
        audit.record("Appel enregistré", actor=request.user, obj=event, request=request, detail={"lignes": len(s.validated_data["marks"])})
        return Response(self._sheet(event))


class ExcuseView(APIView):
    """A member warns in advance they'll be absent (design: "Prévenir
    d'une absence"). Doesn't override a mark the censeur already took."""

    permission_classes = [require("calendar.events", "view")]

    @extend_schema(request=ExcuseSerializer)
    def post(self, request, pk):
        event = get_object_or_404(Event, pk=pk)
        s = ExcuseSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        existing = Attendance.objects.filter(event=event, member=request.user).first()
        if existing and existing.status != Attendance.Status.EXCUSED:
            return Response({"detail": "La présence est déjà marquée par le censeur.", "code": "already_marked"}, status=409)
        Attendance.objects.update_or_create(
            event=event, member=request.user,
            defaults={"status": Attendance.Status.EXCUSED, "reason": s.validated_data["reason"], "marked_by": request.user},
        )
        return Response({"my_attendance": Attendance.Status.EXCUSED})
