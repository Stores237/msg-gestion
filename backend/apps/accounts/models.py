from datetime import date

from django.contrib.auth.base_user import AbstractBaseUser, BaseUserManager
from django.contrib.auth.hashers import check_password, make_password
from django.contrib.auth.models import PermissionsMixin
from django.db import models
from django.db.models import F, FilteredRelation, Q
from django.utils import timezone

from apps.core.groups import current_group_id, default_group_id, scoped

from . import registry
from .phone import normalize_phone


class UserManager(BaseUserManager):
    use_in_migrations = True

    def create_user(self, phone, password=None, **extra):
        user = self.model(phone=normalize_phone(phone), **extra)
        user.set_password(password)  # None -> unusable: no back-office login
        user.save(using=self._db)
        return user

    def members(self):
        """People of the current group, each with `gstatus`: their status
        in that group (filter on it: .filter(gstatus=…)). With no group set
        (platform jobs, tests), everyone, with gstatus = account status.
        Accounts are platform-wide; a Membership puts one in a group."""
        gid = current_group_id()
        if gid is None:
            return self.annotate(gstatus=F("status"))
        return (
            self.annotate(m=FilteredRelation("memberships", condition=Q(memberships__group_id=gid)))
            .filter(m__isnull=False, m__is_active=True)
            .annotate(gstatus=F("m__status"))
        )

    def create_superuser(self, phone, password, **extra):
        extra.setdefault("is_staff", True)
        extra.setdefault("is_superuser", True)
        return self.create_user(phone, password, **extra)


class User(AbstractBaseUser, PermissionsMixin):
    """A member of the movement.

    Two separate credentials on purpose: a 4-digit `pin` for the mobile app
    (every member) and Django's own `password` for the back-office (only
    people who need it, always paired with an SMS second factor). A member
    without a back-office role has an unusable password.
    """

    class Status(models.TextChoices):
        ACTIVE = "actif", "Actif"
        LEAVE = "conge", "En congé"
        RETIRED = "classe", "Classé"
        SUSPENDED = "suspendu", "Suspendu"
        ARCHIVED = "archive", "Archivé"

    phone = models.CharField(max_length=16, unique=True)
    last_name = models.CharField("nom", max_length=80)
    first_name = models.CharField("prénoms", max_length=80)
    status = models.CharField(max_length=10, choices=Status.choices, default=Status.ACTIVE)
    is_diaspora = models.BooleanField(default=False)
    city = models.CharField(max_length=80, blank=True, help_text="Pour la diaspora : « Lyon, France ».")
    birth_date = models.DateField(null=True, blank=True)
    joined_on = models.DateField(default=date.today)
    photo = models.ImageField(upload_to="members/", null=True, blank=True)

    # Required when the member is a minor; visible only to the roles that
    # hold members.minor_contacts:view (président, SG by default).
    parent_name = models.CharField(max_length=120, blank=True)
    parent_relation = models.CharField(max_length=40, blank=True)
    parent_phone = models.CharField(max_length=16, blank=True)

    pin = models.CharField(max_length=128, blank=True)
    pin_failed_attempts = models.PositiveSmallIntegerField(default=0)
    pin_locked_until = models.DateTimeField(null=True, blank=True)
    # Set when someone else chose the PIN (registration, reset by the
    # secretary): the app makes the member pick their own on next login.
    pin_must_change = models.BooleanField(default=False)

    # Reminder preferences (design: event detail → "Rappels").
    remind_eve = models.BooleanField(default=True, help_text="La veille à 20:00")
    remind_2h = models.BooleanField(default=False, help_text="2 heures avant")

    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False, help_text="Accès à l’admin Django (équipe technique).")
    created_at = models.DateTimeField(auto_now_add=True)

    objects = UserManager()

    USERNAME_FIELD = "phone"
    REQUIRED_FIELDS = ["last_name", "first_name"]

    class Meta:
        ordering = ["last_name", "first_name"]
        verbose_name = "membre"

    def __str__(self):
        return self.full_name

    @property
    def full_name(self):
        return f"{self.last_name} {self.first_name}".strip()

    @property
    def short_name(self):
        """"Ngo Nyemb Christelle" -> "Ngo Nyemb C." (design: list rows)."""
        return f"{self.last_name} {self.first_name[:1]}.".strip() if self.first_name else self.last_name

    @property
    def age(self):
        if not self.birth_date:
            return None
        today = date.today()
        return today.year - self.birth_date.year - ((today.month, today.day) < (self.birth_date.month, self.birth_date.day))

    @property
    def is_minor(self):
        return self.age is not None and self.age < 18

    # --- PIN -------------------------------------------------------------

    def set_pin(self, raw_pin, temporary=False):
        self.pin = make_password(raw_pin)
        self.pin_failed_attempts = 0
        self.pin_locked_until = None
        self.pin_must_change = temporary

    def check_pin(self, raw_pin):
        return bool(self.pin) and check_password(raw_pin, self.pin)

    @property
    def has_pin(self):
        return bool(self.pin)

    def pin_locked(self, now=None):
        return self.pin_locked_until is not None and self.pin_locked_until > (now or timezone.now())

    # --- Roles and permissions -------------------------------------------

    def active_assignments(self, on=None):
        return RoleAssignment.objects.active(on).filter(user=self).select_related("role")

    def role_slugs(self, on=None):
        return {a.role.slug for a in self.active_assignments(on)}

    def display_role(self, on=None):
        """The role shown next to what the member posts (owner, 2026-10-26):
        the bureau role first, then any other; "… du jour" for a role of the
        day; "" for a plain member."""
        order = {Role.Kind.BUREAU: 0, Role.Kind.TEMPORARY: 1, Role.Kind.STANDARD: 2, Role.Kind.SYSTEM: 3}
        held = [a for a in self.active_assignments(on) if a.role.slug not in ("membre", registry.SUPER_ADMIN_SLUG)]
        if not held:
            return ""
        a = min(held, key=lambda a: (order.get(a.role.kind, 9), a.role.sort_order))
        name = a.role.name
        if a.is_one_day and "du jour" not in name.lower():
            name = f"{name} du jour"
        return name

    def permission_set(self, on=None):
        """{(resource, action)} granted by every active role, minus locked cells."""
        granted = set()
        for a in self.active_assignments(on):
            for res, act in a.role.permissions.values_list("resource", "action"):
                if not registry.is_locked(a.role.slug, res, act):
                    granted.add((res, act))
        # A locked cell on *any* held role wins (separation of duties is
        # about the person, not the role row).
        slugs = self.role_slugs(on)
        for slug in slugs:
            granted -= registry.LOCKED.get(slug, set())
        # The super admin does and sees everything (owner, 2026-10-23), even
        # alongside a role whose cells are locked.
        if registry.SUPER_ADMIN_SLUG in slugs:
            granted |= registry.all_cells()
        return granted

    def can(self, resource, action):
        return (resource, action) in self.permission_set()

    @property
    def group_status(self):
        """Status in the current group (Membership.status); the account's
        own status when no group is set or the person isn't a member."""
        if hasattr(self, "gstatus"):
            return self.gstatus
        gid = current_group_id()
        if gid is not None:
            from apps.core.models import Membership

            st = Membership.all_groups.filter(user=self, group_id=gid).values_list("status", flat=True).first()
            if st:
                return st
        return self.status

    def get_group_status_display(self):
        return dict(self.Status.choices).get(self.group_status, self.group_status)

    @property
    def is_super_admin(self):
        # Platform role: looked up across groups, whatever group is current.
        return RoleAssignment.all_groups.active().filter(
            user=self, role__slug=registry.SUPER_ADMIN_SLUG, role__group__isnull=True
        ).exists()

    def groups_joined(self):
        # Suspended or archived in a group: no way into it from the app.
        from apps.core.models import Group, Membership

        closed = Membership.all_groups.filter(user=self, status__in=["suspendu", "archive"]).values("group_id")
        return (Group.objects.filter(memberships__user=self, memberships__is_active=True, is_active=True)
                .exclude(pk__in=closed).order_by("memberships__created_at"))

    def tabs(self):
        perms = self.permission_set()
        return [key for key, need in registry.TABS if need is None or need in perms]


class Role(models.Model):
    class Kind(models.TextChoices):
        BUREAU = "bureau", "Bureau (mandat)"
        SYSTEM = "systeme", "Système"
        TEMPORARY = "temporaire", "Temporaire"
        STANDARD = "standard", "Standard"

    # Each group has its own roles, started from the default set; platform
    # roles (super admin) belong to no group.
    group = models.ForeignKey("core.Group", on_delete=models.CASCADE, null=True, blank=True, default=default_group_id, related_name="roles")
    slug = models.SlugField()
    name = models.CharField(max_length=80)
    kind = models.CharField(max_length=12, choices=Kind.choices, default=Kind.STANDARD)
    mandate_months = models.PositiveSmallIntegerField(
        null=True, blank=True, help_text="Durée proposée pour une affectation (24 pour le bureau)."
    )
    is_archived = models.BooleanField(default=False)
    sort_order = models.PositiveSmallIntegerField(default=100)
    # Can be requested in the app for one day, for an active member with no
    # role (owner, 2026-10-23: président, censeur, secrétaire, formateur,
    # commissaire aux comptes, trésorier "du jour").
    daily = models.BooleanField("peut être donné pour une journée", default=False)

    objects = scoped(with_platform=True)
    all_groups = models.Manager()

    class Meta:
        ordering = ["sort_order", "name"]
        verbose_name = "rôle"
        constraints = [models.UniqueConstraint(fields=["group", "slug"], name="role_slug_per_group")]

    def __str__(self):
        return self.name


class RolePermission(models.Model):
    role = models.ForeignKey(Role, on_delete=models.CASCADE, related_name="permissions")
    resource = models.CharField(max_length=40, choices=[(k, v[1]) for k, v in registry.RESOURCES.items()])
    action = models.CharField(max_length=10, choices=list(registry.ACTION_LABELS.items()))

    class Meta:
        constraints = [models.UniqueConstraint(fields=["role", "resource", "action"], name="uniq_role_perm")]

    def __str__(self):
        return f"{self.role.slug}: {self.resource}.{self.action}"


class AssignmentQuerySet(models.QuerySet):
    def active(self, on=None):
        on = on or timezone.localdate()
        return self.filter(revoked_at__isnull=True, starts_on__lte=on).filter(Q(ends_on__isnull=True) | Q(ends_on__gte=on))


class RoleAssignment(models.Model):
    """One person holding one role for a dated span.

    A temporary role (censeur du jour) simply stops being active after
    `ends_on` — nothing has to run for it to expire.
    """

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="assignments")
    role = models.ForeignKey(Role, on_delete=models.PROTECT, related_name="assignments")
    starts_on = models.DateField(default=date.today)
    ends_on = models.DateField(null=True, blank=True)
    reason = models.CharField(max_length=240)
    assigned_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name="+")
    created_at = models.DateTimeField(auto_now_add=True)
    revoked_at = models.DateTimeField(null=True, blank=True)
    revoked_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name="+")

    objects = scoped("role__group", with_platform=True, queryset=AssignmentQuerySet)
    all_groups = AssignmentQuerySet.as_manager()

    class Meta:
        ordering = ["-starts_on"]
        constraints = [
            models.CheckConstraint(
                condition=Q(ends_on__isnull=True) | Q(ends_on__gte=models.F("starts_on")),
                name="assignment_ends_after_start",
            )
        ]

    def __str__(self):
        return f"{self.user} · {self.role}"

    @property
    def is_one_day(self):
        """A role held for a single day (owner, 2026-10-23: censeur du jour,
        and any bureau role, can be given to someone for one activity)."""
        return self.ends_on is not None and self.ends_on == self.starts_on


class RoleRequest(models.Model):
    """A bureau member proposes a role for someone (design: dashboard →
    "Demandes de rôle"); a super admin approves it in the back-office."""

    class Status(models.TextChoices):
        PENDING = "pending", "En attente"
        APPROVED = "approved", "Approuvée"
        REFUSED = "refused", "Refusée"

    member = models.ForeignKey(User, on_delete=models.CASCADE, related_name="role_requests")
    role = models.ForeignKey(Role, on_delete=models.CASCADE, related_name="+")
    starts_on = models.DateField()
    ends_on = models.DateField(null=True, blank=True)
    reason = models.CharField(max_length=240)
    requested_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name="+")
    status = models.CharField(max_length=9, choices=Status.choices, default=Status.PENDING)
    decided_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name="+")
    created_at = models.DateTimeField(auto_now_add=True)

    objects = scoped("role__group")
    all_groups = models.Manager()

    class Meta:
        ordering = ["-created_at"]
