"""A demo network to try networks of groups end to end (owner, 2026-11-03:
"create other groups to test my hypothesis and see how it functions").

    python manage.py seed_network_demo --out demo-network.txt
    python manage.py seed_network_demo --delete

It builds, through the same code the app and back-office use (invitation
codes, sharing, sending down, contingents, contributions, twinning):

    MGS Cameroun (démo): Paroisse › Zone paroissiale › Diocèse › National
      Diocèse de Douala (démo)
        Zone Bonamoussadi (démo)  ── GS Bonamoussadi (démo), GS Kotto (démo)
        Zone Akwa (démo)          ── GS Akwa (démo), GS Bonapriso (démo)
    Chorale Sainte-Cécile (démo), in no network, twinned with GS Kotto (démo)

Every group gets a président, trésorier, commissaire aux comptes, formateur
and four members (made-up names, phone numbers 600 000 1xx, which no
operator gives out). They all share one PIN, written to --out (or printed
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
LEVELS = ["Paroisse", "Zone paroissiale", "Diocèse", "National"]
PHONE_BASE = 600000100

# name, sigle, level, parent name (without the suffix), colour
GROUPS = [
    ("Diocèse de Douala", "DDD", 3, None, "#5B3A8C"),
    ("Zone Bonamoussadi", "ZBO", 2, "Diocèse de Douala", "#1E6FB8"),
    ("Zone Akwa", "ZAK", 2, "Diocèse de Douala", "#B8541E"),
    ("GS Bonamoussadi", "GSB", 1, "Zone Bonamoussadi", "#2E7D46"),
    ("GS Kotto", "GSK", 1, "Zone Bonamoussadi", "#0E9F8F"),
    ("GS Akwa", "GSA", 1, "Zone Akwa", "#8C6D1F"),
    ("GS Bonapriso", "GSP", 1, "Zone Akwa", "#A33B5C"),
]
CHOIR = "Chorale Sainte-Cécile"
OFFICERS = ["president", "tresorier", "commissaire-aux-comptes", "formateur"]
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
            return self.delete()
        from apps.core.models import Group

        if Group.objects.filter(name=demo(GROUPS[0][0])).exists():
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
        from apps.core.network import accept_invitation, accept_twin, create_invitation, place_group, save_network

        net = save_network(by=None, name=NETWORK, levels=LEVELS)
        groups, officers, members, listing = {}, {}, {}, []
        phone = PHONE_BASE
        names = iter([(ln, fn) for ln in LAST for fn in FIRST][::3])
        for name, short, level, _parent, color in [*GROUPS, (CHOIR, "CSC", 1, None, "#C0392B")]:
            g = create_group(name=demo(name), place="Douala", motto="Groupe de démonstration")
            g.short_name = short
            g.save(update_fields=["short_name"])
            st = Settings.get(g)
            st.color = color
            st.save(update_fields=["color"])
            if name != CHOIR:
                g = place_group(g, network=net, level=level, by=None)
            groups[name] = g
            rows = []
            with in_group(g):
                for slug in [*OFFICERS, "membre", "membre", "membre", "membre"]:
                    last, first = next(names)
                    u = self.person(g, slug, last, first, phone, pin)
                    rows.append((u.role_name, u.full_name, u.phone))
                    if slug == "membre":
                        members.setdefault(name, []).append(u)
                    else:
                        officers.setdefault(name, {})[slug] = u
                    phone += 1
            listing.append((demo(name), rows))

        # Attach each group to its parent with an invitation code, as présidents would.
        for name, _s, _l, parent, _c in GROUPS:
            if parent is None:
                continue
            code = create_invitation(groups[parent], by=officers[parent]["president"]).code
            with in_group(groups[name]):
                accept_invitation(code, groups[name], by=officers[name]["president"])
            groups[name].refresh_from_db()

        # Twinning: the choir with GS Kotto.
        twin = create_invitation(groups[CHOIR], by=officers[CHOIR]["president"], kind=GroupInvitation.Kind.TWIN)
        with in_group(groups["GS Kotto"]):
            accept_twin(twin.code, groups["GS Kotto"], by=officers["GS Kotto"]["president"])

        self.share(groups, officers)
        self.everyday_life(groups, officers, members)
        self.from_above(groups, officers, members)
        return listing

    def person(self, group, slug, last, first, phone, pin):
        from apps.accounts.models import Role, RoleAssignment, User
        from apps.core.models import Membership

        u = User.objects.create(phone=f"+237{phone}", last_name=last, first_name=first, status="actif", city="Douala",
                                birth_date=date(1990 + phone % 15, 1 + phone % 12, 1 + phone % 27))
        u.set_unusable_password()
        u.set_pin(pin)
        u.save()
        Membership.join(u, group.pk)
        role = Role.all_groups.get(group=group, slug=slug)
        RoleAssignment.objects.create(user=u, role=role, starts_on=date.today() - timedelta(days=90),
                                      reason="Réseau de démonstration")
        u.role_name = role.name
        return u

    def share(self, groups, officers):
        from apps.core.sharing import save_settings

        for name in ("GS Bonamoussadi", "GS Kotto", "GS Akwa", "GS Bonapriso"):
            save_settings(groups[name], {"members": "detail", "finances": "summary", "calendar": "detail",
                                         "reports": "summary"}, by=officers[name]["president"])
        for name in ("Zone Bonamoussadi", "Zone Akwa"):
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
            o = officers[name]
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
        d, zb, za = groups["Diocèse de Douala"], groups["Zone Bonamoussadi"], groups["Zone Akwa"]
        with in_group(d):
            a = Announcement.objects.create(title="Pèlerinage diocésain à Marienberg",
                                            body="Toutes les paroisses du diocèse sont invitées le dernier samedi du mois.",
                                            author=officers["Diocèse de Douala"]["president"], author_role="Président",
                                            cascade=True)
            Read.objects.create(announcement=a, member=officers["Diocèse de Douala"]["president"])
            send_down(d, f"Annonce de {d.name}", a.title, {"type": "announcement", "id": a.pk})

        for zone, when, title in ((zb, today + timedelta(days=3), "Messe de zone"), (za, today + timedelta(days=1), "Service extérieur de zone")):
            o = officers[zone.name.removesuffix(SUFFIX)]
            with in_group(zone):
                ev = Event.objects.create(kind="messe", title=title, place="Cathédrale Saints-Pierre-et-Paul",
                                          created_by=o["president"], chef=o["formateur"], cascade=True,
                                          starts_at=timezone.make_aware(datetime.combine(when, time(9))))
                send_down(zone, f"Événement de {zone.name}", f"{ev.title} · {when:%d/%m} à 09:00",
                          {"type": "event", "id": ev.pk}, kind="duty")
                set_requests(ev, [{"group": k.pk, "requested": 3, "note": "En tenue de cérémonie"} for k in zone.children.all()],
                             by=o["formateur"])
            # The first parish of each zone names its people; the second hasn't yet.
            first = sorted(zone.children.all(), key=lambda g: g.name)[0]
            c = EventContingent.objects.get(event=ev, group=first)
            with in_group(first):
                answer(c, [m.pk for m in members[first.name.removesuffix(SUFFIX)][:3]],
                       by=officers[first.name.removesuffix(SUFFIX)]["formateur"])

        with in_group(zb):
            dues = network_dues.ask(zb, title="Quote-part T4 2026", amount=15000, due_on=today + timedelta(days=30),
                                    by=officers["Zone Bonamoussadi"]["tresorier"])
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
        self.stdout.write(f"Removed {len(groups)} demo groups and their people ({n} rows).")
