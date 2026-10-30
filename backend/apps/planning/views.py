from datetime import datetime, time, timedelta

from django.shortcuts import get_object_or_404
from django.utils import timezone
from django.utils.dateparse import parse_date
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.accounts.models import User
from apps.accounts.permissions import require
from apps.events.models import ActivityType, Event

from . import services
from .models import SIZES, AlbRotation, Assignment, Request, Service, ServiceGroup, slots_for


def _midnight(d):
    return timezone.make_aware(datetime.combine(d, time.min))


def _rule(e):
    return Response({"detail": str(e), "code": e.code}, status=e.status)


def _assignment_json(a, conflicts=()):
    return {
        "id": a.pk, "post": a.post, "side": a.side, "index": a.index, "member": a.member_id,
        "member_name": a.member.short_name, "status": a.status, "conflict": a.pk in conflicts,
    }


def _service_json(s, conflicts=()):
    e = s.event
    return {
        "id": s.pk, "event": e.pk, "title": e.title, "kind": e.kind, "starts_at": e.starts_at, "size": s.size,
        "group": s.group.name if s.group else None,
        "chef": s.chef.short_name if s.chef else None, "chef_id": s.chef_id,
        "published": s.published_at is not None,
        "past": services.is_past(s),
        "slots": [{"post": p, "side": sd, "index": i} for p, sd, i in slots_for(s.size)],
        "assignments": [_assignment_json(a, conflicts) for a in s.assignments.all()],
    }


def _week_services(start, end):
    lo = _midnight(start)
    hi = lo + (end - start)
    return list(
        Service.objects.filter(event__starts_at__gte=lo, event__starts_at__lt=hi)
        .select_related("event__chef", "group")
        .prefetch_related("assignments__member")
        .order_by("event__starts_at")
    )


class WeekView(APIView):
    """The planning grid for a week (?day=YYYY-MM-DD, any day of it)."""

    permission_classes = [require("calendar.planning", "view")]

    def get(self, request):
        day = parse_date(request.query_params.get("day", "")) or timezone.localdate()
        start, end = services.week_bounds(day)
        items = _week_services(start, end)
        c = services.conflicts(items)
        unplanned = Event.objects.filter(
            starts_at__gte=_midnight(start),
            starts_at__lt=_midnight(end),
            kind__in=ActivityType.objects.filter(needs_lineup=True).values("slug"), service__isnull=True,
        )
        return Response({
            "start": start, "end": end - timedelta(days=1),
            "services": [_service_json(s, c) for s in items],
            "alerts": services.alerts(items),
            "unplanned": [{"event": e.pk, "title": e.title, "starts_at": e.starts_at} for e in unplanned],
            "published": bool(items) and all(s.published_at for s in items),
            # Drafts still to come: what "Publier et notifier" would send.
            "publishable": sum(1 for s in items if s.published_at is None and not services.is_past(s)),
            "past_drafts": sum(1 for s in items if s.published_at is None and services.is_past(s)),
        })


class ServiceCreateView(APIView):
    """Give an event a service size (2–12)."""

    permission_classes = [require("calendar.planning", "create")]

    def post(self, request):
        event = get_object_or_404(Event, pk=request.data.get("event"))
        size = int(request.data.get("size") or 0)
        if size not in SIZES:
            return Response({"detail": "Taille invalide.", "code": "bad_size"}, status=400)
        if event.starts_at <= timezone.now() and not Service.objects.filter(event=event).exists():
            return Response({"detail": "La date de cet événement est passée.", "code": "date_passed"}, status=400)
        s, _ = Service.objects.update_or_create(event=event, defaults={"size": size})
        s.assignments.exclude(pk__in=[a.pk for a in s.assignments.all() if (a.post, a.side, a.index) in slots_for(size)]).delete()
        services.note_exceptional(request.user, "taille du service", s, request, taille=size)
        return Response(_service_json(Service.objects.select_related("event__chef", "group").get(pk=s.pk)), status=201)


class SlotView(APIView):
    """PUT {post, side, index, member, force?} to fill a slot; member null clears it."""

    permission_classes = [require("calendar.planning", "change")]

    def put(self, request, pk):
        s = get_object_or_404(Service.objects.select_related("event"), pk=pk)
        post, side, index = request.data.get("post"), request.data.get("side"), int(request.data.get("index") or 0)
        member_id = request.data.get("member")
        if member_id is None:
            services.clear(s, post, side, index, by=request.user, request=request)
            return Response(status=status.HTTP_204_NO_CONTENT)
        member = get_object_or_404(User.objects.members(), pk=member_id)
        try:
            a = services.assign(s, post, side, index, member, by=request.user, force=bool(request.data.get("force")), request=request)
        except services.PlanningRule as e:
            return _rule(e)
        return Response(_assignment_json(a))


class MoveView(APIView):
    """PUT {service, post, side, index, force?}: drag a guard to another
    cell; a filled cell of the same service swaps the two."""

    permission_classes = [require("calendar.planning", "change")]

    def put(self, request, pk):
        a = get_object_or_404(Assignment.objects.select_related("service__event", "member"), pk=pk)
        target = get_object_or_404(Service.objects.select_related("event"), pk=request.data.get("service") or a.service_id)
        try:
            moved = services.move(a, target, request.data.get("post"), request.data.get("side"), int(request.data.get("index") or 0),
                                  by=request.user, force=bool(request.data.get("force")), request=request)
        except services.PlanningRule as e:
            return _rule(e)
        return Response(_assignment_json(moved))


class CandidatesView(APIView):
    permission_classes = [require("calendar.planning", "change")]

    def get(self, request, pk):
        return Response(services.candidates(get_object_or_404(Service.objects.select_related("event"), pk=pk)))


class AssignGroupView(APIView):
    permission_classes = [require("calendar.planning", "change")]

    def post(self, request, pk):
        s = get_object_or_404(Service.objects.select_related("event"), pk=pk)
        group = get_object_or_404(ServiceGroup, pk=request.data.get("group"))
        created, missing = services.assign_group(s, group, by=request.user, request=request)
        return Response({"assigned": len(created), "still_empty": missing})


class ChefView(APIView):
    """PUT {member} to change the event's chef de groupe from the planning
    (any active member, as when the event is created)."""

    permission_classes = [require("calendar.planning", "change")]

    def put(self, request, pk):
        s = get_object_or_404(Service.objects.select_related("event__chef", "group"), pk=pk)
        member = get_object_or_404(User.objects.members(), pk=request.data["member"]) if request.data.get("member") else None
        try:
            services.set_chef(s, member, by=request.user, request=request)
        except services.PlanningRule as e:
            return _rule(e)
        s = Service.objects.select_related("event__chef", "group").prefetch_related("assignments__member").get(pk=pk)
        return Response(_service_json(s))


class PublishView(APIView):
    """Publish a week: members see their duties and get notified."""

    permission_classes = [require("calendar.planning", "change")]

    def post(self, request):
        day = parse_date(str(request.data.get("day", ""))) or timezone.localdate()
        start, end = services.week_bounds(day)
        items = _week_services(start, end)
        try:
            n = services.publish(items, by=request.user, request=request)
        except services.PlanningRule as e:
            return _rule(e)
        past = [s.event.title for s in items if s.published_at is None and services.is_past(s)]
        return Response({"notified": n, "past": past})


class ReuseView(APIView):
    """GET: upcoming events this lineup can be reused for. POST {event}: a
    new draft lineup for that event, copied from this one."""

    permission_classes = [require("calendar.planning", "change")]

    def get(self, request, pk):
        source = get_object_or_404(Service, pk=pk)
        return Response([{"event": e.pk, "title": e.title, "starts_at": e.starts_at} for e in services.reuse_targets(source)])

    def post(self, request, pk):
        source = get_object_or_404(Service.objects.select_related("event", "group"), pk=pk)
        event = get_object_or_404(Event, pk=request.data.get("event"))
        try:
            target, skipped = services.reuse(source, event, by=request.user, request=request)
        except services.PlanningRule as e:
            return _rule(e)
        target = Service.objects.select_related("event__chef", "group").prefetch_related("assignments__member").get(pk=target.pk)
        return Response({**_service_json(target), "skipped": skipped}, status=201)


class GroupsView(APIView):
    def get_permissions(self):
        return [require("calendar.planning", "change" if self.request.method == "POST" else "view")()]

    def get(self, request):
        out = []
        for g in ServiceGroup.objects.prefetch_related("members"):
            members = list(g.members.all())
            out.append({"id": g.pk, "name": g.name,
                        "members": [{"id": m.pk, "full_name": m.full_name} for m in members],
                        "available": sum(1 for m in members if m.group_status == User.Status.ACTIVE),
                        "on_leave": sum(1 for m in members if m.group_status == User.Status.LEAVE)})
        return Response(out)

    def post(self, request):
        name = (request.data.get("name") or "").strip()
        if not name:
            return Response({"detail": "Nom requis.", "code": "required"}, status=400)
        g, _ = ServiceGroup.objects.get_or_create(name=name)
        if "members" in request.data:
            g.members.set(User.objects.members().filter(pk__in=request.data["members"]))
        return Response({"id": g.pk}, status=201)


class MineView(APIView):
    """My published, upcoming duties (design: "Mes services")."""

    def get(self, request):
        now = timezone.now() - timedelta(hours=6)
        qs = (
            Assignment.objects.filter(member=request.user, service__published_at__isnull=False, service__event__starts_at__gte=now)
            .exclude(status=Assignment.Status.REPLACED)
            .select_related("service__event__chef")
            .order_by("service__event__starts_at")
        )
        return Response([{
            **_assignment_json(a),
            "event": a.service.event_id, "title": a.service.event.title, "starts_at": a.service.event.starts_at,
            "dress": a.service.event.dress, "chef": a.service.chef.full_name if a.service.chef else None,
            "is_chef": a.service.chef_id == request.user.pk,
        } for a in qs])


class ConfirmView(APIView):
    def post(self, request, pk):
        a = get_object_or_404(Assignment, pk=pk, member=request.user)
        a.status = Assignment.Status.CONFIRMED
        a.save(update_fields=["status"])
        return Response(_assignment_json(a))


class SwapView(APIView):
    """POST {target, reason} → ask a colleague; or {absence: true, reason}."""

    def post(self, request, pk):
        a = get_object_or_404(Assignment.objects.select_related("service__event__chef"), pk=pk)
        try:
            if request.data.get("absence"):
                r = services.declare_absence(a, by=request.user, reason=request.data.get("reason", ""))
            else:
                target = get_object_or_404(User.objects.members(), pk=request.data.get("target"))
                r = services.request_swap(a, by=request.user, target=target, reason=request.data.get("reason", ""))
        except services.PlanningRule as e:
            return _rule(e)
        return Response({"id": r.pk, "status": r.status}, status=201)


def _request_json(r):
    a = r.assignment
    return {
        "id": r.pk, "kind": r.kind, "status": r.status, "reason": r.reason,
        "requester": r.requester.short_name, "target": r.target.short_name if r.target else None,
        "assignment": a.pk, "service": a.service_id, "post": a.post, "side": a.side,
        "title": a.service.event.title, "starts_at": a.service.event.starts_at,
    }


class RequestsView(APIView):
    """For whoever makes the lineup: what waits for a decision. For anyone:
    swaps proposed to me."""

    def get(self, request):
        base = Request.objects.select_related("assignment__service__event", "requester", "target")
        mine = base.filter(target=request.user, status=Request.Status.PROPOSED)
        decide = base.filter(status=Request.Status.ACCEPTED)
        if not request.user.can("calendar.planning", "change"):
            # The chef de groupe decides for their own events.
            decide = decide.filter(assignment__service__event__chef=request.user)
        return Response({"for_me": [_request_json(r) for r in mine], "to_decide": [_request_json(r) for r in decide]})


class AnswerView(APIView):
    """The colleague accepts or refuses a proposed swap."""

    def post(self, request, pk):
        r = get_object_or_404(Request.objects.select_related("assignment"), pk=pk)
        try:
            services.target_answer(r, by=request.user, accept=bool(request.data.get("accept")))
        except services.PlanningRule as e:
            return _rule(e)
        return Response(_request_json(r))


class DecideView(APIView):
    """The lineup makers, or the event's chef de groupe (design: "le chef de
    groupe ou le censeur valide")."""

    def post(self, request, pk):
        r = get_object_or_404(Request.objects.select_related("assignment__service__event", "requester", "target"), pk=pk)
        if not services.can_decide(request.user, r):
            return Response({"detail": "Réservé au chef de groupe et aux responsables du planning.", "code": "not_decider"}, status=403)
        replacement = get_object_or_404(User.objects.members(), pk=request.data["replacement"]) if request.data.get("replacement") else None
        try:
            services.decide(r, by=request.user, approve=bool(request.data.get("approve")), replacement=replacement, request=request)
        except services.PlanningRule as e:
            return _rule(e)
        return Response(_request_json(r))


class ReplacementCandidatesView(APIView):
    def get(self, request, pk):
        r = get_object_or_404(Request.objects.select_related("assignment__service__event"), pk=pk)
        if not services.can_decide(request.user, r):
            return Response({"detail": "Réservé au chef de groupe et aux responsables du planning.", "code": "not_decider"}, status=403)
        return Response(services.candidates(r.assignment.service))


def _alb_json(r, user):
    return {"id": r.pk, "week_start": r.week_start, "group": r.group.name if r.group else None,
            "responsible": r.responsible.full_name if r.responsible else None, "albs": r.albs, "status": r.status,
            "can_advance": services.may_advance_alb(r, user)}


class AlbsView(APIView):
    """Current and upcoming alb-washing weeks, plus the 12-month fairness."""

    def get_permissions(self):
        if self.request.method == "POST":
            return [require("calendar.planning", "change")()]
        return [IsAuthenticated()]

    def get(self, request):
        monday, _ = services.week_bounds(timezone.localdate())
        rows = AlbRotation.objects.filter(week_start__gte=monday - timedelta(days=7)).select_related("group", "responsible")[:8]
        return Response({"weeks": [_alb_json(r, request.user) for r in rows], "fairness": services.alb_fairness()})

    def post(self, request):
        week = parse_date(str(request.data.get("week_start", "")))
        if not week:
            return Response({"detail": "Semaine requise.", "code": "required"}, status=400)
        week, _ = services.week_bounds(week)
        group = ServiceGroup.objects.filter(pk=request.data.get("group")).first()
        responsible = User.objects.members().filter(pk=request.data.get("responsible")).first()
        r, _ = AlbRotation.objects.update_or_create(week_start=week, defaults={"group": group, "responsible": responsible,
                                                                              "albs": int(request.data.get("albs") or 12)})
        return Response(_alb_json(r, request.user), status=201)


class AlbAdvanceView(APIView):
    def post(self, request, pk):
        r = get_object_or_404(AlbRotation.objects.select_related("group"), pk=pk)
        if not services.may_advance_alb(r, request.user):
            return Response({"detail": "Réservé au groupe responsable.", "code": "forbidden"}, status=403)
        try:
            services.advance_alb(r, by=request.user)
        except services.PlanningRule as e:
            return _rule(e)
        return Response(_alb_json(r, request.user))


class SwapCandidatesView(APIView):
    """Colleagues I can offer my duty to: active, free that day. Names only —
    members don't otherwise see the member list."""

    def get(self, request, pk):
        a = get_object_or_404(Assignment.objects.select_related("service__event"), pk=pk, member=request.user)
        rows = [c for c in services.candidates(a.service) if c["flag"] in (None, "many_this_month") and c["member"] != request.user.pk]
        return Response([{"member": c["member"], "full_name": c["full_name"]} for c in rows])
