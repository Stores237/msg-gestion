from datetime import datetime, time, timedelta

from django.core.management.base import BaseCommand
from django.db import transaction
from django.utils import timezone

from apps.accounts.models import RoleAssignment
from apps.announcements.models import Announcement, Read
from apps.events.models import Event

DEMO_TAG = "[démo]"


def _at(day, hour, minute=0):
    return timezone.make_aware(datetime.combine(day, time(hour, minute)))


def _next_weekday(start, weekday):
    return start + timedelta(days=(weekday - start.weekday()) % 7)


class Command(BaseCommand):
    """Demo calendar and announcements for testers (staging). Every row it
    creates has "[démo]" in its notes or body; re-running replaces them, and
    --remove deletes them. Never touches anything else."""

    help = "Create (or replace) demo events and announcements for testers."

    def add_arguments(self, parser):
        parser.add_argument("--remove", action="store_true", help="Only delete the demo content.")

    def handle(self, *args, remove=False, **options):
        with transaction.atomic():
            Announcement.objects.filter(body__contains=DEMO_TAG).delete()
            Event.objects.filter(notes__contains=DEMO_TAG).delete()
            if remove:
                self.stdout.write("Demo content removed.")
                return
            author_assignment = (
                RoleAssignment.objects.active().filter(role__slug__in=["secretaire-general", "super-admin"]).select_related("user").first()
            )
            author = author_assignment.user if author_assignment else None
            today = timezone.localdate()
            note = f"{DEMO_TAG} Contenu de démonstration pour les testeurs."
            events = []
            saturday = _next_weekday(today, 5)
            for i in range(4):
                day = saturday + timedelta(weeks=i)
                events.append(Event(kind="assise", title="Assise hebdomadaire", starts_at=_at(day, 15), place="Salle paroissiale", dress="interieure", notes=note))
                events.append(Event(kind="messe", title="Grand-messe", starts_at=_at(day + timedelta(days=1), 9), place="Église Notre-Dame de Lourdes", dress="interieure", notes=note))
            vigil_day = _next_weekday(today + timedelta(days=7), 5)
            vigil = Event(kind="grande_veillee", title="Veillée de prière", starts_at=_at(vigil_day, 22), ends_at=_at(vigil_day + timedelta(days=1), 5),
                          place="Église Notre-Dame de Lourdes", dress="interieure", notes=note)
            ag_day = saturday + timedelta(weeks=2)
            ag = Event(kind="reunion", title="Assemblée générale ordinaire", starts_at=_at(ag_day, 16), place="Salle paroissiale", dress="civile", notes=note)
            service = Event(kind="service_exterieur", title="Messe d’ordination", starts_at=_at(saturday + timedelta(weeks=3, days=1), 9),
                            place="Cathédrale Saints-Pierre-et-Paul", dress="exterieure", notes=note)
            Event.objects.bulk_create([*events, vigil, ag, service])
            items = [
                Announcement(kind="convocation", title="Assemblée générale ordinaire", event=ag, pinned=True, author=author,
                             body=f"Présence obligatoire pour tous les gardes. Ordre du jour : bilan du trimestre, préparation des fêtes. {DEMO_TAG}"),
                Announcement(kind="annonce", title="Répétition des chants pour la veillée", author=author,
                             body=f"Rendez-vous jeudi à 18:00 à l’église. {DEMO_TAG}"),
                Announcement(kind="annonce", title="Bienvenue sur MSG Gestion (version de test)", author=author,
                             body=f"Merci de tester l’application. Signalez tout problème au bureau. {DEMO_TAG}"),
            ]
            Announcement.objects.bulk_create(items)
            if author:
                Read.objects.bulk_create([Read(announcement=a, member=author) for a in Announcement.objects.filter(body__contains=DEMO_TAG)])
        self.stdout.write(self.style.SUCCESS(f"{len(events) + 3} demo events and 3 announcements created."))
