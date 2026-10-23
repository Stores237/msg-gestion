from django.conf import settings
from django.db import models

from apps.core.groups import default_group_id, scoped


class AccessRequest(models.Model):
    """A group leader asks the platform's partner (the super admin) to open
    an account for someone (owner, 2026-10-23):

    leader requests in the app → the partner creates the access in the
    back-office → the leader receives the temporary PIN in the app and hands
    it over → the member signs in, picks their own PIN and sees their role.

    The temporary PIN is kept only until the leader has seen it once, and
    the member must replace it at first sign-in.
    """

    class Status(models.TextChoices):
        PENDING = "pending", "En attente"
        APPROVED = "approved", "Accès créé"
        REFUSED = "refused", "Refusée"

    group = models.ForeignKey("core.Group", on_delete=models.CASCADE, default=default_group_id, related_name="+")
    requested_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, related_name="+")
    last_name = models.CharField("nom", max_length=80)
    first_name = models.CharField("prénoms", max_length=80)
    phone = models.CharField(max_length=16)
    birth_date = models.DateField(null=True, blank=True)
    is_diaspora = models.BooleanField(default=False)
    city = models.CharField(max_length=80, blank=True)
    parent_name = models.CharField(max_length=120, blank=True)
    parent_relation = models.CharField(max_length=40, blank=True)
    parent_phone = models.CharField(max_length=16, blank=True)
    registration_paid = models.BooleanField(default=False)
    role = models.ForeignKey("accounts.Role", on_delete=models.PROTECT, related_name="+")
    note = models.CharField(max_length=300, blank=True)

    status = models.CharField(max_length=10, choices=Status.choices, default=Status.PENDING)
    decided_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="+")
    decided_at = models.DateTimeField(null=True, blank=True)
    decision_note = models.CharField(max_length=300, blank=True)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="+")
    # Set on approval for a new account; cleared once the leader has seen it.
    temp_pin = models.CharField(max_length=4, blank=True)
    pin_revealed_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    objects = scoped()
    all_groups = models.Manager()

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.last_name} {self.first_name}".strip()

    @property
    def full_name(self):
        return str(self)
