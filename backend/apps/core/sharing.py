"""What a group shares with its network (owner, 2026-11-03).

Each group's président chooses, kind by kind, what the groups above it may
see: nothing (the default), a summary, or the detail. In the upper group,
each kind is read only by those whose role there covers it (its treasurer
reads the finances, its secretary the members…), so sharing upward never
shows more than the umbrella's own officers handle.

Never shared, whatever the setting: phone numbers, PINs, minors' contacts,
members' personal statements. Announcements' photos and files only at
"detail" (build 48; until then "detail" was the text, now "summary").

A group may ask a linked group to share more (build 48): the asked group's
président accepts — for that whole audience — or declines.
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
    "announcements": ((SUMMARY, DETAIL), ("announcements.posts", "view")),
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

def _members(level, request=None):
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


def _finances(level, request=None):
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


def _calendar(level, request=None):
    from apps.events.models import Event

    now = timezone.now()
    soon = Event.objects.filter(starts_at__gte=now, starts_at__lt=now + timedelta(days=30)).order_by("starts_at")
    data = {"upcoming": soon.count()}
    if level == DETAIL:
        data["events"] = [{"title": e.title, "starts_at": e.starts_at.isoformat(), "place": e.place} for e in soon[:30]]
    return data


def _announcements(level, request=None):
    """For the whole group (not the ones naming members), own posts only."""
    from apps.announcements.models import Announcement

    rows = (Announcement.objects.filter(kind=Announcement.Kind.ANNOUNCEMENT, tagged__isnull=True)
            .prefetch_related("attachments").order_by("-created_at")[:10])
    items = []
    for a in rows:
        item = {"title": a.title, "body": a.body[:600], "created_at": a.created_at.isoformat()}
        if level == DETAIL:
            item["attachments"] = [_file(f, request) for f in a.attachments.all()]
        items.append(item)
    return {"items": items}


def _file(f, request):
    url = f.file.url  # signed and short-lived on S3/Supabase
    if request is not None and url.startswith("/"):
        url = request.build_absolute_uri(url)
    return {"id": f.pk, "name": f.name, "size": f.size, "content_type": f.content_type, "url": url}


def _reports(level, request=None):
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


def shared_view(target, viewer, *, audience=GroupShare.Audience.UP, request=None, levels=None):
    """What `viewer`, in the current group, may see of `target` (or, with
    `levels`, would see: the président's preview of their own group)."""
    levels = levels or settings_of(target, audience)
    allowed = {k for k in KINDS if readable(k, viewer)}  # in the viewer's group, before switching
    out = {}
    with in_group(target):
        for kind, level in levels.items():
            if kind not in KINDS or level == NONE:
                continue
            if kind not in allowed:
                out[kind] = {"level": level, "hidden": True}
                continue
            out[kind] = {"level": level, "data": BUILDERS[kind](level, request)}
    return out


def preview(group, viewer, values, request=None):
    """The président's "Aperçu": `group` as others would see it with
    `values`. Kinds the viewer can't read in their own group stay hidden."""
    levels = {k: v for k, v in (values or {}).items() if k in KINDS and (v == NONE or v in KINDS[k][0])}
    return shared_view(group, viewer, request=request, levels=levels)


def kinds_view(viewer_group, target, viewer, audience, request=None):
    """Every kind, as the viewer stands with it (build 48): shared and
    readable, shared but for other roles, or not shared (with what more it
    could share and any request this group made)."""
    from .models import ShareRequest

    shown = shared_view(target, viewer, audience=audience, request=request)
    pending = {r.kind: r for r in ShareRequest.objects.filter(from_group=viewer_group, target=target,
                                                              status=ShareRequest.Status.PENDING)}
    last = {}
    for r in ShareRequest.objects.filter(from_group=viewer_group, target=target).exclude(
            status=ShareRequest.Status.PENDING).order_by("created_at"):
        last[r.kind] = r
    asker = may_ask(viewer)
    out = []
    for kind, (levels, _) in KINDS.items():
        got = shown.get(kind, {"level": NONE})
        level = got["level"]
        more = [lv for lv in levels if _rank(lv) > _rank(level)]
        state = "hidden" if got.get("hidden") else ("shared" if level != NONE else "none")
        row = {"kind": kind, "level": level, "state": state, "levels": list(levels), "data": got.get("data"),
               "request": request_row(pending[kind], request) if kind in pending else None,
               "last_answer": request_row(last[kind], request) if kind in last else None,
               "can_request": bool(more) and state != "hidden" and kind not in pending and asker(kind),
               "next_level": more[0] if more else None}
        out.append(row)
    return out


def _rank(level):
    return {NONE: 0, SUMMARY: 1, DETAIL: 2}.get(level, 0)


def may_ask(viewer):
    """Who in a group may ask for more: whoever would read that kind, or
    the président."""
    pres = viewer.can("group.profile", "change")
    return lambda kind: pres or readable(kind, viewer)


def request_row(r, request=None):
    from .identity import group_identity

    return {"id": r.pk, "kind": r.kind, "level": r.level, "audience": r.audience, "note": r.note, "status": r.status,
            "from_group": group_identity(r.from_group, request), "target": group_identity(r.target, request),
            "by": r.created_by.short_name if r.created_by else "", "created_at": r.created_at.isoformat(),
            "answered_at": r.answered_at.isoformat() if r.answered_at else None, "answer_note": r.answer_note,
            "current": settings_of(r.target, r.audience)[r.kind] if r.status == "pending" else None}


# --- Asking for more (build 48) ----------------------------------------------------------------

def ask(viewer_group, target, kind, level, *, by, note="", request=None):
    from .models import ShareRequest
    from .network import presidents, relation

    rel = relation(viewer_group, target)
    if rel is None:
        raise SharingRule("not_linked", "Ce groupe n’est pas lié au vôtre.", 404)
    if kind not in KINDS or level not in KINDS[kind][0]:
        raise SharingRule("bad_level", "Niveau de partage impossible.")
    if not may_ask(by)(kind):
        raise SharingRule("forbidden", "Votre rôle ne permet pas de demander ce partage.", 403)
    if _rank(level) <= _rank(settings_of(target, rel)[kind]):
        raise SharingRule("already_shared", "Ce groupe partage déjà cela.")
    if ShareRequest.objects.filter(from_group=viewer_group, target=target, kind=kind, status=ShareRequest.Status.PENDING).exists():
        raise SharingRule("already_asked", "Une demande est déjà en attente.", 409)
    note = (note or "").strip()[:300]
    r = ShareRequest.objects.create(from_group=viewer_group, target=target, audience=rel, kind=kind, level=level,
                                    note=note, created_by=by)
    detail = {"groupe": target.name, "partage": f"{LABELS[kind]} ({LEVEL_LABELS[level].lower()})"}
    with in_group(viewer_group):
        audit.record("Demande de partage envoyée", actor=by, obj=viewer_group, request=request, detail=detail)
    with in_group(target):
        audit.record("Demande de partage reçue", actor=by, obj=target, request=request,
                     detail={"de": viewer_group.name, "partage": detail["partage"]})
    body = f"« {viewer_group.name} » demande : {LABELS[kind].lower()} ({LEVEL_LABELS[level].lower()})."
    from .notify import notify

    with in_group(target):
        notify(presidents(target), "network", "Demande de partage", f"{body} {note}".strip(), {"type": "share_requests"})
    return r


def cancel(r, *, by, request=None):
    from .models import ShareRequest

    if r.status != ShareRequest.Status.PENDING:
        raise SharingRule("not_pending", "Cette demande n’est plus en attente.", 409)
    r.status, r.answered_by, r.answered_at = ShareRequest.Status.CANCELLED, by, timezone.now()
    r.save(update_fields=["status", "answered_by", "answered_at"])
    with in_group(r.from_group):
        audit.record("Demande de partage annulée", actor=by, obj=r.from_group, request=request,
                     detail={"groupe": r.target.name, "partage": LABELS[r.kind]})


def answer(r, accept, *, by, note="", request=None):
    """The asked group's président. Accepting shares that kind at that level
    with the whole audience (every group above, every neighbour…)."""
    from apps.accounts.models import User

    from .models import ShareRequest
    from .notify import notify

    if r.status != ShareRequest.Status.PENDING:
        raise SharingRule("not_pending", "Cette demande n’est plus en attente.", 409)
    note = (note or "").strip()[:300]
    if accept and _rank(settings_of(r.target, r.audience)[r.kind]) < _rank(r.level):
        save_settings(r.target, {r.kind: r.level}, by=by, request=request, audience=r.audience)
    r.status = ShareRequest.Status.ACCEPTED if accept else ShareRequest.Status.DECLINED
    r.answered_by, r.answered_at, r.answer_note = by, timezone.now(), note
    r.save(update_fields=["status", "answered_by", "answered_at", "answer_note"])
    what = f"{LABELS[r.kind].lower()} ({LEVEL_LABELS[r.level].lower()})"
    with in_group(r.target):
        audit.record("Demande de partage acceptée" if accept else "Demande de partage refusée", actor=by, obj=r.target,
                     request=request, detail={"de": r.from_group.name, "partage": what, **({"motif": note} if note else {})})
    title = "Partage accepté" if accept else "Partage refusé"
    body = (f"« {r.target.name} » partage maintenant : {what}." if accept
            else f"« {r.target.name} » ne partage pas : {what}.") + (f" {note}" if note else "")
    from .network import presidents

    with in_group(r.from_group):
        people = {u.pk: u for u in presidents(r.from_group)}
        if r.created_by_id and r.created_by.is_active:
            people.setdefault(r.created_by_id, r.created_by)
        people = User.objects.members().filter(pk__in=list(people))
        notify(people, "network", title, body, {"type": "network_group", "id": r.target_id})
    return r


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
