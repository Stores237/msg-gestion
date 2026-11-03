"""What a group shares with its network (owner, 2026-11-03).

Each group's président chooses, kind by kind, what the groups above it may
see: nothing (the default), a summary, or the detail. In the upper group,
each kind is read only by those whose role there covers it (its treasurer
reads the finances, its secretary the members…), so sharing upward never
shows more than the umbrella's own officers handle.

Never shared, whatever the setting: phone numbers, PINs, minors' contacts,
attachments, members' personal statements.
"""

from datetime import timedelta

from django.db.models import Count, Q
from django.utils import timezone

from . import audit
from .groups import in_group
from .models import GroupShare

NONE, SUMMARY, DETAIL = "none", "summary", "detail"

# kind -> (levels offered, permission needed in the upper group to read it)
KINDS = {
    "members": ((SUMMARY, DETAIL), ("members.profile", "view")),
    "finances": ((SUMMARY, DETAIL), ("finances.cashbook", "view")),
    "calendar": ((SUMMARY, DETAIL), ("calendar.events", "view")),
    "announcements": ((DETAIL,), ("announcements.posts", "view")),
    "reports": ((SUMMARY, DETAIL), ("calendar.reports", "view")),
}
LABELS = {"members": "Membres", "finances": "Finances", "calendar": "Calendrier",
          "announcements": "Annonces", "reports": "Présences et rapports"}
LEVEL_LABELS = {NONE: "Rien", SUMMARY: "Résumé", DETAIL: "Détail"}


class SharingRule(Exception):
    def __init__(self, code, message, status=400):
        super().__init__(message)
        self.code, self.message, self.status = code, message, status


def settings_of(group, audience=GroupShare.Audience.UP):
    rows = dict(GroupShare.objects.filter(group=group, audience=audience).values_list("kind", "level"))
    return {k: rows.get(k, NONE) for k in KINDS}


def save_settings(group, values, *, by, request=None, audience=GroupShare.Audience.UP):
    current = settings_of(group, audience)
    changed = {}
    for kind, level in (values or {}).items():
        if kind not in KINDS:
            continue
        if level != NONE and level not in KINDS[kind][0]:
            raise SharingRule("bad_level", f"{LABELS[kind]} : niveau de partage impossible.")
        if current[kind] != level:
            GroupShare.objects.update_or_create(group=group, audience=audience, kind=kind,
                                                defaults={"level": level, "updated_by": by})
            changed[LABELS[kind]] = {"avant": LEVEL_LABELS[current[kind]], "apres": LEVEL_LABELS[level]}
    if changed:
        with in_group(group):
            audit.record("Partage avec le réseau modifié", actor=by, obj=group, request=request, detail=changed)
        from .network import _tell, neighbours, twins

        now = settings_of(group, audience)
        shown = ", ".join(f"{LABELS[k].lower()} ({LEVEL_LABELS[v].lower()})" for k, v in now.items() if v != NONE)
        body = f"« {group.name} » partage maintenant : {shown}." if shown else f"« {group.name} » ne partage plus rien."
        if audience == GroupShare.Audience.UP:
            told, title = ([group.parent] if group.parent_id and group.parent.is_active else []), "Partage d’un groupe rattaché"
        elif audience == GroupShare.Audience.NEIGHBOURS:
            told, title = neighbours(group), "Partage d’un groupe voisin"
        else:
            told, title = twins(group), "Partage d’un groupe jumelé"
        for g in told:
            _tell(g, title, body)
    return settings_of(group, audience)


# --- What is shown -------------------------------------------------------------------------

def _members(level):
    from apps.accounts.models import RoleAssignment, User

    from .models import Membership

    ms = Membership.objects.filter(is_active=True).exclude(status="archive")
    by_status = dict(ms.values_list("status").annotate(n=Count("pk")))
    data = {"total": sum(n for s, n in by_status.items() if s != "classe"), "by_status": by_status}
    if level == DETAIL:
        roles = {}
        for user_id, name in RoleAssignment.objects.active().values_list("user_id", "role__name"):
            roles.setdefault(user_id, []).append(name)
        people = User.objects.members().filter(is_active=True).order_by("last_name", "first_name")
        data["people"] = [{"name": u.full_name, "roles": roles.get(u.pk, [])} for u in people]
    return data


def _finances(level):
    from apps.finances.models import Entry
    from apps.finances.services import balance, cur

    ok = Entry.objects.filter(status=Entry.Status.VALIDATED)
    year = ok.filter(date__year=timezone.localdate().year)
    agg = year.aggregate(i=_sum("in"), o=_sum("out"))
    data = {"currency": cur(), "balance": balance(ok), "year_in": agg["i"] or 0, "year_out": agg["o"] or 0}
    if level == DETAIL:
        data["entries"] = [{"date": e.date.isoformat(), "label": e.label, "direction": e.direction, "amount": e.amount,
                            "category": e.get_category_display()} for e in ok.order_by("-date", "-pk")[:30]]
    return data


def _sum(direction):
    from django.db.models import Sum

    return Sum("amount", filter=Q(direction=direction))


def _calendar(level):
    from apps.events.models import Event

    now = timezone.now()
    soon = Event.objects.filter(starts_at__gte=now, starts_at__lt=now + timedelta(days=30)).order_by("starts_at")
    data = {"upcoming": soon.count()}
    if level == DETAIL:
        data["events"] = [{"title": e.title, "starts_at": e.starts_at.isoformat(), "place": e.place} for e in soon[:30]]
    return data


def _announcements(level):
    from apps.announcements.models import Announcement

    rows = Announcement.objects.filter(kind=Announcement.Kind.ANNOUNCEMENT).order_by("-created_at")[:10]
    return {"items": [{"title": a.title, "body": a.body[:600], "created_at": a.created_at.isoformat()} for a in rows]}


def _reports(level):
    from apps.events.models import Event

    since = timezone.now() - timedelta(days=90)
    events = (Event.objects.filter(starts_at__gte=since, starts_at__lt=timezone.now())
              .annotate(p=Count("attendance", filter=Q(attendance__status="present")),
                        a=Count("attendance", filter=Q(attendance__status="absent")),
                        x=Count("attendance", filter=Q(attendance__status="excuse")))
              .order_by("-starts_at"))
    marked = [e for e in events if e.p + e.a + e.x]
    present = sum(e.p for e in marked)
    total = sum(e.p + e.a + e.x for e in marked)
    data = {"events": len(marked), "presence_rate": round(100 * present / total) if total else None}
    if level == DETAIL:
        data["rows"] = [{"title": e.title, "date": e.starts_at.isoformat(), "present": e.p, "absent": e.a, "excused": e.x,
                         "report": hasattr(e, "report")} for e in marked[:30]]
    return data


BUILDERS = {"members": _members, "finances": _finances, "calendar": _calendar,
            "announcements": _announcements, "reports": _reports}


def readable(kind, viewer):
    """May `viewer` (in the current, upper group) read this kind?"""
    return viewer.can(*KINDS[kind][1])


def shared_view(target, viewer, *, audience=GroupShare.Audience.UP):
    """What `viewer`, in the current group, may see of `target`."""
    levels = settings_of(target, audience)
    allowed = {k for k in KINDS if readable(k, viewer)}  # in the viewer's group, before switching
    out = {}
    with in_group(target):
        for kind, level in levels.items():
            if level == NONE:
                continue
            if kind not in allowed:
                out[kind] = {"level": level, "hidden": True}
                continue
            out[kind] = {"level": level, "data": BUILDERS[kind](level)}
    return out


def totals(groups):
    """Across the groups below that share their members: how many."""
    sharing = set(GroupShare.objects.filter(group__in=groups, audience=GroupShare.Audience.UP, kind="members")
                  .exclude(level=NONE).values_list("group_id", flat=True))
    members = 0
    for g in groups:
        if g.pk in sharing:
            with in_group(g):
                members += _members(SUMMARY)["total"]
    return {"groups": len(groups), "sharing_members": len(sharing), "members": members}
