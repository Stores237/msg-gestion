from datetime import date

from django.contrib.auth.base_user import AbstractBaseUser, BaseUserManager
from django.contrib.auth.hashers import check_password, make_password
from django.contrib.auth.models import PermissionsMixin
from django.db import models
from django.db.models import Q
from django.utils import timezone

from . import registry
from .phone import normalize_phone


class UserManager(BaseUserManager):
    use_in_migrations = True

    def create_user(self, phone, password=None, **extra):
        user = self.model(phone=normalize_phone(phone), **extra)
        user.set_password(password)  # None -> unusable: no back-office login
        user.save(using=self._db)
        return user

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

    def set_pin(self, raw_pin):
        self.pin = make_password(raw_pin)
        self.pin_failed_attempts = 0
        self.pin_locked_until = None

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

    def permission_set(self, on=None):
        """{(resource, action)} granted by every active role, minus locked cells."""
        granted = set()
        for a in self.active_assignments(on):
            for res, act in a.role.permissions.values_list("resource", "action"):
                if not registry.is_locked(a.role.slug, res, act):
                    granted.add((res, act))
        # A locked cell on *any* held role wins (separation of duties is
        # about the person, not the role row).
        for slug in self.role_slugs(on):
            granted -= registry.LOCKED.get(slug, set())
        return granted

    def can(self, resource, action):
        return (resource, action) in self.permission_set()

    @property
    def is_super_admin(self):
        return registry.SUPER_ADMIN_SLUG in self.role_slugs()

    def tabs(self):
        perms = self.permission_set()
        return [key for key, need in registry.TABS if need is None or need in perms]


class Role(models.Model):
    class Kind(models.TextChoices):
        BUREAU = "bureau", "Bureau (mandat)"
        SYSTEM = "systeme", "Système"
        TEMPORARY = "temporaire", "Temporaire"
        STANDARD = "standard", "Standard"

    slug = models.SlugField(unique=True)
    name = models.CharField(max_length=80)
    kind = models.CharField(max_length=12, choices=Kind.choices, default=Kind.STANDARD)
    mandate_months = models.PositiveSmallIntegerField(
        null=True, blank=True, help_text="Durée proposée pour une affectation (24 pour le bureau)."
    )
    is_archived = models.BooleanField(default=False)
    sort_order = models.PositiveSmallIntegerField(default=100)

    class Meta:
        ordering = ["sort_order", "name"]
        verbose_name = "rôle"

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

    objects = AssignmentQuerySet.as_manager()

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
