"""Networks of groups (owner, 2026-11-03).

The MGS has a Garde Suisse group in many parishes; the parishes of a zone
paroissiale form the zone, the zones a diocese, like the government system.
On Huddle:

- the back-office creates a network, names its levels (at most 4) and puts
  groups in it at a level (owner: "Backoffice" creates the upper levels);
- an umbrella group (level 2+) invites a group of a lower level with a
  single-use code; that group's président accepts it in the app — both sides
  agree, nobody is attached without knowing;
- either side can end the link (the attached group's président in the app,
  the platform team in the back-office), with a reason;
- an umbrella informs the groups under it; it has no say in how they run
  (owner: "he just inform").

Every change is audited in both groups and their présidents are told.
"""

import secrets
from datetime import timedelta

from django.db import transaction
from django.utils import timezone

from . import audit
from .groups import in_group
from .models import Group, GroupInvitation, Network

INVITATION_DAYS = 14
ALPHABET = "ABCDEFGHJKMNPQRSTUVWXYZ23456789"  # no 0/O, 1/I/L


class NetworkRule(Exception):
    def __init__(self, code, message, status=400):
        super().__init__(message)
        self.code, self.message, self.status = code, message, status


def clean_code(raw):
    return "".join(c for c in str(raw or "").upper() if c.isalnum())[:8]


def presidents(group):
    """Who manages the group's name, logo and attachment (group.profile)."""
    from apps.accounts.models import RoleAssignment, User

    with in_group(group):
        ids = RoleAssignment.objects.active().filter(
            role__group=group, role__permissions__resource="group.profile", role__permissions__action="change"
        ).values("user")
        return list(User.objects.members().filter(pk__in=ids, is_active=True))


def _tell(group, title, body):
    from .notify import notify

    with in_group(group):
        notify(presidents(group), "network", title, body, {"type": "network"})


def _record(group, action, *, by, request, detail, platform=False):
    with in_group(group):
        audit.record(action, actor=by, obj=group, request=request, detail=detail, sensitive=True)
    if platform:
        audit.record(action, actor=by, obj=group, request=request, detail=detail, sensitive=True, platform=True)


# --- Back-office: networks and levels -------------------------------------------------

def save_network(*, by, request=None, network=None, name, levels):
    name = (name or "").strip()[:120]
    if not name:
        raise NetworkRule("name_required", "Le nom du réseau est obligatoire.")
    labels = [(levels[i] if i < len(levels) else "").strip()[:40] for i in range(4)]
    if not labels[0] or not labels[1]:
        raise NetworkRule("levels_required", "Nommez au moins les deux premiers niveaux (ex. Paroisse, Zone).")
    created = network is None
    network = network or Network(created_by=by)
    before = {"nom": network.name, "niveaux": [network.level1, network.level2, network.level3, network.level4]}
    network.name = name
    network.level1, network.level2, network.level3, network.level4 = labels
    used = [n for n in Network.LEVELS if not labels[n - 1]]
    if not created and network.groups.filter(level__in=used).exists():
        raise NetworkRule("level_in_use", "Un groupe est à ce niveau : gardez-lui un nom.")
    network.save()
    audit.record("Réseau créé" if created else "Réseau modifié", actor=by, obj=network, request=request, platform=True,
                 detail={"nom": name, "niveaux": labels} if created else {"avant": before, "apres": {"nom": name, "niveaux": labels}})
    return network


@transaction.atomic
def place_group(group, *, network, level, by, request=None):
    """Put a group in a network at a level (or out of any network). Refused
    while it would break its links: leave or detach them first."""
    level = int(level or 1)
    if network is not None and (level not in Network.LEVELS or not network.level_name(level)):
        raise NetworkRule("bad_level", "Ce niveau n’existe pas dans ce réseau.")
    if network is None:
        level = 1
    group = Group.objects.select_for_update().get(pk=group.pk)
    linked = group.parent_id is not None or group.children.filter(is_active=True).exists()
    if linked and network != group.network:
        raise NetworkRule("linked", "Ce groupe est rattaché ou a des groupes rattachés : détachez-les avant de changer de réseau.")
    if group.parent is not None and level >= group.parent.level:
        raise NetworkRule("above_parent", f"Le niveau doit rester sous celui de « {group.parent.name} ».")
    top_child = max((c.level for c in group.children.filter(is_active=True)), default=0)
    if level <= top_child:
        raise NetworkRule("below_children", "Le niveau doit rester au-dessus de celui des groupes rattachés.")
    before = {"reseau": str(group.network or "—"), "niveau": group.level}
    group.network, group.level = network, level
    group.save(update_fields=["network", "level"])
    if network is None or level == 1:
        GroupInvitation.objects.filter(umbrella=group, status=GroupInvitation.Status.PENDING).update(
            status=GroupInvitation.Status.REVOKED)
    audit.record("Groupe placé dans un réseau", actor=by, obj=group, request=request, platform=True, sensitive=True,
                 detail={"avant": before, "apres": {"reseau": str(network or "—"), "niveau": level}})
    return group


# --- Invitations -------------------------------------------------------------------------

def can_invite(group):
    return group.network_id is not None and group.level > 1 and group.is_active


def create_invitation(umbrella, *, by, request=None, platform=False):
    if not can_invite(umbrella):
        raise NetworkRule("not_umbrella", "Seul un groupe de niveau supérieur dans un réseau peut inviter.")
    for _ in range(10):
        code = "".join(secrets.choice(ALPHABET) for _ in range(8))
        if not GroupInvitation.objects.filter(code=code).exists():
            break
    inv = GroupInvitation.objects.create(umbrella=umbrella, code=code, created_by=by,
                                         expires_at=timezone.now() + timedelta(days=INVITATION_DAYS))
    _record(umbrella, "Invitation de rattachement créée", by=by, request=request, platform=platform,
            detail={"expire": inv.expires_at.date().isoformat()})
    return inv


def revoke_invitation(inv, *, by, request=None, platform=False):
    if inv.status != GroupInvitation.Status.PENDING:
        raise NetworkRule("not_pending", "Cette invitation n’est plus en attente.")
    inv.status = GroupInvitation.Status.REVOKED
    inv.save(update_fields=["status"])
    _record(inv.umbrella, "Invitation de rattachement annulée", by=by, request=request, platform=platform, detail={})


def pending_invitations(umbrella):
    return GroupInvitation.objects.filter(umbrella=umbrella, status=GroupInvitation.Status.PENDING,
                                          expires_at__gt=timezone.now())


def find_invitation(code, group):
    """The invitation behind `code`, checked for `group` (the one that
    would join). Raises NetworkRule with what's wrong."""
    code = clean_code(code)
    inv = GroupInvitation.objects.select_related("umbrella", "umbrella__network").filter(code=code).first() if len(code) == 8 else None
    if inv is None or inv.status == GroupInvitation.Status.REVOKED or not inv.umbrella.is_active:
        raise NetworkRule("unknown_invitation", "Code d’invitation inconnu. Vérifiez-le auprès du groupe qui vous invite.", 404)
    if inv.status == GroupInvitation.Status.USED:
        raise NetworkRule("used", "Ce code a déjà servi. Demandez-en un nouveau.")
    if inv.expires_at <= timezone.now():
        raise NetworkRule("expired", "Ce code a expiré. Demandez-en un nouveau.")
    u = inv.umbrella
    if u.pk == group.pk:
        raise NetworkRule("self", "Un groupe ne peut pas se rattacher à lui-même.")
    if group.parent_id is not None:
        raise NetworkRule("already", f"Votre groupe est déjà rattaché à « {group.parent.name} ». Détachez-le d’abord.", 409)
    if group.network_id and group.network_id != u.network_id:
        raise NetworkRule("other_network", "Ce groupe invite dans un autre réseau que le vôtre.")
    if group.level >= u.level:
        raise NetworkRule("level", f"« {u.name} » doit être d’un niveau supérieur au vôtre.")
    if u.pk in {d.pk for d in group.descendants()}:
        raise NetworkRule("loop", "Ce groupe est déjà rattaché au vôtre.")
    return inv


@transaction.atomic
def accept_invitation(code, group, *, by, request=None):
    inv = find_invitation(code, group)
    inv = GroupInvitation.objects.select_for_update().get(pk=inv.pk)
    if inv.status != GroupInvitation.Status.PENDING:
        raise NetworkRule("used", "Ce code a déjà servi. Demandez-en un nouveau.")
    u = inv.umbrella
    group.parent, group.network, group.attached_at = u, u.network, timezone.now()
    group.save(update_fields=["parent", "network", "attached_at"])
    inv.status, inv.used_by_group, inv.used_by, inv.used_at = GroupInvitation.Status.USED, group, by, timezone.now()
    inv.save(update_fields=["status", "used_by_group", "used_by", "used_at"])
    detail = {"groupe": group.name, "rattache_a": u.name}
    _record(group, "Groupe rattaché", by=by, request=request, detail=detail)
    _record(u, "Groupe rattaché", by=by, request=request, detail=detail)
    _tell(u, "Nouveau groupe rattaché", f"« {group.name} » a rejoint « {u.name} » ({u.network.level_name(group.level)}).")
    _tell(group, "Groupe rattaché", f"« {group.name} » est maintenant rattaché à « {u.name} ».")
    return u


@transaction.atomic
def detach(group, *, by, reason, request=None, platform=False):
    reason = (reason or "").strip()[:300]
    if len(reason) < 3:
        raise NetworkRule("detach_reason", "Indiquez le motif.")
    group = Group.objects.select_for_update().get(pk=group.pk)
    parent = group.parent
    if parent is None:
        raise NetworkRule("not_attached", "Ce groupe n’est rattaché à aucun groupe.")
    group.parent, group.attached_at = None, None
    group.save(update_fields=["parent", "attached_at"])
    detail = {"groupe": group.name, "detache_de": parent.name, "motif": reason}
    _record(group, "Groupe détaché", by=by, request=request, detail=detail, platform=platform)
    _record(parent, "Groupe détaché", by=by, request=request, detail=detail)
    _tell(parent, "Groupe détaché", f"« {group.name} » n’est plus rattaché à « {parent.name} ». Motif : {reason}")
    _tell(group, "Groupe détaché", f"« {group.name} » n’est plus rattaché à « {parent.name} ». Motif : {reason}")
    return parent


# --- What the app shows ---------------------------------------------------------------------

def summary(group, request=None, *, manage=False):
    from .identity import group_identity
    from .sharing import settings_of, totals

    def item(g):
        return {**group_identity(g, request), "level": g.level, "level_name": g.level_name}

    net = group.network
    data = {
        "network": {"name": net.name, "levels": [n for n in (net.level1, net.level2, net.level3, net.level4) if n]} if net else None,
        "level": group.level, "level_name": group.level_name,
        "parents": [item(g) for g in group.ancestors()],
        "children": [{**item(c), "children": len(c.descendants()),
                      "shares": [k for k, v in settings_of(c).items() if v != "none"]}
                     for c in group.children.filter(is_active=True).order_by("name")],
        "can_manage": manage, "can_invite": manage and can_invite(group),
        "invitations": [],
    }
    below = group.descendants()
    if below:
        data["totals"] = totals(below)
    data["sharing"] = settings_of(group) if group.parent_id else None
    if manage and can_invite(group):
        data["invitations"] = [{"code": i.pretty, "expires_at": i.expires_at.isoformat()} for i in pending_invitations(group)]
    return data


# --- What flows down (build 41) ------------------------------------------------------------

def upper_ids(group_id):
    """The active groups above `group_id` (their cascaded posts reach it)."""
    g = Group.objects.filter(pk=group_id).select_related("parent").first()
    return [a.pk for a in g.ancestors() if a.is_active] if g else []


def visible(model, group_id, **extra):
    """`model` rows of this group plus those its upper groups sent down."""
    from django.db.models import Q

    if group_id is None:  # no group chosen (one group on the platform): as before
        return model.objects.all()
    cond = Q(group_id=group_id)
    up = upper_ids(group_id)
    if up:
        cond |= Q(group_id__in=up, cascade=True, **extra)
    return model.all_groups.filter(cond)


def origin(obj, group_id, request=None):
    """The sending group, when a row comes from above; else None."""
    from .identity import group_identity

    if obj.group_id == group_id:
        return None
    cache = getattr(request, "_origins", None) if request is not None else None
    if cache is None:
        cache = {}
        if request is not None:
            request._origins = cache
    if obj.group_id not in cache:
        g = obj.group
        cache[obj.group_id] = {**group_identity(g, request), "level_name": g.level_name}
    return cache[obj.group_id]


def send_down(group, title, body, target, *, kind="announcement"):
    """Notify the members of every group below `group`, each in its group."""
    from apps.accounts.models import User

    from .notify import notify

    n = 0
    for g in group.descendants():
        with in_group(g):
            people = User.objects.members().filter(gstatus__in=[User.Status.ACTIVE, User.Status.LEAVE], is_active=True)
            n += notify(people, kind, title, body, target)
    return n
