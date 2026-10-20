from django.conf import settings
from django.db import models


class Announcement(models.Model):
    """An announcement or a convocation to every member. A convocation is
    tied to a calendar event. Title and body are shown as written (the
    author chooses the language)."""

    class Kind(models.TextChoices):
        ANNOUNCEMENT = "annonce", "Annonce"
        CONVOCATION = "convocation", "Convocation"

    kind = models.CharField(max_length=12, choices=Kind.choices, default=Kind.ANNOUNCEMENT)
    title = models.CharField(max_length=160)
    body = models.TextField(blank=True)
    event = models.ForeignKey("events.Event", on_delete=models.SET_NULL, null=True, blank=True, related_name="convocations")
    pinned = models.BooleanField(default=False)
    author = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, related_name="+")
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)

    class Meta:
        ordering = ["-pinned", "-created_at"]

    def __str__(self):
        return self.title


class Read(models.Model):
    announcement = models.ForeignKey(Announcement, on_delete=models.CASCADE, related_name="reads")
    member = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="+")
    read_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        constraints = [models.UniqueConstraint(fields=["announcement", "member"], name="one_read_per_member")]
