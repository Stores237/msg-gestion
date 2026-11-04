"""A demo network to try networks of groups end to end (owner, 2026-11-03:
"create other groups to test my hypothesis and see how it functions").

    python manage.py seed_network_demo --out demo-network.txt
    python manage.py seed_network_demo --delete

It builds, through the same code the app and back-office use (invitation
codes, sharing, sending down, contingents, contributions, twinning):

    MGS Cameroun (démo): Paroisse › Zone paroissiale › Diocèse › Province ecclésiastique › National
      Archidiocèse de Douala (démo)                       (groups stop at the diocese for now)
        Zone Wouri 9 (démo) ── GS Yapoma, GS Bonamoussadi, GS Kotto, and
                               GS Paroisse 4–7 « à compléter » (no président yet)
        Zone Akwa (démo)    ── GS Akwa, GS Bonapriso
    Chorale Sainte-Cécile (démo), in no network, twinned with GS Kotto (démo)

The upper groups get their level's roles (owner, 2026-11-03): the diocese an
aumônier diocésain and its bureau, the zones a coordinateur de zone and
theirs. The platform team places the groups it sets up; GS Yapoma, which
"already runs itself", joins Zone Wouri 9 with an invitation code. Every
active group gets its officers and four members (made-up names, phone
numbers 600 000 1xx, which no operator gives out). They all share one PIN, written to --out (or printed
when there is no --out). Nothing outside the "(démo)" groups is touched;
--delete removes them and their people.
"""

import secrets
from datetime import date, datetime, time, timedelta

from django.core.management.base import BaseCommand, CommandError
from django.db import transaction
from django.utils import timezone

SUFFIX = " (démo)"
NETWORK = "MGS Cameroun" + SUFFIX
LEVELS = ["Paroisse", "Zone paroissiale", "Diocèse", "Province ecclésiastique", "National"]
PHONE_BASE = 600000100

# name, sigle, level, parent name (without the suffix), colour
DIOCESE, ZONE, ZONE2 = "Archidiocèse de Douala", "Zone Wouri 9", "Zone Akwa"
GROUPS = [
    (DIOCESE, "ADD", 3, None, "#5B3A8C"),
    (ZONE, "ZW9", 2, DIOCESE, "#1E6FB8"),
    (ZONE2, "ZAK", 2, DIOCESE, "#B8541E"),
    ("GS Yapoma", "GSY", 1, ZONE, "#2E7D46"),
    ("GS Bonamoussadi", "GSB", 1, ZONE, "#0E9F8F"),
    ("GS Kotto", "GSK", 1, ZONE, "#3E6B2E"),
    ("GS Akwa", "GSA", 1, ZONE2, "#8C6D1F"),
    ("GS Bonapriso", "GSP", 1, ZONE2, "#A33B5C"),
]
WAITING = [f"GS Paroisse {i}" for i in range(4, 8)]  # « à compléter »: in place, no président yet
CHOIR = "Chorale Sainte-Cécile"
# Officers by level (role slugs; their names come from the level's roles).
OFFICERS = {1: ["president", "tresorier", "commissaire-aux-comptes", "formateur"],
            2: ["president", "vice-president", "tresorier", "commissaire-aux-comptes"],
            3: ["conseiller", "president", "tresorier", "commissaire-aux-comptes"]}
LAST = ["Ewane", "Ngo Bassa", "Mbarga", "Tchoupo", "Fouda", "Nkoulou", "Abena", "Ekotto", "Manga", "Essomba",
        "Ndjock", "Etoundi", "Mvondo", "Kamga", "Bilong", "Owona"]
FIRST = ["Brice", "Sandrine", "Arnaud", "Clarisse", "Joël", "Prisca", "Hervé", "Larissa", "Serge", "Nadège",
         "Yannick", "Mireille", "Patrick", "Carine", "Thierry", "Estelle"]


def demo(name):
    return name + SUFFIX


class Command(BaseCommand):
    help = "Create (or --delete) a demo network of groups to try networks end to end."

    def add_arguments(self, parser):
        parser.add_argument("--out", help="File to write the demo accounts and their PIN to.")
        parser.add_argument("--delete", action="store_true", help="Remove the demo network, its groups and people.")

    def handle(self, *args, **opts):
        if opts["delete"]:
            n_groups, n_rows = self.delete()
            self.stdout.write(f"Removed {n_groups} demo groups and their people ({n_rows} rows).")
            return
        if exists():
            raise CommandError("The demo network already exists. Run with --delete first to start again.")
        pin = self.pick_pin()
        with transaction.atomic():
            people = self.build(pin)
        lines = [f"Réseau de démonstration « {NETWORK} » — PIN de tous les comptes : {pin}", ""]
        for group, rows in people:
            lines.append(group)
            lines += [f"  {role:<26} {name:<26} {phone}" for role, name, phone in rows]
            lines.append("")
        text = "\n".join(lines)
        if opts["out"]:
            with open(opts["out"], "w") as f:
                f.write(text)
            self.stdout.write(f"Demo network created: {len(people)} groups. Accounts and PIN written to {opts['out']}.")
        else:
            self.stdout.write(text)

    @staticmethod
    def pick_pin():
        from apps.accounts.services import pin_problem

        while True:
            pin = f"{secrets.randbelow(10000):04d}"
            if pin_problem(pin) is None:
                return pin

    # --- building ------------------------------------------------------------------------

    def build(self, pin):
        from apps.core.group_admin import create_group
        from apps.core.groups import in_group
        from apps.core.models import GroupInvitation, Settings
        from apps.core.network import accept_invitation, accept_twin, create_in_network, create_invitation, save_network

        net = save_network(by=None, name=NETWORK, levels=LEVELS)
        groups, officers, members, listing = {}, {}, {}, []
        phone = PHONE_BASE
        names = iter([(ln, fn) for ln in LAST for fn in FIRST][::3])
        for name, short, level, parent, color in [*GROUPS, (CHOIR, "CSC", 1, None, "#C0392B")]:
            if name == CHOIR:
                g = create_group(name=demo(name), place="Douala", motto="Groupe de démonstration")
            else:
                # Set up by the platform team, in place — except GS Yapoma, which joins with a code below.
                up = groups[parent] if parent and name != "GS Yapoma" else None
                g = create_in_network(name=demo(name), network=net, level=level, parent=up, place="Douala", by=None)
            g.short_name = short
            g.save(update_fields=["short_name"])
            st = Settings.get(g)
            st.color, st.motto = color, "Groupe de démonstration"
            st.save(update_fields=["color", "motto"])
            groups[name] = g
            rows = []
            with in_group(g):
                for slug in [*OFFICERS[level], "membre", "membre", "membre", "membre"]:
                    last, first = next(names)
                    u = self.person(g, slug, last, first, phone, pin)
                    rows.append((u.role_name, u.full_name, u.phone))
                    if slug == "membre":
                        members.setdefault(name, []).append(u)
                    else:
                        officers.setdefault(name, {})[slug] = u
                    phone += 1
            listing.append((demo(name), rows))
        for name in WAITING:
            groups[name] = create_in_network(name=demo(name), network=net, level=1, parent=groups[ZONE], by=None)
            listing.append((demo(name), [("(à compléter : pas encore de président)", "", "")]))

        # GS Yapoma already runs itself: its président joins the zone with the zone's code.
        code = create_invitation(groups[ZONE], by=officers[ZONE]["president"]).code
        with in_group(groups["GS Yapoma"]):
            accept_invitation(code, groups["GS Yapoma"], by=officers["GS Yapoma"]["president"])
        for g in groups.values():
            g.refresh_from_db()

        # Twinning: the choir with GS Kotto.
        twin = create_invitation(groups[CHOIR], by=officers[CHOIR]["president"], kind=GroupInvitation.Kind.TWIN)
        with in_group(groups["GS Kotto"]):
            accept_twin(twin.code, groups["GS Kotto"], by=officers["GS Kotto"]["president"])

        self.share(groups, officers)
        self.everyday_life(groups, officers, members)
        self.from_above(groups, officers, members)
        return listing

    def person(self, group, slug, last, first, phone, pin):
        from django.contrib.auth.hashers import make_password

        from apps.accounts.models import Role, RoleAssignment, User
        from apps.core.models import Membership

        # One hash for everyone: hashing is deliberately slow (~0.2 s each),
        # and 68 of them pushed the back-office request past its time limit.
        if getattr(self, "_pin_hash", None) is None:
            self._pin_hash = make_password(pin)
        u = User(phone=f"+237{phone}", last_name=last, first_name=first, status="actif", city="Douala",
                 birth_date=date(1990 + phone % 15, 1 + phone % 12, 1 + phone % 27), pin=self._pin_hash)
        u.set_unusable_password()
        u.save()
        Membership.join(u, group.pk)
        role = Role.all_groups.get(group=group, slug=slug)
        RoleAssignment.objects.create(user=u, role=role, starts_on=date.today() - timedelta(days=90),
                                      reason="Réseau de démonstration")
        u.role_name = role.name
        return u

    def share(self, groups, officers):
        from apps.core.sharing import save_settings

        for name in ("GS Yapoma", "GS Bonamoussadi", "GS Kotto", "GS Akwa", "GS Bonapriso"):
            save_settings(groups[name], {"members": "detail", "finances": "summary", "calendar": "detail",
                                         "reports": "summary"}, by=officers[name]["president"])
        for name in (ZONE, ZONE2):
            save_settings(groups[name], {"members": "summary", "finances": "summary", "announcements": "detail"},
                          by=officers[name]["president"])
        # GS Bonapriso keeps its finances to itself.
        save_settings(groups["GS Bonapriso"], {"finances": "none"}, by=officers["GS Bonapriso"]["president"])
        save_settings(groups["GS Bonamoussadi"], {"calendar": "detail"}, by=officers["GS Bonamoussadi"]["president"],
                      audience="neighbours")
        save_settings(groups["GS Kotto"], {"calendar": "summary", "members": "summary"},
                      by=officers["GS Kotto"]["president"], audience="neighbours")
        save_settings(groups[CHOIR], {"announcements": "detail", "calendar": "detail"},
                      by=officers[CHOIR]["president"], audience="twins")
        save_settings(groups["GS Kotto"], {"calendar": "summary"}, by=officers["GS Kotto"]["president"], audience="twins")

    def everyday_life(self, groups, officers, members):
        """Each group: two events, a few validated cash-book lines, an announcement."""
        from apps.announcements.models import Announcement
        from apps.core.groups import in_group
        from apps.events.models import Event
        from apps.finances.models import Entry

        today = timezone.localdate()
        for i, (name, g) in enumerate(groups.items()):
            if name not in officers:
                continue  # « à compléter »
            o = dict(officers[name])
            o.setdefault("formateur", o["president"])
            with in_group(g):
                for days, kind, title in ((2 + i % 3, "assise", "Assise hebdomadaire"), (9 + i, "reunion", "Réunion du bureau")):
                    Event.objects.create(kind=kind, title=title, place="Salle paroissiale", created_by=o["president"],
                                         chef=o["formateur"] if kind == "assise" else None,
                                         starts_at=timezone.make_aware(datetime.combine(today + timedelta(days=days), time(15))))
                past = Event.objects.create(kind="assise", title="Assise du mois dernier", created_by=o["president"],
                                            starts_at=timezone.make_aware(datetime.combine(today - timedelta(days=20), time(15))))
                from apps.events.models import Attendance

                for j, m in enumerate(members[name]):
                    Attendance.objects.create(event=past, member=m, status="present" if j % 3 else "absent",
                                              marked_by=o["formateur"])
                for j, m in enumerate(members[name]):
                    Entry.objects.create(direction="in", amount=2000 + 500 * j, category="inscription",
                                         label="Inscription annuelle", member=m, date=today - timedelta(days=30 - j),
                                         status="validated", created_by=o["tresorier"],
                                         validated_by=o["commissaire-aux-comptes"], validated_at=timezone.now())
                Entry.objects.create(direction="out", amount=3500, category="depense", label="Bougies et fleurs",
                                     date=today - timedelta(days=10), status="validated", created_by=o["tresorier"],
                                     validated_by=o["commissaire-aux-comptes"], validated_at=timezone.now())
                Announcement.objects.create(title=f"Bienvenue dans {g.name}", body="Groupe de démonstration du réseau.",
                                            author=o["president"], author_role="Président")

    def from_above(self, groups, officers, members):
        """What flows down: a diocesan announcement, a zone event asking
        each parish for people, another for tomorrow (reminders), and a
        contribution half paid."""
        from apps.announcements.models import Announcement, Read
        from apps.core.groups import in_group
        from apps.core.network import send_down
        from apps.events.contingents import answer, set_requests
        from apps.events.models import Event, EventContingent
        from apps.finances import network_dues

        today = timezone.localdate()
        d, zb, za = groups[DIOCESE], groups[ZONE], groups[ZONE2]
        with in_group(d):
            a = Announcement.objects.create(title="Pèlerinage diocésain à Marienberg",
                                            body="Toutes les paroisses du diocèse sont invitées le dernier samedi du mois.",
                                            author=officers[DIOCESE]["conseiller"], author_role="Aumônier diocésain",
                                            cascade=True)
            Read.objects.create(announcement=a, member=officers[DIOCESE]["conseiller"])
            send_down(d, f"Annonce de {d.name}", a.title, {"type": "announcement", "id": a.pk})

        # Build 48: a zone post for two parishes' bureaux only, and requests
        # for more sharing waiting for the parishes' présidents.
        from apps.core.network import send_to
        from apps.core.sharing import ask

        with in_group(zb):
            b = Announcement.objects.create(title="Réunion des présidents de la zone",
                                            body="Pour les bureaux de Yapoma et Kotto : préparation de la fête de zone.",
                                            author=officers[ZONE]["president"], author_role="Coordinateur de zone",
                                            cascade=True, reach_audience="bureau")
            b.reach.set([groups["GS Yapoma"], groups["GS Kotto"]])
            Read.objects.create(announcement=b, member=officers[ZONE]["president"])
            send_to(b, f"Annonce de {zb.name}", b.title, {"type": "announcement", "id": b.pk})
            ask(zb, groups["GS Kotto"], "finances", "detail", by=officers[ZONE]["tresorier"],
                note="Pour le rapport trimestriel de la zone.")
        with in_group(za):
            ask(za, groups["GS Bonapriso"], "finances", "summary", by=officers[ZONE2]["president"],
                note="Toutes les paroisses de la zone le partagent, sauf vous.")

        for zone, when, title in ((zb, today + timedelta(days=3), "Messe de zone"), (za, today + timedelta(days=1), "Service extérieur de zone")):
            o = officers[zone.name.removesuffix(SUFFIX)]
            with in_group(zone):
                ev = Event.objects.create(kind="messe", title=title, place="Cathédrale Saints-Pierre-et-Paul",
                                          created_by=o["president"], chef=o["president"], cascade=True,
                                          starts_at=timezone.make_aware(datetime.combine(when, time(9))))
                send_down(zone, f"Événement de {zone.name}", f"{ev.title} · {when:%d/%m} à 09:00",
                          {"type": "event", "id": ev.pk}, kind="duty")
                active = [k for k in zone.children.all() if k.name.removesuffix(SUFFIX) in officers]
                set_requests(ev, [{"group": k.pk, "requested": 3, "note": "En tenue de cérémonie"} for k in active],
                             by=o["president"])
            # The first parish of each zone names its people; the others haven't yet.
            first = sorted(active, key=lambda g: g.name)[0]
            c = EventContingent.objects.get(event=ev, group=first)
            with in_group(first):
                answer(c, [m.pk for m in members[first.name.removesuffix(SUFFIX)][:3]],
                       by=officers[first.name.removesuffix(SUFFIX)]["formateur"])

        with in_group(zb):
            dues = network_dues.ask(zb, title="Quote-part T4 2026", amount=15000, due_on=today + timedelta(days=30),
                                    groups=[g.pk for g in zb.children.all() if g.name.removesuffix(SUFFIX) in officers],
                                    by=officers[ZONE]["tresorier"])
        paid = next(x for x in dues if x.group == groups["GS Bonamoussadi"])
        with in_group(paid.group):
            network_dues.pay(paid, by=officers["GS Bonamoussadi"]["tresorier"])

    # --- removing ------------------------------------------------------------------------

    def delete(self):
        from apps.accounts.models import User
        from apps.core.models import Group, GroupInvitation, GroupLink, Membership, Network
        from apps.finances.models import NetworkDue

        groups = list(Group.objects.filter(name__endswith=SUFFIX))
        ids = [g.pk for g in groups]
        phones = [f"+237{n}" for n in range(PHONE_BASE, PHONE_BASE + 100)]
        with transaction.atomic():
            NetworkDue.objects.filter(group_id__in=ids).delete()
            NetworkDue.objects.filter(umbrella_id__in=ids).delete()
            GroupLink.objects.filter(a_id__in=ids).delete()
            GroupLink.objects.filter(b_id__in=ids).delete()
            GroupInvitation.objects.filter(umbrella_id__in=ids).delete()
            Group.objects.filter(pk__in=ids).update(parent=None)
            from apps.accounts.models import RoleAssignment

            RoleAssignment.all_groups.filter(role__group_id__in=ids).delete()  # protected: they go first
            for g in groups:
                g.delete()
            Network.objects.filter(name=NETWORK).delete()
            users = User.objects.filter(phone__in=phones)
            keep = set(Membership.all_groups.filter(user__in=users).values_list("user_id", flat=True))
            n = users.exclude(pk__in=keep).delete()[0]
        return len(groups), n


# --- For the back-office (build 47: staging has no shell on the owner's plan) ----------------

def exists():
    from apps.core.models import Group

    return Group.objects.filter(name=demo(GROUPS[0][0])).exists()


def create_demo():
    """Build the demo network; returns (pin, [(group, [(role, name, phone)])])."""
    cmd = Command()
    pin = cmd.pick_pin()
    with transaction.atomic():
        return pin, cmd.build(pin)


# The back-office runs creation in the background (build 48): on Render's
# small instance it takes longer than a request may last.
JOB = "network-demo-job"


def start_demo(user_id):
    """Start building in a thread; the result waits in the cache for
    `user_id` (the PIN shows once). Returns False when a job is running."""
    import threading

    from django.conf import settings
    from django.core.cache import cache
    from django.db import connection

    if not cache.add(JOB, {"status": "running", "user": user_id}, timeout=600):
        return False

    def build():
        try:
            pin, listing = create_demo()
            cache.set(JOB, {"status": "done", "user": user_id, "pin": pin, "listing": listing}, timeout=900)
        except Exception as e:  # shown to the super admin, and in the logs
            import logging

            logging.getLogger(__name__).exception("demo network")
            cache.set(JOB, {"status": "error", "user": user_id, "error": f"{type(e).__name__}: {e}"[:500]}, timeout=900)

    def run():
        try:
            build()
        finally:
            connection.close()  # the thread's own connection

    if getattr(settings, "DEMO_INLINE", False):  # tests: same thread, same transaction
        build()
    else:
        threading.Thread(target=run, name="network-demo", daemon=True).start()
    return True


def job():
    from django.core.cache import cache

    return cache.get(JOB)


def clear_job():
    from django.core.cache import cache

    cache.delete(JOB)


def delete_demo():
    """Remove it; returns (groups, rows) deleted."""
    return Command().delete()
