from django.conf import settings
from django.db import models

# Posts in the order they open as the service grows (design: "Taille du
# service → postes"). Every post has a Pariso side and a Yapoma side.
POSTS = ["premiere_centrale", "deuxieme_centrale", "controle", "petites_portes", "mesanie"]
SIDES = ["pariso", "yapoma"]
SIZES = [2, 4, 6, 8, 10, 12]


def slots_for(size):
    """(post, side, index) for a service of `size` guards. At 12 the mésanie
    takes two guards per side."""
    if size not in SIZES:
        return []
    posts = POSTS[: min(size // 2, 5)]
    out = [(p, s, 0) for p in posts for s in SIDES]
    if size == 12:
        out += [("mesanie", s, 1) for s in SIDES]
    return out


class ServiceGroup(models.Model):
    """A standing team (Saint-Michel, Sainte-Agnès…) with its chef."""

    name = models.CharField(max_length=80, unique=True)
    chef = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="led_groups")
    members = models.ManyToManyField(settings.AUTH_USER_MODEL, related_name="service_groups", blank=True)

    class Meta:
        ordering = ["name"]

    def __str__(self):
        return self.name


class Service(models.Model):
    """The duty side of a calendar event: how many guards, which group,
    and whether the plan was published to members."""

    event = models.OneToOneField("events.Event", on_delete=models.CASCADE, related_name="service")
    size = models.PositiveSmallIntegerField()
    group = models.ForeignKey(ServiceGroup, on_delete=models.SET_NULL, null=True, blank=True, related_name="services")
    published_at = models.DateTimeField(null=True, blank=True)

    def __str__(self):
        return f"{self.event} · {self.size}"


class Assignment(models.Model):
    class Status(models.TextChoices):
        PENDING = "pend", "À confirmer"
        CONFIRMED = "conf", "Confirmé"
        SWAP = "swap", "Échange demandé"
        REPLACED = "repl", "Remplacé"
        ABSENT = "absent", "Absence déclarée"

    service = models.ForeignKey(Service, on_delete=models.CASCADE, related_name="assignments")
    post = models.CharField(max_length=20, choices=[(p, p) for p in POSTS])
    side = models.CharField(max_length=6, choices=[(s, s) for s in SIDES])
    index = models.PositiveSmallIntegerField(default=0)
    member = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="duties")
    status = models.CharField(max_length=6, choices=Status.choices, default=Status.PENDING)
    assigned_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, related_name="+")
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        constraints = [models.UniqueConstraint(fields=["service", "post", "side", "index"], name="one_member_per_slot")]


class Request(models.Model):
    """A swap (member → colleague; colleague accepts; chef approves) or an
    absence (member can't come; a censeur picks a replacement)."""

    class Kind(models.TextChoices):
        SWAP = "swap", "Échange"
        ABSENCE = "absence", "Absence"

    class Status(models.TextChoices):
        PROPOSED = "proposed", "En attente du collègue"
        ACCEPTED = "accepted", "En attente du chef"
        APPROVED = "approved", "Approuvé"
        REFUSED = "refused", "Refusé"

    kind = models.CharField(max_length=8, choices=Kind.choices)
    assignment = models.ForeignKey(Assignment, on_delete=models.CASCADE, related_name="requests")
    requester = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="+")
    target = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, null=True, blank=True, related_name="duty_requests_received")
    reason = models.CharField(max_length=240, blank=True)
    status = models.CharField(max_length=9, choices=Status.choices)
    decided_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="+")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]


class AlbRotation(models.Model):
    """Who washes the albs (aubes) which week (design: "Lavage des aubes")."""

    class Status(models.TextChoices):
        TO_WASH = "a_laver", "À laver"
        WASHED = "lavees", "Lavées"
        RETURNED = "rendues", "Rendues"

    week_start = models.DateField(unique=True)
    group = models.ForeignKey(ServiceGroup, on_delete=models.SET_NULL, null=True, blank=True, related_name="+")
    responsible = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="+")
    albs = models.PositiveSmallIntegerField(default=12)
    status = models.CharField(max_length=8, choices=Status.choices, default=Status.TO_WASH)

    class Meta:
        ordering = ["week_start"]
