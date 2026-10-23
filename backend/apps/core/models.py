from django.conf import settings
from django.db import models

from .groups import default_group_id, scoped


class Group(models.Model):
    """A group using the MSG platform (e.g. the Mouvement Garde Suisse).
    Its people are linked through Membership; its roles, money, calendar,
    planning and announcements all carry it."""

    name = models.CharField(max_length=120)
    slug = models.SlugField(unique=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["name"]
        verbose_name = "groupe"

    def __str__(self):
        return self.name


class Membership(models.Model):
    """A person in a group. One account (one phone number) can belong to
    several groups, with different roles in each."""

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="memberships")
    group = models.ForeignKey(Group, on_delete=models.CASCADE, related_name="memberships")
    joined_on = models.DateField(null=True, blank=True)
    # Actif, en congé, classé, suspendu, archivé — in this group (owner,
    # 2026-10-23: one person can be on leave in one group, active in another).
    status = models.CharField(max_length=10, default="actif", choices=[
        ("actif", "Actif"), ("conge", "En congé"), ("classe", "Classé"), ("suspendu", "Suspendu"), ("archive", "Archivé")])
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    objects = scoped()
    all_groups = models.Manager()

    class Meta:
        constraints = [models.UniqueConstraint(fields=["user", "group"], name="one_membership_per_group")]

    def __str__(self):
        return f"{self.user} · {self.group}"

    @classmethod
    def join(cls, user, group_id=None):
        """Put `user` in a group (the current one by default); idempotent."""
        m, created = cls.all_groups.get_or_create(user=user, group_id=group_id or default_group_id(),
                                                  defaults={"joined_on": user.joined_on, "status": "actif"})
        if not m.is_active:
            m.is_active = True
            m.save(update_fields=["is_active"])
        return m


class AuditLog(models.Model):
    """Who did what, to what, when, from which device. Append-only.

    Kept 5 years (design: "Conservation : 5 ans"). `detail` holds a
    before/after diff where there is one; finance amounts never go in it
    for an actor who isn't allowed to see them.
    """

    actor = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="+")
    # The group it happened in; empty for platform actions (logins,
    # super admins, groups themselves).
    group = models.ForeignKey(Group, on_delete=models.SET_NULL, null=True, blank=True, related_name="+")
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


class Notification(models.Model):
    """In-app notification (design: "Notifications"). Push delivery to the
    phone comes later; these rows are what the app lists either way."""

    class Kind(models.TextChoices):
        DUTY = "duty", "Service"
        ANNOUNCEMENT = "announcement", "Annonce"
        CONVOCATION = "convocation", "Convocation"
        PAYMENT = "payment", "Paiement"
        MEMBER = "member", "Membre"
        REQUEST = "request", "Demande"
        REMINDER = "reminder", "Rappel"

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="notifications")
    group = models.ForeignKey(Group, on_delete=models.CASCADE, default=default_group_id, related_name="+")
    kind = models.CharField(max_length=14, choices=Kind.choices)
    title = models.CharField(max_length=160)
    body = models.CharField(max_length=300, blank=True)
    # What to open: {"type": "event", "id": 12} etc.
    target = models.JSONField(default=dict, blank=True)
    read_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)

    objects = scoped()
    all_groups = models.Manager()

    class Meta:
        ordering = ["-created_at"]


class Settings(models.Model):
    """A group's settings (back-office → Paramètres): place, motto, welcome
    message, amounts and times. One row per group; the name is the group's."""

    group = models.OneToOneField(Group, on_delete=models.CASCADE, default=default_group_id, related_name="settings")
    parish = models.CharField("lieu ou rattachement", max_length=160, blank=True)
    motto = models.CharField(max_length=120, blank=True)
    # Shown to the group's members when they open the app (owner, 2026-10-23).
    welcome_message = models.TextField("message de bienvenue", max_length=600, blank=True)
    fee_registration = models.PositiveIntegerField(default=500)
    fee_medal = models.PositiveIntegerField(default=2000)
    fee_illness = models.PositiveIntegerField(default=1000)
    fee_death = models.PositiveIntegerField(default=2500)
    installments = models.PositiveSmallIntegerField(default=3)
    assise_weekday = models.PositiveSmallIntegerField(default=5, help_text="0 = lundi … 5 = samedi")
    assise_time = models.TimeField(default="15:00")
    vigil_time = models.TimeField(default="22:00")
    reminder_time = models.TimeField(default="20:00")
    duty_template = models.CharField(
        max_length=300,
        default="Bonjour {prénom}, tu es de service {date} à {heure} : {poste} ({côté}). Confirme dans l’app.",
    )

    objects = scoped()
    all_groups = models.Manager()

    @classmethod
    def get(cls, group=None):
        """The current group's settings (created with the defaults)."""
        gid = group.pk if group is not None else default_group_id()
        obj, _ = cls.all_groups.get_or_create(group_id=gid)
        return obj

    @property
    def name(self):
        return self.group.name

    def quick_amounts(self):
        return sorted({self.fee_registration, self.fee_illness, self.fee_medal, self.fee_death})
