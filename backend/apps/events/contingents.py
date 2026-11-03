"""Joint planning between the groups of a network (owner, 2026-11-03).

An event sent down (Event.cascade) can ask each group attached directly
below for a number of people. That group's planning officers
(calendar.planning change, in their own group) name them; the people named
are told, and so are the asking group's planners. The upper group never
picks a lower group's members itself.
"""

from django.db import transaction
from django.utils import timezone

from apps.core import audit
from apps.core.groups import in_group
from apps.core.notify import notify

from .models import EventContingent


class ContingentRule(Exception):
    def __init__(self, code, message, status=400):
        super().__init__(message)
        self.code, self.message, self.status = code, message, status


def named_here(event, group_id):
    """The members of `group_id` named for an event sent down from above."""
    c = EventContingent.objects.filter(event=event, group_id=group_id).prefetch_related("members").first()
    return list(c.members.filter(is_active=True)) if c else []


def planners(group):
    from apps.accounts.models import RoleAssignment, User

    with in_group(group):
        ids = RoleAssignment.objects.active().filter(
            role__group=group, role__permissions__resource="calendar.planning", role__permissions__action="change"
        ).values("user")
        return list(User.objects.members().filter(pk__in=ids, is_active=True))


def _tell(group, people, title, body, event):
    with in_group(group):
        notify(people, "duty", title, body, {"type": "event", "id": event.pk})


def _open(event):
    if event.has_ended():
        raise ContingentRule("event_ended", "Cet événement est passé : le planning ne change plus.", 409)


@transaction.atomic
def set_requests(event, requests, *, by, request=None):
    """requests: [{"group": id, "requested": n, "note": ""}]; 0 removes."""
    _open(event)
    if not event.cascade:
        raise ContingentRule("not_sent_down", "Envoyez d’abord l’événement aux groupes rattachés.")
    kids = {g.pk: g for g in event.group.children.filter(is_active=True)}
    changed = []
    for r in requests or []:
        try:
            gid, n = int(r.get("group")), int(r.get("requested") or 0)
        except (TypeError, ValueError):
            raise ContingentRule("bad_request", "Demande invalide.") from None
        if gid not in kids:
            raise ContingentRule("not_below", "Ce groupe n’est pas rattaché au vôtre.")
        if not 0 <= n <= 500:
            raise ContingentRule("bad_number", "Entre 0 et 500 personnes.")
        note = str(r.get("note") or "").strip()[:200]
        g = kids[gid]
        c = EventContingent.objects.filter(event=event, group=g).first()
        if n == 0:
            if c is not None:
                c.delete()
                changed.append((g, 0))
                _tell(g, planners(g), "Demande annulée", f"{event.group.name} n’attend plus de personnes pour « {event.title} ».", event)
            continue
        if c is None:
            EventContingent.objects.create(event=event, group=g, requested=n, note=note, asked_by=by)
        elif (c.requested, c.note) != (n, note):
            c.requested, c.note = n, note
            c.save(update_fields=["requested", "note"])
        else:
            continue
        changed.append((g, n))
        when = timezone.localtime(event.starts_at).strftime("%d/%m à %H:%M")
        _tell(g, planners(g), f"{event.group.name} demande {n} personne{'s' if n > 1 else ''}",
              f"« {event.title} », le {when}. Désignez-les dans Calendrier → l’événement." + (f" {note}" if note else ""), event)
    if changed:
        audit.record("Contingents demandés", actor=by, obj=event, request=request,
                     detail={g.name: n for g, n in changed})
    return contingents_of(event)


def contingents_of(event):
    rows = {c.group_id: c for c in EventContingent.objects.filter(event=event).prefetch_related("members")}
    out = []
    for g in event.group.children.filter(is_active=True).order_by("name"):
        c = rows.get(g.pk)
        out.append({"group": g, "contingent": c})
    return out


@transaction.atomic
def answer(contingent, member_ids, *, by, request=None):
    from apps.accounts.models import User

    event, group = contingent.event, contingent.group
    _open(event)
    with in_group(group):
        people = list(User.objects.members().filter(pk__in=member_ids or [], is_active=True,
                                                    gstatus=User.Status.ACTIVE))
    if len(people) != len(set(member_ids or [])):
        raise ContingentRule("not_member", "Choisissez des membres actifs de votre groupe.")
    before = set(contingent.members.values_list("pk", flat=True))
    contingent.members.set(people)
    contingent.answered_by, contingent.answered_at = by, timezone.now()
    contingent.save(update_fields=["answered_by", "answered_at"])
    new = [u for u in people if u.pk not in before]
    when = timezone.localtime(event.starts_at).strftime("%d/%m à %H:%M")
    if new:
        _tell(group, new, "Vous êtes désigné(e)", f"Pour « {event.title} » de {event.group.name}, le {when}.", event)
    gone = [pk for pk in before if pk not in {u.pk for u in people}]
    if gone:
        with in_group(group):
            _tell(group, list(User.objects.filter(pk__in=gone)), "Désignation retirée",
                  f"Vous n’êtes plus attendu(e) pour « {event.title} ».", event)
    _tell(event.group, planners(event.group), f"{group.name} a désigné {len(people)}/{contingent.requested}",
          f"Pour « {event.title} ».", event)
    with in_group(group):
        audit.record("Contingent désigné", actor=by, obj=event, request=request,
                     detail={"groupe": group.name, "demandés": contingent.requested, "désignés": len(people)})
    return contingent
