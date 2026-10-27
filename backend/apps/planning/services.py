from datetime import datetime, time, timedelta

from django.db import transaction
from django.db.models import Count
from django.utils import timezone

from apps.accounts import registry
from apps.accounts.models import RoleAssignment, User
from apps.core import audit
from apps.core.notify import notify

from .models import AlbRotation, Assignment, Request, ServiceGroup, slots_for

MONTHLY_SOFT_LIMIT = 4  # design: "plus de 4 services dans le mois" → warning


class PlanningRule(Exception):
    def __init__(self, code, message, status=400):
        super().__init__(message)
        self.code = code
        self.status = status


def _day_bounds(d):
    start = timezone.make_aware(datetime.combine(d, time.min))
    return start, start + timedelta(days=1)


def week_bounds(any_day):
    monday = any_day - timedelta(days=any_day.weekday())
    return monday, monday + timedelta(days=7)


# --- Who makes the lineup ------------------------------------------------------
# The formateur or formateur adjoint makes it; the président or vice-président
# only exceptionally (registry.LINEUP_ROLES). An exceptional change is
# recorded in the audit log and the formateurs are told when it is published.

REGULAR_LINEUP_ROLES = registry.LINEUP_ROLES - registry.LINEUP_EXCEPTIONAL_ROLES


def is_exceptional(user):
    return not (user.role_slugs() & REGULAR_LINEUP_ROLES)


def lineup_makers():
    ids = RoleAssignment.objects.active().filter(role__slug__in=REGULAR_LINEUP_ROLES).values("user")
    return list(User.objects.members().filter(pk__in=ids, is_active=True))


def note_exceptional(by, what, service=None, request=None, **detail):
    if by is None or not is_exceptional(by):
        return
    if service is not None:
        detail["service"] = f"{service.event.title} · {timezone.localtime(service.event.starts_at):%d/%m %H:%M}"
    audit.record("Planning modifié à titre exceptionnel", actor=by, request=request, sensitive=True,
                 detail={"action": what, **detail})


def _available_members():
    return User.objects.members().filter(gstatus=User.Status.ACTIVE, is_active=True)


def service_counts(month_of):
    """Services per member in the calendar month of `month_of`."""
    first = month_of.replace(day=1)
    nxt = (first + timedelta(days=32)).replace(day=1)
    lo, _ = _day_bounds(first)
    hi, _ = _day_bounds(nxt)
    rows = (
        Assignment.objects.filter(service__event__starts_at__gte=lo, service__event__starts_at__lt=hi)
        .exclude(status__in=[Assignment.Status.REPLACED, Assignment.Status.ABSENT])
        .values("member")
        .annotate(n=Count("id"))
    )
    return {r["member"]: r["n"] for r in rows}


def busy_same_day(member_id, service):
    lo, hi = _day_bounds(timezone.localtime(service.event.starts_at).date())
    return (
        Assignment.objects.filter(member_id=member_id, service__event__starts_at__gte=lo, service__event__starts_at__lt=hi)
        .exclude(service=service)
        .exclude(status__in=[Assignment.Status.REPLACED, Assignment.Status.ABSENT])
        .select_related("service__event")
        .first()
    )


def candidates(service):
    """Members for an empty slot, least-solicited first, with flags the
    app shows (design: "Les moins sollicités en premier")."""
    counts = service_counts(timezone.localtime(service.event.starts_at).date())
    taken = set(service.assignments.values_list("member_id", flat=True))
    out = []
    for m in User.objects.members().filter(gstatus__in=[User.Status.ACTIVE, User.Status.LEAVE], is_active=True):
        if m.pk in taken:
            continue
        flag = None
        if m.gstatus == User.Status.LEAVE:
            flag = "on_leave"
        else:
            other = busy_same_day(m.pk, service)
            if other:
                flag = "busy_same_day"
            elif counts.get(m.pk, 0) >= MONTHLY_SOFT_LIMIT:
                flag = "many_this_month"
        out.append({"member": m.pk, "full_name": m.full_name, "services_this_month": counts.get(m.pk, 0), "flag": flag})
    order = {None: 0, "many_this_month": 1, "busy_same_day": 2, "on_leave": 3}
    out.sort(key=lambda c: (order[c["flag"]], c["services_this_month"], c["full_name"]))
    return out


def assign(service, post, side, index, member, *, by, force=False, request=None):
    if (post, side, index) not in slots_for(service.size):
        raise PlanningRule("bad_slot", "Ce poste n’existe pas pour cette taille de service.")
    if member.status == User.Status.LEAVE:
        raise PlanningRule("on_leave", f"{member.short_name} est en congé.")
    if member.status != User.Status.ACTIVE:
        raise PlanningRule("not_active", f"{member.short_name} n’est pas actif.")
    if service.assignments.filter(member=member).exclude(post=post, side=side, index=index).exists():
        raise PlanningRule("already_in_service", f"{member.short_name} a déjà un poste dans ce service.")
    other = busy_same_day(member.pk, service)
    if other and not force:
        raise PlanningRule("double_service", f"{member.short_name} a déjà un service ce jour-là.", status=409)
    a, _ = Assignment.objects.update_or_create(
        service=service, post=post, side=side, index=index,
        defaults={"member": member, "status": Assignment.Status.PENDING, "assigned_by": by},
    )
    note_exceptional(by, "affectation", service, request, membre=member.short_name, poste=_post_label(a))
    if service.published_at:
        _notify_duty([a])
    return a


def clear(service, post, side, index, *, by=None, request=None):
    gone = service.assignments.filter(post=post, side=side, index=index).first()
    if gone is None:
        return
    gone.delete()
    note_exceptional(by, "poste libéré", service, request, poste=_post_label(gone))


def set_chef(service, member, *, by, request=None):
    """Change the event's chef de groupe from the planning (owner,
    2026-10-27: the chef belongs to the event, designated when it is
    created; None removes it). The new chef is told at once."""
    from apps.events import reports

    event = service.event
    if member is None and not _chef_optional(event):
        raise PlanningRule("chef_required", "Cet événement a besoin d’un chef de groupe.")
    previous = event.chef_id
    event.chef = member
    event.save(update_fields=["chef"])
    note_exceptional(by, "chef de groupe", service, request, chef=member.short_name if member else None)
    if member is not None and member.pk != previous:
        reports.tell_chef(event)
    return service


def _chef_optional(event):
    from apps.events.models import ActivityType

    t = ActivityType.objects.filter(slug=event.kind).first()
    return t is None or not t.needs_chef


def assign_group(service, group, *, by, request=None):
    """Fill empty slots with the group's available members, least-solicited
    first; members on leave or already busy that day are skipped."""
    counts = service_counts(timezone.localtime(service.event.starts_at).date())
    filled = {(a.post, a.side, a.index) for a in service.assignments.all()}
    empty = [s for s in slots_for(service.size) if s not in filled]
    taken = set(service.assignments.values_list("member_id", flat=True))
    pool = [m for m in User.objects.members().filter(gstatus=User.Status.ACTIVE, service_groups=group) if m.pk not in taken and not busy_same_day(m.pk, service)]
    pool.sort(key=lambda m: (counts.get(m.pk, 0), m.last_name))
    created = []
    with transaction.atomic():
        for slot, m in zip(empty, pool, strict=False):
            created.append(Assignment.objects.create(service=service, post=slot[0], side=slot[1], index=slot[2], member=m, assigned_by=by))
        service.group = group
        service.save(update_fields=["group"])
    note_exceptional(by, "groupe affecté", service, request, groupe=group.name, affectés=len(created))
    if service.published_at:
        _notify_duty(created)
    return created, len(empty) - len(created)


def alerts(services):
    """Week alerts (design: "3 alertes · Grande-messe : 8 sur 10 · Essomba K.
    a deux services le dimanche 25")."""
    out = []
    by_day = {}
    for s in services:
        active = [a for a in s.assignments.all() if a.status not in (Assignment.Status.REPLACED, Assignment.Status.ABSENT)]
        if len(active) < s.size:
            out.append({"code": "understaffed", "service": s.pk, "filled": len(active), "size": s.size})
        day = timezone.localtime(s.event.starts_at).date()
        for a in active:
            by_day.setdefault((day, a.member_id), []).append((s, a))
            if a.member.status == User.Status.LEAVE:
                out.append({"code": "on_leave", "service": s.pk, "member": a.member.short_name})
    for (day, _), items in by_day.items():
        if len(items) > 1:
            out.append({"code": "double_service", "day": day, "member": items[0][1].member.short_name,
                        "services": [s.pk for s, _ in items]})
    return out


def conflicts(services):
    """Assignment ids that are in conflict (two services the same day)."""
    by_day = {}
    for s in services:
        day = timezone.localtime(s.event.starts_at).date()
        for a in s.assignments.all():
            if a.status in (Assignment.Status.REPLACED, Assignment.Status.ABSENT):
                continue
            by_day.setdefault((day, a.member_id), []).append(a.pk)
    return {aid for ids in by_day.values() if len(ids) > 1 for aid in ids}


def _post_label(a):
    return f"{a.post.replace('_', ' ')} ({a.side.capitalize()})"


def _notify_duty(assignments):
    for a in assignments:
        ev = a.service.event
        when = timezone.localtime(ev.starts_at)
        chef = " Vous êtes chef de groupe." if a.service.chef_id == a.member_id else ""
        notify([a.member], "duty", "Nouveau service",
               f"{when:%d/%m} à {when:%H:%M} · {_post_label(a)}.{chef} Confirmez votre présence.",
               {"type": "duty", "id": a.pk})


def publish(services, *, by, request=None):
    now = timezone.now()
    to_notify = []
    with transaction.atomic():
        for s in services:
            if s.published_at is None:
                s.published_at = now
                s.save(update_fields=["published_at"])
                to_notify += list(s.assignments.select_related("service__event", "member"))
    _notify_duty(to_notify)
    exceptional = is_exceptional(by)
    audit.record("Planning publié" + (" à titre exceptionnel" if exceptional else ""), actor=by, request=request,
                 sensitive=exceptional, detail={"services": len(services), "notifiés": len(to_notify)})
    if exceptional and services:
        notify(lineup_makers(), "duty", "Planning publié par le bureau",
               f"{by.short_name} a publié le planning ({len(services)} service(s)) à titre exceptionnel.",
               {"type": "planning"})
    return len(to_notify)


# --- Member side ----------------------------------------------------------------


def request_swap(assignment, *, by, target, reason=""):
    if assignment.member_id != by.pk:
        raise PlanningRule("not_yours", "Ce service n’est pas le vôtre.", status=403)
    if target.pk == by.pk or target.group_status != User.Status.ACTIVE:
        raise PlanningRule("bad_target", "Choisissez un collègue actif.")
    if busy_same_day(target.pk, assignment.service):
        raise PlanningRule("target_busy", f"{target.short_name} a déjà un service ce jour-là.")
    r = Request.objects.create(kind=Request.Kind.SWAP, assignment=assignment, requester=by, target=target, reason=reason, status=Request.Status.PROPOSED)
    assignment.status = Assignment.Status.SWAP
    assignment.save(update_fields=["status"])
    notify([target], "request", "Demande d’échange", f"{by.short_name} vous propose son service : {_post_label(assignment)}.", {"type": "request", "id": r.pk})
    return r


def declare_absence(assignment, *, by, reason=""):
    if assignment.member_id != by.pk:
        raise PlanningRule("not_yours", "Ce service n’est pas le vôtre.", status=403)
    r = Request.objects.create(kind=Request.Kind.ABSENCE, assignment=assignment, requester=by, reason=reason, status=Request.Status.ACCEPTED)
    assignment.status = Assignment.Status.ABSENT
    assignment.save(update_fields=["status"])
    # The formateurs find the replacement; the day's chef de groupe is told.
    chef = assignment.service.chef if assignment.service.chef_id != by.pk else None
    notify([*lineup_makers(), chef], "request", "Absence déclarée", f"{by.short_name} · {_post_label(assignment)} · {reason}", {"type": "request", "id": r.pk})
    return r


def target_answer(req, *, by, accept):
    if req.target_id != by.pk or req.status != Request.Status.PROPOSED:
        raise PlanningRule("not_for_you", "Cette demande ne vous attend pas.", status=403)
    req.status = Request.Status.ACCEPTED if accept else Request.Status.REFUSED
    req.save(update_fields=["status"])
    if not accept:
        req.assignment.status = Assignment.Status.PENDING
        req.assignment.save(update_fields=["status"])
    notify([req.requester], "request", "Échange accepté" if accept else "Échange refusé", by.short_name, {"type": "request", "id": req.pk})
    return req


def decide(req, *, by, approve, replacement=None, request=None):
    """Whoever makes the lineup approves a swap (accepted by the colleague)
    or fills an absence with a replacement."""
    if req.status != Request.Status.ACCEPTED:
        raise PlanningRule("not_ready", "Cette demande n’attend pas de décision.")
    a = req.assignment
    with transaction.atomic():
        if not approve:
            req.status = Request.Status.REFUSED
            a.status = Assignment.Status.PENDING
        else:
            new_member = req.target if req.kind == Request.Kind.SWAP else replacement
            if new_member is None:
                raise PlanningRule("replacement_required", "Choisissez un remplaçant.")
            if busy_same_day(new_member.pk, a.service):
                raise PlanningRule("double_service", f"{new_member.short_name} a déjà un service ce jour-là.", status=409)
            a.member = new_member
            a.status = Assignment.Status.CONFIRMED if req.kind == Request.Kind.SWAP else Assignment.Status.PENDING
            req.status = Request.Status.APPROVED
            req.target = new_member
        req.decided_by = by
        req.save(update_fields=["status", "decided_by", "target"])
        a.save(update_fields=["member", "status"])
    audit.record("Demande de service " + ("approuvée" if approve else "refusée"), actor=by, request=request,
                 sensitive=is_exceptional(by), detail={"type": req.kind, "exceptionnel": is_exceptional(by)})
    notify([req.requester, req.target if approve else None], "request", "Demande " + ("approuvée" if approve else "refusée"),
           _post_label(a), {"type": "request", "id": req.pk})
    return req


# --- Albs -----------------------------------------------------------------------------


def alb_fairness(today=None):
    since = (today or timezone.localdate()) - timedelta(days=365)
    rows = AlbRotation.objects.filter(week_start__gte=since, status=AlbRotation.Status.RETURNED)
    counts = {}
    for r in rows.select_related("group", "responsible"):
        name = r.group.name if r.group else (r.responsible.short_name if r.responsible else "—")
        counts[name] = counts.get(name, 0) + 1
    for g in ServiceGroup.objects.all():
        counts.setdefault(g.name, 0)
    return sorted(({"name": k, "count": v} for k, v in counts.items()), key=lambda x: (-x["count"], x["name"]))


def advance_alb(rot, *, by):
    order = [AlbRotation.Status.TO_WASH, AlbRotation.Status.WASHED, AlbRotation.Status.RETURNED]
    i = order.index(rot.status)
    if i == len(order) - 1:
        raise PlanningRule("already_returned", "Les aubes sont déjà rendues.")
    rot.status = order[i + 1]
    rot.save(update_fields=["status"])
    return rot


def may_advance_alb(rot, user):
    if user.can("calendar.planning", "change"):
        return True
    if rot.responsible_id == user.pk:
        return True
    return bool(rot.group and rot.group.members.filter(pk=user.pk).exists())

