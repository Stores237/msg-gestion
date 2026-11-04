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

from . import lineup, reports
from .models import Attendance, Event
from .serializers import AttendanceSheetSerializer, EventReportSerializer, EventSerializer, ExcuseSerializer

EVENT_RELATED = ("created_by", "chef", "report__read_by")

ENDED = {"detail": "Cet événement est passé : il ne peut plus être modifié. Seul l’appel reste possible.", "code": "event_ended"}

METHOD_ACTION = {"GET": "view", "POST": "create", "PATCH": "change", "DELETE": "delete"}


def _mine(user, events):
    return dict(Attendance.objects.filter(member=user, event__in=events).values_list("event_id", "status"))


def _context(user, events):
    with_lineup, duties = lineup.viewer_duties(user, events)
    return {"mine": _mine(user, events), "viewer": user, "lineups": with_lineup, "duties": duties}


def _visible(viewer=None):
    """This group's events and those other groups sent it (builds 41, 48)."""
    from apps.core.groups import current_group_id
    from apps.core.network import visible

    return visible(Event, current_group_id(), viewer=viewer).prefetch_related("reach")


def _tell_reached(event, before):
    """The people of the groups an event newly reaches (builds 41, 48)."""
    from apps.core.groups import in_group
    from apps.core.network import reach_people, reached
    from apps.core.notify import notify

    if not event.cascade:
        return 0
    when = timezone.localtime(event.starts_at).strftime("%d/%m à %H:%M")
    n = 0
    for g in reached(event):
        if g.pk not in before:
            people = reach_people(g, event.reach_audience)
            with in_group(g):
                n += notify(people, "duty", f"Événement de {event.group.name}",
                            f"{event.title} · {when}", {"type": "event", "id": event.pk})
    return n


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
        events = list(_visible(request.user).select_related(*EVENT_RELATED, "group").filter(starts_at__gte=_day_start(start), starts_at__lt=_day_start(end + timedelta(days=1))))
        return Response(EventSerializer(events, many=True, context=_context(request.user, events)).data)

    @extend_schema(request=EventSerializer, responses=EventSerializer)
    def post(self, request):
        s = EventSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        event = s.save(created_by=request.user, created_by_role=request.user.display_role())
        audit.record("Événement créé", actor=request.user, obj=event, request=request,
                     detail={"chef": event.chef.short_name} if event.chef else None)
        reports.tell_chef(event)
        _tell_reached(event, [])
        return Response(EventSerializer(event, context={"viewer": request.user, "request": request}).data, status=status.HTTP_201_CREATED)


class EventDetailView(APIView):
    """GET; PATCH and DELETE by whoever added the event, or with the
    calendar's change / delete rights (owner, 2026-10-26)."""

    permission_classes = [require("calendar.events", "view")]

    @extend_schema(responses=EventSerializer)
    def get(self, request, pk):
        event = get_object_or_404(_visible(request.user).select_related(*EVENT_RELATED, "group"), pk=pk)
        body = dict(EventSerializer(event, context=_context(request.user, [event])).data)
        if request.user.can("calendar.attendance", "view") and body.get("from_group") is None:
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
        if event.has_ended():
            return Response(ENDED, status=409)
        previous_chef = event.chef_id
        from apps.core.network import reached

        before = {g.pk for g in reached(event)}
        s = EventSerializer(event, data=request.data, partial=True, context={"viewer": request.user})
        s.is_valid(raise_exception=True)
        s.save()
        _tell_reached(event, before)
        audit.record("Événement modifié", actor=request.user, obj=event, request=request, detail={"champs": sorted(request.data)})
        if event.chef_id and event.chef_id != previous_chef:
            reports.tell_chef(event)
        return Response(EventSerializer(event, context={"viewer": request.user}).data)

    def delete(self, request, pk):
        event = get_object_or_404(Event, pk=pk)
        if not (event.created_by_id == request.user.pk or request.user.can("calendar.events", "delete")):
            return Response({"detail": "Seul l’auteur peut supprimer cet événement.", "code": "author_only"}, status=403)
        if event.has_ended():
            return Response(ENDED, status=409)
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
        reports.mark_read(event, request.user, request)
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
        duties = lineup.lineup(event)
        if duties is None:
            members = User.objects.members().filter(gstatus__in=[User.Status.ACTIVE, User.Status.LEAVE]).order_by("last_name", "first_name")
        else:
            # Only the guards lined up for it, in lineup order (chef first).
            by_id = {m.pk: m for m in User.objects.members().filter(pk__in=duties)}
            members = [by_id[i] for i in duties if i in by_id]
        rows = [
            {
                "member": m.pk,
                "full_name": m.full_name,
                "is_diaspora": m.is_diaspora,
                "status": marks[m.pk].status if m.pk in marks else "",
                "reason": marks[m.pk].reason if m.pk in marks else "",
                "duty": duties.get(m.pk) if duties is not None else None,
            }
            for m in members
        ]
        counts = {s: sum(1 for r in rows if r["status"] == s) for s in Attendance.Status.values}
        counts["unmarked"] = sum(1 for r in rows if not r["status"])
        return {"counts": counts, "rows": rows, "lineup": duties is not None}

    def get(self, request, pk):
        return Response(self._sheet(get_object_or_404(Event, pk=pk)))

    @extend_schema(request=AttendanceSheetSerializer)
    def put(self, request, pk):
        event = get_object_or_404(Event, pk=pk)
        s = AttendanceSheetSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        known = set(User.objects.members().filter(pk__in=[m["member"] for m in s.validated_data["marks"]]).values_list("pk", flat=True))
        duties = lineup.lineup(event)
        if duties is not None:
            known &= set(duties)  # only the guards lined up for it
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
        _absence_alerts(event, [m["member"] for m in s.validated_data["marks"] if m["status"] == Attendance.Status.ABSENT and m["member"] in known])
        return Response(self._sheet(event))


def _absence_alerts(event, absent_ids):
    """Settings.absence_alert (owner, 2026-11-02): the Nth unexcused absence
    in 90 days tells the member and those who keep the roll call, once."""
    from apps.accounts.models import RoleAssignment
    from apps.core.models import Settings
    from apps.core.notify import notify

    limit = Settings.get().absence_alert
    if not limit or not absent_ids:
        return
    since = timezone.now() - timedelta(days=90)
    keepers = None
    for member in User.objects.members().filter(pk__in=absent_ids):
        n = Attendance.objects.filter(member=member, status=Attendance.Status.ABSENT, event__starts_at__gte=since).count()
        if n != limit:
            continue
        if keepers is None:
            ids = RoleAssignment.objects.active().filter(
                role__permissions__resource="calendar.attendance", role__permissions__action="change").values("user")
            keepers = list(User.objects.members().filter(pk__in=ids, is_active=True))
        notify([member], "member", "Absences", f"{n} absences en 90 jours (dernière : {event.title}). Prévenez quand vous ne pouvez pas venir.",
               {"type": "event", "id": event.pk})
        notify([k for k in keepers if k.pk != member.pk], "member", "Absences répétées",
               f"{member.short_name} : {n} absences en 90 jours (dernière : {event.title}).", {"type": "member", "id": member.pk})


class ExcuseView(APIView):
    """A member warns in advance they'll be absent (design: "Prévenir
    d'une absence"). Doesn't override a mark the censeur already took."""

    permission_classes = [require("calendar.events", "view")]

    @extend_schema(request=ExcuseSerializer)
    def post(self, request, pk):
        event = get_object_or_404(Event, pk=pk)
        if event.has_ended():
            return Response(ENDED, status=409)
        s = ExcuseSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        duties = lineup.lineup(event)
        if duties is not None and request.user.pk not in duties:
            return Response({"detail": "Vous n’êtes pas de service pour cet événement.", "code": "not_on_duty"}, status=409)
        existing = Attendance.objects.filter(event=event, member=request.user).first()
        if existing and existing.status != Attendance.Status.EXCUSED:
            return Response({"detail": "La présence est déjà marquée par le censeur.", "code": "already_marked"}, status=409)
        Attendance.objects.update_or_create(
            event=event, member=request.user,
            defaults={"status": Attendance.Status.EXCUSED, "reason": s.validated_data["reason"], "marked_by": request.user},
        )
        return Response({"my_attendance": Attendance.Status.EXCUSED})


def _people(qs):
    return [{"id": u.pk, "name": u.short_name} for u in sorted(qs, key=lambda u: (u.last_name, u.first_name))]


class ContingentsView(APIView):
    """The asking side (owner, 2026-11-03): GET how many people each group
    below is asked for and whom it named; PUT {"requests": [{"group",
    "requested", "note"}]} (calendar.planning change)."""

    permission_classes = [require("calendar.events", "view")]

    def _body(self, request, event):
        from apps.core.identity import group_identity

        from .contingents import contingents_of

        rows = []
        for r in contingents_of(event):
            c = r["contingent"]
            rows.append({"group": group_identity(r["group"], request), "requested": c.requested if c else 0,
                         "note": c.note if c else "", "members": _people(c.members.all()) if c else [],
                         "answered_at": c.answered_at.isoformat() if c and c.answered_at else None})
        return {"groups": rows, "can_plan": request.user.can("calendar.planning", "change") and not event.has_ended(),
                "sent_down": event.cascade}

    def get(self, request, pk):
        event = get_object_or_404(Event, pk=pk)
        return Response(self._body(request, event))

    def put(self, request, pk):
        from .contingents import ContingentRule, set_requests

        event = get_object_or_404(Event, pk=pk)
        if not request.user.can("calendar.planning", "change"):
            return Response({"detail": "Réservé à ceux qui font le planning.", "code": "forbidden"}, status=403)
        try:
            set_requests(event, request.data.get("requests"), by=request.user, request=request)
        except ContingentRule as e:
            return Response({"detail": e.message, "code": e.code}, status=e.status)
        return Response(self._body(request, event))


class MyContingentView(APIView):
    """The asked side: GET what the group above asks of this group for its
    event; PUT {"members": [ids]} (calendar.planning change here)."""

    permission_classes = [require("calendar.events", "view")]

    def _contingent(self, pk):
        from apps.core.groups import current_group_id

        from .models import EventContingent

        event = get_object_or_404(_visible(self.request.user), pk=pk)
        return get_object_or_404(EventContingent.objects.select_related("event", "event__group", "group"),
                                 event=event, group_id=current_group_id())

    def _body(self, request, c):
        return {"requested": c.requested, "note": c.note, "members": _people(c.members.all()),
                "answered_at": c.answered_at.isoformat() if c.answered_at else None,
                "can_answer": request.user.can("calendar.planning", "change") and not c.event.has_ended()}

    def get(self, request, pk):
        return Response(self._body(request, self._contingent(pk)))

    def put(self, request, pk):
        from .contingents import ContingentRule, answer

        c = self._contingent(pk)
        if not request.user.can("calendar.planning", "change"):
            return Response({"detail": "Réservé à ceux qui font le planning.", "code": "forbidden"}, status=403)
        ids = request.data.get("members")
        if not isinstance(ids, list):
            return Response({"detail": "Liste de membres attendue.", "code": "bad_request"}, status=400)
        try:
            answer(c, ids, by=request.user, request=request)
        except ContingentRule as e:
            return Response({"detail": e.message, "code": e.code}, status=e.status)
        return Response(self._body(request, c))
