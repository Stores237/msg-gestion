from datetime import timedelta

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
    # Held inside or outside (owner, 2026-10-27: Messe intérieure /
    # extérieure, which replaced "Service extérieur"); each event says which.
    has_scope = models.BooleanField("intérieur / extérieur", default=False)
    # A chef de groupe is designated when the event is created, coordinates
    # it and reports to the formateur (owner, 2026-10-27; not for meetings).
    needs_chef = models.BooleanField("chef de groupe", default=True)
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
    # What it means in this group (design: "Aube blanche, cordon, chaussures noires").
    description = models.CharField(max_length=140, blank=True)
    sort_order = models.PositiveSmallIntegerField(default=100)
    is_archived = models.BooleanField(default=False)

    objects = scoped()
    all_groups = models.Manager()

    class Meta:
        ordering = ["sort_order", "name"]
        constraints = [models.UniqueConstraint(fields=["group", "slug"], name="dress_slug_per_group")]

    def __str__(self):
        return self.name


# Hours after an event ends for its chef de groupe to hand in the report;
# each group sets its own (Settings.report_hours, owner 2026-11-02).
REPORT_HOURS = 24


def _settings(group_id):
    from apps.core.models import Settings

    return Settings.all_groups.filter(group_id=group_id).first()


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

    class Scope(models.TextChoices):
        NONE = "", "—"
        INSIDE = "interieur", "Intérieur"
        OUTSIDE = "exterieur", "Extérieur"

    class Dress(models.TextChoices):
        NONE = "", "—"
        INSIDE = "interieure", "Tenue intérieure"
        OUTSIDE = "exterieure", "Tenue extérieure"
        SPORT = "sportive", "Tenue sportive"
        CIVIL = "civile", "Tenue civile"

    # The slug of one of the group's ActivityType (Kind: the defaults).
    kind = models.CharField(max_length=20)
    # With kind "autre": what it is, in the author's words.
    kind_other = models.CharField(max_length=60, blank=True)
    # For a type with has_scope: inside or outside.
    scope = models.CharField(max_length=10, choices=Scope.choices, blank=True)
    title = models.CharField(max_length=140)
    starts_at = models.DateTimeField(db_index=True)
    ends_at = models.DateTimeField(null=True, blank=True)
    place = models.CharField(max_length=140, blank=True)
    # Second line under the place (design: "Yapoma, Douala").
    place_detail = models.CharField(max_length=140, blank=True)
    # The slug of one of the group's DressCode, or empty.
    dress = models.CharField(max_length=12, blank=True)
    notes = models.TextField(blank=True)
    # Shown in the calendars of the groups attached below (owner, 2026-11-03),
    # read-only there.
    cascade = models.BooleanField("aussi pour les groupes rattachés", default=False)
    # Which groups of the network receive it (owner, 2026-11-04: "select who
    # should receive"): groups below, neighbours or twins. None chosen: every
    # group below, as before build 48. "bureau": only their bureau sees it.
    reach = models.ManyToManyField("core.Group", blank=True, related_name="+")
    reach_audience = models.CharField(max_length=8, choices=[("all", "Tous les membres"), ("bureau", "Le bureau seulement")],
                                      default="all")
    created_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, related_name="+")
    # The author's role when they created it (owner, 2026-10-26: shown on it).
    created_by_role = models.CharField(max_length=100, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    # Coordinates the event and reports on it within REPORT_HOURS of its end.
    chef = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="led_events")
    # Set by send_soon_reminders so each reminder goes once.
    report_reminded_at = models.DateTimeField(null=True, blank=True)
    report_overdue_at = models.DateTimeField(null=True, blank=True)

    group = models.ForeignKey("core.Group", on_delete=models.CASCADE, default=default_group_id, related_name="+")
    objects = scoped()
    all_groups = models.Manager()

    @property
    def report_due_at(self):
        st = _settings(self.group_id)
        return (self.ends_at or self.starts_at) + timedelta(hours=st.report_hours if st else REPORT_HOURS)

    @property
    def ends_or_default(self):
        """The end, or the start plus the group's default length."""
        if self.ends_at:
            return self.ends_at
        st = _settings(self.group_id)
        return self.starts_at + timedelta(minutes=st.event_minutes if st else 120)

    def has_ended(self, now=None):
        """Once over, an event can't be changed any more: only its roll call
        stays open (owner, 2026-11-02)."""
        from django.utils import timezone

        return self.ends_or_default <= (now or timezone.now())

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


class EventReport(models.Model):
    """The chef de groupe's report on an event: written in the app, a PDF,
    or both. Goes to the formateur, with the formateur adjoint, the
    secrétaire général, the censeur général and the vice-censeur in copy."""

    event = models.OneToOneField(Event, on_delete=models.CASCADE, related_name="report")
    author = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, related_name="+")
    body = models.TextField(blank=True)
    file = models.FileField(upload_to="reports/", null=True, blank=True)
    file_name = models.CharField(max_length=160, blank=True)
    submitted_at = models.DateTimeField()
    updated_at = models.DateTimeField(auto_now=True)
    # The first time a bureau reader (not the chef) opened it; from then on
    # the chef can no longer change it (owner, 2026-10-27).
    read_at = models.DateTimeField(null=True, blank=True)
    read_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="+")

    objects = scoped("event__group")
    all_groups = models.Manager()

    @property
    def late(self):
        return self.submitted_at > self.event.report_due_at


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


def dress_descriptions():
    return dict(DressCode.objects.exclude(description="").values_list("slug", "description"))


class EventContingent(models.Model):
    """Joint planning (owner, 2026-11-03): an event a group sends down asks
    each group attached below it for a number of people; that group's
    planning officer names who goes. The upper group asks, the lower one
    decides who (an umbrella only informs)."""

    event = models.ForeignKey(Event, on_delete=models.CASCADE, related_name="contingents")
    group = models.ForeignKey("core.Group", on_delete=models.CASCADE, related_name="+")
    requested = models.PositiveSmallIntegerField()
    note = models.CharField(max_length=200, blank=True)
    members = models.ManyToManyField(settings.AUTH_USER_MODEL, blank=True, related_name="contingents")
    asked_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, related_name="+")
    asked_at = models.DateTimeField(auto_now_add=True)
    answered_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="+")
    answered_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        constraints = [models.UniqueConstraint(fields=["event", "group"], name="one_contingent_per_group")]

    def __str__(self):
        return f"{self.event} · {self.group}: {self.requested}"
