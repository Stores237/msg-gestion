from django.conf import settings
from django.db import models
from django.db.models import Q, Sum

from apps.core.groups import default_group_id, scoped


class Collection(models.Model):
    """A solidarity collection (décès, maladie, médaille): every member owes
    the same amount, paid in thirds over a month (design: "Recouvrement par
    tiers")."""

    class Kind(models.TextChoices):
        DEATH = "deces", "Décès"
        ILLNESS = "maladie", "Maladie"
        MEDAL = "medaille", "Médaille, diplôme, sacrement"
        OTHER = "autre", "Autre"

    kind = models.CharField(max_length=10, choices=Kind.choices)
    title = models.CharField(max_length=140)
    amount_per_member = models.PositiveIntegerField()
    installments = models.PositiveSmallIntegerField(default=3)
    opened_on = models.DateField()
    closed_at = models.DateTimeField(null=True, blank=True)
    created_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, related_name="+")
    created_at = models.DateTimeField(auto_now_add=True)

    group = models.ForeignKey("core.Group", on_delete=models.CASCADE, default=default_group_id, related_name="+")
    objects = scoped()
    all_groups = models.Manager()

    class Meta:
        ordering = ["-opened_on", "-id"]

    def __str__(self):
        return self.title

    @property
    def is_open(self):
        return self.closed_at is None

    def tranches(self):
        """Cumulative thresholds: 2500 in 3 → [834, 1667, 2500] (design)."""
        base, rest = divmod(self.amount_per_member, self.installments)
        parts = [base + (1 if i < rest else 0) for i in range(self.installments)]
        out, total = [], 0
        for p in parts:
            total += p
            out.append(total)
        return out


class Due(models.Model):
    """Money one member owes: their share of a collection, or a fine."""

    class Kind(models.TextChoices):
        SOLIDARITY = "solidarite", "Contribution de solidarité"
        FINE = "amende", "Amende"
        REGISTRATION = "inscription", "Inscription"

    member = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="dues")
    kind = models.CharField(max_length=12, choices=Kind.choices)
    label = models.CharField(max_length=160)
    amount = models.PositiveIntegerField()
    collection = models.ForeignKey(Collection, on_delete=models.CASCADE, null=True, blank=True, related_name="dues")
    due_on = models.DateField(null=True, blank=True)
    cancelled = models.BooleanField(default=False)
    created_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, related_name="+")
    created_at = models.DateTimeField(auto_now_add=True)

    group = models.ForeignKey("core.Group", on_delete=models.CASCADE, default=default_group_id, related_name="+")
    objects = scoped()
    all_groups = models.Manager()

    class Meta:
        ordering = ["-created_at"]
        constraints = [models.UniqueConstraint(fields=["member", "collection"], condition=Q(collection__isnull=False), name="one_share_per_collection")]

    def paid(self):
        return self.entries.aggregate(t=Sum("amount"))["t"] or 0


class Entry(models.Model):
    """One line of the cash book. Who entered it and who validated it are
    always recorded (design: "qui a saisi, quand, qui a validé"). A
    validated entry can't be changed or deleted."""

    class Direction(models.TextChoices):
        IN = "in", "Entrée"
        OUT = "out", "Sortie"

    class Category(models.TextChoices):
        REGISTRATION = "inscription", "Inscriptions"
        FINE = "amende", "Amendes"
        DONATION = "aide_don", "Aides et dons"
        SOLIDARITY = "solidarite", "Contributions de solidarité"
        OTHER = "autre", "Autre"
        EXPENSE = "depense", "Dépenses"

    class Status(models.TextChoices):
        PENDING = "pending", "À valider"
        # Edited by the trésorier, then validated by him: the commissaire who
        # entered it finalises (owner, 2026-10-30: the two steps remain).
        TO_CONFIRM = "to_confirm", "À finaliser"
        VALIDATED = "validated", "Validé"

    direction = models.CharField(max_length=3, choices=Direction.choices)
    amount = models.PositiveIntegerField()
    category = models.CharField(max_length=12, choices=Category.choices)
    label = models.CharField(max_length=160)
    member = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT, null=True, blank=True, related_name="entries")
    collection = models.ForeignKey(Collection, on_delete=models.PROTECT, null=True, blank=True, related_name="entries")
    due = models.ForeignKey(Due, on_delete=models.PROTECT, null=True, blank=True, related_name="entries")
    date = models.DateField()
    status = models.CharField(max_length=10, choices=Status.choices, default=Status.PENDING)
    # Set by the app for entries made offline, so a retried upload never
    # records the same payment twice.
    client_uuid = models.UUIDField(null=True, blank=True, unique=True)
    created_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT, related_name="+")
    created_at = models.DateTimeField(auto_now_add=True)
    validated_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT, null=True, blank=True, related_name="+")
    validated_at = models.DateTimeField(null=True, blank=True)
    # "Modifié": the trésorier corrected the line before validating it.
    edited_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT, null=True, blank=True, related_name="+")
    edited_at = models.DateTimeField(null=True, blank=True)
    confirmed_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT, null=True, blank=True, related_name="+")
    confirmed_at = models.DateTimeField(null=True, blank=True)

    group = models.ForeignKey("core.Group", on_delete=models.CASCADE, default=default_group_id, related_name="+")
    objects = scoped()
    all_groups = models.Manager()

    class Meta:
        ordering = ["-date", "-created_at"]
        constraints = [models.CheckConstraint(condition=Q(amount__gt=0), name="entry_amount_positive")]

    @property
    def signed(self):
        return self.amount if self.direction == self.Direction.IN else -self.amount


class QuarterReport(models.Model):
    """A quarter's report, once the commissaire aux comptes validated it."""

    year = models.PositiveSmallIntegerField()
    quarter = models.PositiveSmallIntegerField()
    validated_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT, related_name="+")
    validated_at = models.DateTimeField(auto_now_add=True)
    closing_balance = models.IntegerField()

    group = models.ForeignKey("core.Group", on_delete=models.CASCADE, default=default_group_id, related_name="+")
    objects = scoped()
    all_groups = models.Manager()

    class Meta:
        constraints = [models.UniqueConstraint(fields=["group", "year", "quarter"], name="one_report_per_quarter")]


# --- Expense requests (owner, 2026-10-30) -------------------------------------------
#
# Any member asks for money for a purchase; the lead of the domain it
# concerns (or a coordinator the member tags) approves it, then the
# commissaire aux comptes, then the trésorier pays and posts the proof in the
# request's thread. Domains and their lead roles are each group's own
# (back-office → Paramètres).


class ExpenseDomain(models.Model):
    """What an expense is for (Formation, Liturgie, Matériel…) and the role
    that approves it first (the formateur for Formation, never the adjoint)."""

    group = models.ForeignKey("core.Group", on_delete=models.CASCADE, default=default_group_id, related_name="+")
    name = models.CharField(max_length=60)
    lead_role = models.ForeignKey("accounts.Role", on_delete=models.SET_NULL, null=True, blank=True, related_name="+")
    sort_order = models.PositiveSmallIntegerField(default=100)
    is_archived = models.BooleanField(default=False)

    objects = scoped()
    all_groups = models.Manager()

    class Meta:
        ordering = ["sort_order", "name"]

    def __str__(self):
        return self.name


class ExpenseRequest(models.Model):
    class Status(models.TextChoices):
        SUBMITTED = "submitted", "Chez le responsable"
        APPROVED = "approved", "Chez le commissaire aux comptes"
        TO_PAY = "to_pay", "Chez le trésorier"
        PAID = "paid", "Payée"
        REFUSED = "refused", "Refusée"
        CANCELLED = "cancelled", "Annulée"

    group = models.ForeignKey("core.Group", on_delete=models.CASCADE, default=default_group_id, related_name="+")
    requester = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT, related_name="+")
    domain = models.ForeignKey(ExpenseDomain, on_delete=models.PROTECT, related_name="requests")
    title = models.CharField(max_length=140)
    description = models.TextField(max_length=1000, blank=True)
    amount = models.PositiveIntegerField()
    # Coordinators the member asked to look at it too; any one of them, or
    # a holder of the domain's lead role, decides the first step.
    tagged = models.ManyToManyField(settings.AUTH_USER_MODEL, blank=True, related_name="+")
    status = models.CharField(max_length=10, choices=Status.choices, default=Status.SUBMITTED)
    lead_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="+")
    lead_at = models.DateTimeField(null=True, blank=True)
    audit_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="+")
    audit_at = models.DateTimeField(null=True, blank=True)
    paid_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="+")
    paid_at = models.DateTimeField(null=True, blank=True)
    paid_amount = models.PositiveIntegerField(null=True, blank=True)
    entry = models.OneToOneField("Entry", on_delete=models.PROTECT, null=True, blank=True, related_name="expense")
    closed_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="+")
    closed_at = models.DateTimeField(null=True, blank=True)
    close_reason = models.CharField(max_length=300, blank=True)
    # A new request made after cancelling this one (to match the exact amount):
    # the cancelled one stays on record.
    replaces = models.OneToOneField("self", on_delete=models.SET_NULL, null=True, blank=True, related_name="replaced_by")
    created_at = models.DateTimeField(auto_now_add=True)

    objects = scoped()
    all_groups = models.Manager()

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.title} · {self.amount} FCFA"


class ExpenseMessage(models.Model):
    """The request's thread: each step's decision, comments, and the
    trésorier's proof of payment (a screenshot)."""

    class Kind(models.TextChoices):
        STEP = "step", "Étape"
        COMMENT = "comment", "Commentaire"
        PROOF = "proof", "Preuve de paiement"

    request = models.ForeignKey(ExpenseRequest, on_delete=models.CASCADE, related_name="messages")
    author = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, related_name="+")
    kind = models.CharField(max_length=8, choices=Kind.choices, default=Kind.COMMENT)
    body = models.TextField(max_length=1000, blank=True)
    file = models.FileField(upload_to="expenses/%Y/%m/", null=True, blank=True)
    file_name = models.CharField(max_length=160, blank=True)
    content_type = models.CharField(max_length=60, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    objects = scoped("request__group")
    all_groups = models.Manager()

    class Meta:
        ordering = ["created_at"]
