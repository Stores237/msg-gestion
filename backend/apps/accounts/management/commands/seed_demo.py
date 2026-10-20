from datetime import date, timedelta

from django.conf import settings
from django.core.management.base import BaseCommand, CommandError
from django.db import transaction

from apps.accounts.models import Role, RoleAssignment, User
from apps.accounts.phone import normalize_phone

# The sample people from the designs (design/screens-a.jsx, bo-screens-1.jsx).
PEOPLE = [
    # phone, last, first, status, diaspora, city, birth, roles
    ("677102241", "Ewane", "Brice", "actif", False, "", date(1978, 4, 2), ["president", "membre"]),
    ("699451007", "Ngo Nyemb", "Christelle", "actif", False, "", date(1990, 9, 14), ["secretaire-general", "super-admin", "membre"]),
    ("677452108", "Fotso", "Ingrid", "actif", False, "", date(1992, 1, 20), ["tresorier", "membre"]),
    ("655319012", "Tchoumi", "Arnaud", "actif", False, "", date(1988, 6, 3), ["commissaire-aux-comptes", "membre"]),
    ("691023358", "Eboa", "Lionel", "actif", False, "", date(2001, 5, 12), ["censeur-general", "chef-de-groupe", "membre"]),
    ("670881463", "Kotto", "Hervé", "actif", False, "", date(1999, 11, 8), ["membre"]),
    ("694275130", "Mbella", "Grâce", "conge", False, "", date(2003, 2, 17), ["membre"]),
    ("+33612457890", "Ateba", "Sandrine", "actif", True, "Lyon, France", date(1995, 7, 30), ["membre"]),
    ("677630219", "Moukouri", "Danielle", "suspendu", False, "", date(2002, 3, 9), ["membre"]),
    ("691347702", "Essomba", "Kévin", "actif", False, "", date(2011, 3, 3), ["membre"]),
    ("677000001", "Tchakounté", "Alain", "actif", False, "", date(1985, 10, 1), ["super-admin", "membre"]),
    # Ten more ordinary members, made up for the demo (owner request, 2026-10-20).
    ("650214387", "Nkoulou", "Paule", "actif", False, "", date(1998, 8, 21), ["membre"]),
    ("672905114", "Bilong", "Steve", "actif", False, "", date(2004, 12, 2), ["membre"]),
    ("695338720", "Manga", "Yves", "actif", False, "", date(1996, 4, 11), ["membre"]),
    ("681470256", "Etoundi", "Carine", "actif", False, "", date(2000, 6, 25), ["membre"]),
    ("653127948", "Din", "Yannick", "actif", False, "", date(1993, 1, 7), ["formateur", "chef-de-groupe", "membre"]),
    ("698046631", "Ngo Mbock", "Rachel", "actif", False, "", date(2002, 9, 18), ["membre"]),
    ("674583902", "Ndjock", "Patrick", "actif", False, "", date(2010, 3, 3), ["membre"]),
    ("+4915112345678", "Abena", "Joël", "actif", True, "Berlin, Allemagne", date(1991, 11, 30), ["membre"]),
    ("690712463", "Mvondo", "Estelle", "conge", False, "", date(2005, 5, 14), ["membre"]),
    ("656281709", "Owona", "Franck", "classe", False, "", date(1983, 2, 26), ["membre"]),
]
# Minors in the list above get a parent contact, as the design requires.
PARENTS = {
    "674583902": ("Mme Ndjock Hélène", "Mère", "+237699120044"),
    "691347702": ("Mme Essomba Pauline", "Mère", "+237699123456"),
}
DEMO_PIN = "1234"
DEMO_PASSWORD = "msg-demo-2026!"


class Command(BaseCommand):
    help = "Local development only: create the sample members from the designs, with roles, PIN 1234."

    def handle(self, *args, **options):
        if not settings.DEBUG:
            raise CommandError("seed_demo refuses to run with DEBUG off — it creates accounts with a known PIN.")
        roles = {r.slug: r for r in Role.objects.all()}
        mandate_start = date(2025, 10, 1)
        with transaction.atomic():
            for phone, last, first, status, diaspora, city, birth, slugs in PEOPLE:
                user, created = User.objects.get_or_create(
                    phone=normalize_phone(phone),
                    defaults=dict(last_name=last, first_name=first, status=status, is_diaspora=diaspora, city=city, birth_date=birth),
                )
                if not created:
                    continue
                if phone in PARENTS:
                    user.parent_name, user.parent_relation, user.parent_phone = PARENTS[phone]
                user.set_pin(DEMO_PIN)
                if {"super-admin", "president", "secretaire-general"} & set(slugs):
                    user.set_password(DEMO_PASSWORD)
                user.save()
                for slug in slugs:
                    role = roles[slug]
                    start = mandate_start if role.kind == "bureau" else date.today() - timedelta(days=30)
                    end = date(2027, 9, 30) if role.kind == "bureau" else None
                    RoleAssignment.objects.create(user=user, role=role, starts_on=start, ends_on=end, reason="Données de démonstration")
            kotto = User.objects.get(last_name="Kotto")
            if not kotto.assignments.filter(role__slug="censeur-du-jour").exists():
                RoleAssignment.objects.create(
                    user=kotto, role=roles["censeur-du-jour"], starts_on=date.today(), ends_on=date.today() + timedelta(days=5), reason="Données de démonstration"
                )
        self.stdout.write(self.style.SUCCESS(f"{len(PEOPLE)} demo members ready. App PIN: {DEMO_PIN}. Back-office password: {DEMO_PASSWORD}"))
