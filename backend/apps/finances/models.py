from django.conf import settings
from django.db import models
from django.db.models import Q, Sum


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
        EXPENSE = "depense", "Dépenses"

    class Status(models.TextChoices):
        PENDING = "pending", "À valider"
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

    class Meta:
        constraints = [models.UniqueConstraint(fields=["year", "quarter"], name="one_report_per_quarter")]
