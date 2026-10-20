from django.conf import settings
from django.db import models


class AuditLog(models.Model):
    """Who did what, to what, when, from which device. Append-only.

    Kept 5 years (design: "Conservation : 5 ans"). `detail` holds a
    before/after diff where there is one; finance amounts never go in it
    for an actor who isn't allowed to see them.
    """

    actor = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="+")
    action = models.CharField(max_length=60)
    object_type = models.CharField(max_length=60, blank=True)
    object_id = models.CharField(max_length=40, blank=True)
    object_repr = models.CharField(max_length=200, blank=True)
    detail = models.JSONField(default=dict, blank=True)
    sensitive = models.BooleanField(default=False)
    refused = models.BooleanField(default=False, help_text="Action refusée par un garde-fou.")
    ip = models.GenericIPAddressField(null=True, blank=True)
    device = models.CharField(max_length=200, blank=True)
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.created_at:%Y-%m-%d %H:%M} {self.action} {self.object_repr}"
