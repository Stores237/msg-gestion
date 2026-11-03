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
from .models import Group, GroupInvitation, GroupLink, Network

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
    labels = [(levels[i] if i < len(levels) else "").strip()[:40] or "" for i in range(len(Network.LEVELS))]
    if not labels[0] or not labels[1]:
        raise NetworkRule("levels_required", "Nommez au moins les deux premiers niveaux (ex. Paroisse, Zone).")
    created = network is None
    network = network or Network(created_by=by)
    before = {"nom": network.name, "niveaux": network.labels}
    network.name = name
    for i, label in enumerate(labels, start=1):
        setattr(network, f"level{i}", label)
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
        GroupInvitation.objects.filter(umbrella=group, kind=GroupInvitation.Kind.ATTACH,
                                       status=GroupInvitation.Status.PENDING).update(
            status=GroupInvitation.Status.REVOKED)
    audit.record("Groupe placé dans un réseau", actor=by, obj=group, request=request, platform=True, sensitive=True,
                 detail={"avant": before, "apres": {"reseau": str(network or "—"), "niveau": level}})
    return group


# --- Invitations -------------------------------------------------------------------------

def can_invite(group):
    return group.network_id is not None and group.level > 1 and group.is_active


def create_invitation(umbrella, *, by, request=None, platform=False, kind=GroupInvitation.Kind.ATTACH):
    if kind == GroupInvitation.Kind.ATTACH and not can_invite(umbrella):
        raise NetworkRule("not_umbrella", "Seul un groupe de niveau supérieur dans un réseau peut inviter.")
    for _ in range(10):
        code = "".join(secrets.choice(ALPHABET) for _ in range(8))
        if not GroupInvitation.objects.filter(code=code).exists():
            break
    inv = GroupInvitation.objects.create(umbrella=umbrella, code=code, created_by=by, kind=kind,
                                         expires_at=timezone.now() + timedelta(days=INVITATION_DAYS))
    _record(umbrella, "Code de jumelage créé" if kind == GroupInvitation.Kind.TWIN else "Invitation de rattachement créée", by=by, request=request, platform=platform,
            detail={"expire": inv.expires_at.date().isoformat()})
    return inv


def revoke_invitation(inv, *, by, request=None, platform=False):
    if inv.status != GroupInvitation.Status.PENDING:
        raise NetworkRule("not_pending", "Cette invitation n’est plus en attente.")
    inv.status = GroupInvitation.Status.REVOKED
    inv.save(update_fields=["status"])
    _record(inv.umbrella, "Invitation de rattachement annulée", by=by, request=request, platform=platform, detail={})


def pending_invitations(umbrella, kind=GroupInvitation.Kind.ATTACH):
    return GroupInvitation.objects.filter(umbrella=umbrella, kind=kind, status=GroupInvitation.Status.PENDING,
                                          expires_at__gt=timezone.now())


def find_invitation(code, group, kind=GroupInvitation.Kind.ATTACH):
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
    if inv.kind != kind:
        raise NetworkRule("wrong_kind", "C’est un code de jumelage : utilisez « Accepter un jumelage »."
                          if inv.kind == GroupInvitation.Kind.TWIN else
                          "C’est un code de rattachement : utilisez « Rejoindre avec un code ».")
    u = inv.umbrella
    if kind == GroupInvitation.Kind.TWIN:
        if u.pk == group.pk:
            raise NetworkRule("self", "Un groupe ne peut pas se jumeler avec lui-même.")
        if link_between(u, group) is not None:
            raise NetworkRule("already_twinned", f"Votre groupe est déjà jumelé avec « {u.name} ».", 409)
        return inv
    _check_attach(group, u)
    return inv


def _check_attach(group, u):
    if u.pk == group.pk:
        raise NetworkRule("self", "Un groupe ne peut pas se rattacher à lui-même.")
    if group.parent_id is not None:
        raise NetworkRule("already", f"« {group.name} » est déjà rattaché à « {group.parent.name} ». Détachez-le d’abord.", 409)
    if group.network_id and group.network_id != u.network_id:
        raise NetworkRule("other_network", "Ce groupe invite dans un autre réseau que le vôtre.")
    if group.level >= u.level:
        raise NetworkRule("level", f"« {u.name} » doit être d’un niveau supérieur à « {group.name} ».")
    if u.pk in {d.pk for d in group.descendants()}:
        raise NetworkRule("loop", "Ce groupe est déjà rattaché au vôtre.")


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
        # "waiting": set up by the platform team, no président yet (« à compléter »).
        return {**group_identity(g, request), "level": g.level, "level_name": g.level_name,
                "waiting": not has_president(g)}

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
    near, linked = neighbours(group), twins(group)
    data["neighbours"] = [{**item(g), "shares": [k for k, v in settings_of(g, "neighbours").items() if v != "none"]} for g in near]
    data["twins"] = [{**item(g), "shares": [k for k, v in settings_of(g, "twins").items() if v != "none"]} for g in linked]
    data["sharing_neighbours"] = settings_of(group, "neighbours") if near else None
    data["sharing_twins"] = settings_of(group, "twins") if linked else None
    data["twin_invitations"] = ([{"code": i.pretty, "expires_at": i.expires_at.isoformat()}
                                 for i in pending_invitations(group, GroupInvitation.Kind.TWIN)] if manage else [])
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


# --- Links between groups (build 43) ---------------------------------------------------------

def neighbours(group):
    """The other active groups attached to the same parent."""
    if group.parent_id is None:
        return []
    return list(Group.objects.filter(parent_id=group.parent_id, is_active=True).exclude(pk=group.pk).order_by("name"))


def _pair(g1, g2):
    return (g1, g2) if g1.pk < g2.pk else (g2, g1)


def link_between(g1, g2):
    a, b = _pair(g1, g2)
    return GroupLink.objects.filter(a=a, b=b, is_active=True).first()


def twins(group):
    from django.db.models import Q

    links = GroupLink.objects.filter(Q(a=group) | Q(b=group), is_active=True).select_related("a", "b")
    return sorted((lk.other(group) for lk in links if lk.other(group).is_active), key=lambda g: g.name)


def relation(viewer_group, target):
    """How `target` relates to the viewer's group, for sharing: "up" (it is
    below), "neighbours", "twins", or None."""
    if target.pk in {d.pk for d in viewer_group.descendants()}:
        return "up"
    if viewer_group.parent_id and target.parent_id == viewer_group.parent_id and target.pk != viewer_group.pk:
        return "neighbours"
    if link_between(viewer_group, target) is not None:
        return "twins"
    return None


@transaction.atomic
def accept_twin(code, group, *, by, request=None):
    inv = find_invitation(code, group, kind=GroupInvitation.Kind.TWIN)
    inv = GroupInvitation.objects.select_for_update().get(pk=inv.pk)
    if inv.status != GroupInvitation.Status.PENDING:
        raise NetworkRule("used", "Ce code a déjà servi. Demandez-en un nouveau.")
    other = inv.umbrella
    a, b = _pair(group, other)
    link, _ = GroupLink.objects.get_or_create(a=a, b=b, defaults={"created_by": by})
    link.is_active, link.ended_at, link.ended_by, link.ended_reason, link.created_by = True, None, None, "", by
    link.save()
    inv.status, inv.used_by_group, inv.used_by, inv.used_at = GroupInvitation.Status.USED, group, by, timezone.now()
    inv.save(update_fields=["status", "used_by_group", "used_by", "used_at"])
    detail = {"groupes": [group.name, other.name]}
    _record(group, "Groupes jumelés", by=by, request=request, detail=detail)
    _record(other, "Groupes jumelés", by=by, request=request, detail=detail)
    _tell(other, "Nouveau jumelage", f"« {group.name} » et « {other.name} » sont jumelés.")
    _tell(group, "Nouveau jumelage", f"« {group.name} » et « {other.name} » sont jumelés.")
    return other


@transaction.atomic
def end_twin(group, other, *, by, reason, request=None, platform=False):
    reason = (reason or "").strip()[:300]
    if len(reason) < 3:
        raise NetworkRule("detach_reason", "Indiquez le motif.")
    link = link_between(group, other)
    if link is None:
        raise NetworkRule("not_twinned", "Ces groupes ne sont pas jumelés.", 404)
    link.is_active, link.ended_at, link.ended_by, link.ended_reason = False, timezone.now(), by, reason
    link.save(update_fields=["is_active", "ended_at", "ended_by", "ended_reason"])
    detail = {"groupes": [group.name, other.name], "motif": reason}
    _record(group, "Jumelage terminé", by=by, request=request, detail=detail, platform=platform)
    _record(other, "Jumelage terminé", by=by, request=request, detail=detail)
    for g in (group, other):
        _tell(g, "Jumelage terminé", f"« {group.name} » et « {other.name} » ne sont plus jumelés. Motif : {reason}")


# --- Setting up a network from the back-office (build 46) ------------------------------------

def has_president(group):
    """Someone holds the group's name/logo/attachment right (group.profile)."""
    from apps.accounts.models import RoleAssignment

    with in_group(group):
        return RoleAssignment.objects.active().filter(
            role__group=group, role__permissions__resource="group.profile", role__permissions__action="change").exists()


def level_model(network, level):
    from .models import NetworkLevelModel

    m = NetworkLevelModel.objects.filter(network=network, level=level).select_related("group").first()
    return m.group if m and m.group.is_active else None


def set_level_model(network, level, group, *, by, request=None):
    from .models import NetworkLevelModel

    if group.network_id != network.pk or group.level != int(level):
        raise NetworkRule("bad_model", "Le modèle doit être un groupe de ce réseau, à ce niveau.")
    NetworkLevelModel.objects.update_or_create(network=network, level=level, defaults={"group": group})
    audit.record("Modèle de rôles choisi", actor=by, obj=network, request=request, platform=True,
                 detail={"niveau": network.level_name(level), "groupe": group.name})


@transaction.atomic
def attach_direct(group, parent, *, by, request=None):
    """The platform team places a group it set up, which has no président
    yet, under `parent` — no code needed: nobody there to ask. A group with a
    président joins with a code, as before."""
    group = Group.objects.select_for_update().get(pk=group.pk)
    if has_president(group):
        raise NetworkRule("has_president", f"« {group.name} » a un président : envoyez-lui un code d’invitation.")
    if parent.network_id is None:
        raise NetworkRule("parent_outside", f"« {parent.name} » n’est dans aucun réseau.")
    _check_attach(group, parent)
    group.parent, group.network, group.attached_at = parent, parent.network, timezone.now()
    group.save(update_fields=["parent", "network", "attached_at"])
    detail = {"groupe": group.name, "rattache_a": parent.name, "par": "équipe Huddle"}
    _record(group, "Groupe rattaché", by=by, request=request, detail=detail, platform=True)
    _record(parent, "Groupe rattaché", by=by, request=request, detail=detail)
    _tell(parent, "Nouveau groupe rattaché",
          f"« {group.name} » a été rattaché à « {parent.name} » par l’équipe Huddle ({group.level_name}).")
    return group


@transaction.atomic
def create_in_network(*, name, network, level, parent=None, preset=None, place="", by, request=None):
    """A new group, set up by the platform team, straight in its place: its
    roles come from the level's model group, else from `preset`
    (group_admin.ROLE_PRESETS); the first group of a level becomes its model."""
    from .group_admin import ROLE_PRESETS, create_group, default_preset

    level = int(level or 1)
    if level not in Network.LEVELS or not network.level_name(level):
        raise NetworkRule("bad_level", "Ce niveau n’existe pas dans ce réseau.")
    name = (name or "").strip()[:120]
    if not name:
        raise NetworkRule("name_required", "Le nom du groupe est obligatoire.")
    if Group.objects.filter(name__iexact=name, is_active=True).exists():
        raise NetworkRule("name_taken", f"Un groupe s’appelle déjà « {name} ».")
    if parent is not None and parent.level <= level:
        raise NetworkRule("level", f"« {parent.name} » doit être d’un niveau supérieur.")
    model = level_model(network, level)
    if model is not None:
        g = create_group(name=name, place=place, by=by, request=request, template=model)
    else:
        key = preset if preset in ROLE_PRESETS else default_preset(level)
        g = create_group(name=name, place=place, by=by, request=request, roles=ROLE_PRESETS[key][1])
    g = place_group(g, network=network, level=level, by=by, request=request)
    if model is None:
        set_level_model(network, level, g, by=by, request=request)
    if parent is not None:
        g = attach_direct(g, parent, by=by, request=request)
    return g


def import_groups(network, text, *, by, request=None):
    """One group per line: « Nom ; niveau ; rattaché à » (niveau: its number
    or its name; « rattaché à »: a group of the network, possibly created on
    an earlier line). All or nothing; the error names the line."""
    rows = [ln for ln in (text or "").replace("\r", "").split("\n") if ln.strip() and not ln.strip().startswith("#")]
    if not rows:
        raise NetworkRule("empty_import", "Collez au moins une ligne : Nom ; niveau ; rattaché à.")
    if len(rows) > 300:
        raise NetworkRule("too_many", "300 lignes au plus par import.")
    names = {n.lower(): i for i, n in enumerate(network.labels, start=1) if n}
    created = []
    with transaction.atomic():
        for no, line in enumerate(rows, start=1):
            parts = [p.strip() for p in line.split(";")]
            name, lvl, parent_name = (parts + ["", "", ""])[:3]
            level = int(lvl) if lvl.isdigit() else names.get(lvl.lower())
            if not name or not level:
                raise NetworkRule("bad_line", f"Ligne {no} : « {line.strip()} » — attendu « Nom ; niveau ; rattaché à ».")
            parent = None
            if parent_name:
                parent = Group.objects.filter(name__iexact=parent_name, network=network, is_active=True).first()
                if parent is None:
                    raise NetworkRule("bad_parent", f"Ligne {no} : « {parent_name} » n’est pas un groupe de ce réseau.")
            try:
                created.append(create_in_network(name=name, network=network, level=level, parent=parent, by=by,
                                                 request=request))
            except NetworkRule as e:
                raise NetworkRule(e.code, f"Ligne {no} : {e.message}") from None
    return created
