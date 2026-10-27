"""Who serves at an event (owner, 2026-10-27): for an event with a service
lineup, the roll call lists only the guards lined up for it (and the chef de
groupe), each with their post; other events keep the whole membership."""

from apps.planning.models import POSTS, Assignment, Service


def lineup(event):
    """member id → {post, side, chef} in lineup order, chef first; None when
    the event has no service lineup."""
    service = Service.objects.filter(event=event).first()
    if service is None:
        return None
    rows = Assignment.objects.filter(service=service).exclude(status=Assignment.Status.REPLACED)
    duties = {a.member_id: {"post": a.post, "side": a.side, "chef": a.member_id == event.chef_id}
              for a in sorted(rows, key=lambda a: (POSTS.index(a.post), a.side, a.index))}
    if event.chef_id and event.chef_id not in duties:
        duties[event.chef_id] = {"post": "", "side": "", "chef": True}
    return dict(sorted(duties.items(), key=lambda kv: not kv[1]["chef"]))


def viewer_duties(user, events):
    """(ids of the events that have a lineup, event id → the viewer's duty)."""
    ids = [e.pk for e in events]
    with_lineup = set(Service.objects.filter(event_id__in=ids).values_list("event_id", flat=True))
    mine = {}
    for a in Assignment.objects.filter(service__event_id__in=ids, member=user).exclude(status=Assignment.Status.REPLACED):
        mine[a.service.event_id] = {"post": a.post, "side": a.side}
    for e in events:
        if e.chef_id == user.pk:
            mine.setdefault(e.pk, {"post": "", "side": ""})["chef"] = True
    return with_lineup, mine
