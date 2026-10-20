from django.conf import settings
from django.db import models


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

    kind = models.CharField(max_length=20, choices=Kind.choices)
    title = models.CharField(max_length=140)
    starts_at = models.DateTimeField(db_index=True)
    ends_at = models.DateTimeField(null=True, blank=True)
    place = models.CharField(max_length=140, blank=True)
    dress = models.CharField(max_length=12, choices=Dress.choices, blank=True)
    notes = models.TextField(blank=True)
    created_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, related_name="+")
    created_at = models.DateTimeField(auto_now_add=True)

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

    class Meta:
        constraints = [models.UniqueConstraint(fields=["event", "member"], name="one_mark_per_member")]
