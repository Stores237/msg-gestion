from django.conf import settings
from django.db import models

from apps.core.groups import default_group_id, scoped


class ActivityType(models.Model):
    """A kind of activity on a group's calendar (owner, 2026-10-23: each
    group names its own — the Garde Suisse's assise, messe, grande
    veillée…; a choir's rehearsal…). Edited in back-office → Paramètres."""

    group = models.ForeignKey("core.Group", on_delete=models.CASCADE, default=default_group_id, related_name="+")
    slug = models.SlugField(max_length=20)
    name = models.CharField(max_length=60)
    # A service lineup is made for it (planning: "à planifier").
    needs_lineup = models.BooleanField(default=False)
    # Counts in a member's presence summary (the weekly meeting).
    counts_presence = models.BooleanField(default=False)
    sort_order = models.PositiveSmallIntegerField(default=100)
    is_archived = models.BooleanField(default=False)

    objects = scoped()
    all_groups = models.Manager()

    class Meta:
        ordering = ["sort_order", "name"]
        constraints = [models.UniqueConstraint(fields=["group", "slug"], name="activity_slug_per_group")]

    def __str__(self):
        return self.name


class DressCode(models.Model):
    """A dress code a group asks for (tenue intérieure…). Per group."""

    group = models.ForeignKey("core.Group", on_delete=models.CASCADE, default=default_group_id, related_name="+")
    slug = models.SlugField(max_length=12)
    name = models.CharField(max_length=60)
    sort_order = models.PositiveSmallIntegerField(default=100)
    is_archived = models.BooleanField(default=False)

    objects = scoped()
    all_groups = models.Manager()

    class Meta:
        ordering = ["sort_order", "name"]
        constraints = [models.UniqueConstraint(fields=["group", "slug"], name="dress_slug_per_group")]

    def __str__(self):
        return self.name


class Event(models.Model):
    """Anything on the movement's calendar: assises, masses, services,
    night vigils, meetings. Kind and dress are fixed lists the app
    translates; title, place and notes are free text, shown as written."""

    class Kind(models.TextChoices):
        ASSISE = "assise", "Assise du samedi"
        MASS = "messe", "Messe"
        OUTSIDE_SERVICE = "service_exterieur", "Service extérieur"
        VIGIL = "grande_veillee", "Grande veillée"
        MEETING = "reunion", "Réunion"
        OTHER = "autre", "Autre"

    class Dress(models.TextChoices):
        NONE = "", "—"
        INSIDE = "interieure", "Tenue intérieure"
        OUTSIDE = "exterieure", "Tenue extérieure"
        SPORT = "sportive", "Tenue sportive"
        CIVIL = "civile", "Tenue civile"

    # The slug of one of the group's ActivityType (Kind: the defaults).
    kind = models.CharField(max_length=20)
    title = models.CharField(max_length=140)
    starts_at = models.DateTimeField(db_index=True)
    ends_at = models.DateTimeField(null=True, blank=True)
    place = models.CharField(max_length=140, blank=True)
    # The slug of one of the group's DressCode, or empty.
    dress = models.CharField(max_length=12, blank=True)
    notes = models.TextField(blank=True)
    created_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, related_name="+")
    # The author's role when they created it (owner, 2026-10-26: shown on it).
    created_by_role = models.CharField(max_length=100, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    group = models.ForeignKey("core.Group", on_delete=models.CASCADE, default=default_group_id, related_name="+")
    objects = scoped()
    all_groups = models.Manager()

    class Meta:
        ordering = ["starts_at"]
        constraints = [
            models.CheckConstraint(
                condition=models.Q(ends_at__isnull=True) | models.Q(ends_at__gt=models.F("starts_at")),
                name="event_ends_after_start",
            )
        ]

    def __str__(self):
        return f"{self.title} ({self.starts_at:%Y-%m-%d %H:%M})"


class Attendance(models.Model):
    class Status(models.TextChoices):
        PRESENT = "present", "Présent"
        ABSENT = "absent", "Absent"
        EXCUSED = "excuse", "Excusé"

    event = models.ForeignKey(Event, on_delete=models.CASCADE, related_name="attendance")
    member = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="attendance")
    status = models.CharField(max_length=8, choices=Status.choices)
    reason = models.CharField(max_length=240, blank=True, help_text="Motif donné par le membre pour une absence prévenue.")
    marked_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, related_name="+")
    marked_at = models.DateTimeField(auto_now=True)

    objects = scoped("event__group")
    all_groups = models.Manager()

    class Meta:
        constraints = [models.UniqueConstraint(fields=["event", "member"], name="one_mark_per_member")]


def kind_names():
    return dict(ActivityType.objects.values_list("slug", "name"))


def dress_names():
    return dict(DressCode.objects.values_list("slug", "name"))
