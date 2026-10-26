from django.conf import settings
from django.core.validators import RegexValidator
from django.db import models

from .groups import default_group_id, scoped


class Group(models.Model):
    """A group using the MSG platform (e.g. the Mouvement Garde Suisse).
    Its people are linked through Membership; its roles, money, calendar,
    planning and announcements all carry it."""

    name = models.CharField(max_length=120)
    slug = models.SlugField(unique=True)
    # False = deleted by two super admins: hidden from the app and the
    # back-office's group list, its data kept; a super admin can restore it.
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    deleted_at = models.DateTimeField(null=True, blank=True)
    deleted_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="+")

    class Meta:
        ordering = ["name"]
        verbose_name = "groupe"

    def __str__(self):
        return self.name


class GroupDeletion(models.Model):
    """Deleting a group takes two super admins (owner, 2026-10-23): one asks,
    with a reason; another confirms within DELETION_WINDOW. The group is
    then hidden, its data kept (owner: "hide the group and keep its data")."""

    class Status(models.TextChoices):
        PENDING = "pending", "En attente"
        CANCELLED = "cancelled", "Annulée"
        DONE = "done", "Effectuée"

    group = models.ForeignKey(Group, on_delete=models.CASCADE, related_name="deletions")
    reason = models.TextField(max_length=600)
    status = models.CharField(max_length=12, choices=Status.choices, default=Status.PENDING)
    requested_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, related_name="+")
    requested_at = models.DateTimeField(auto_now_add=True)
    decided_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="+")
    decided_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ["-requested_at"]

    def __str__(self):
        return f"Suppression de {self.group}"


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


PRIVACY_DRAFT = """Politique de confidentialité — brouillon à faire relire.

MSG est une plateforme de gestion de groupes. Elle conserve, pour chaque membre : nom, prénoms, numéro de téléphone, date de naissance, ville, photo de profil (facultative), rôles, présences, contributions et paiements, ainsi que, pour les mineurs, le contact d’un parent.

Ces données servent uniquement à la vie du groupe : liste des membres, calendrier, planning des services, caisse et annonces. Elles ne sont ni vendues ni partagées hors du groupe et du partenaire qui administre la plateforme.

Chacun ne voit que ce que son rôle permet ; les données sensibles (finances, contacts des mineurs) sont réservées aux responsables concernés. Chaque modification importante est enregistrée dans un journal.

Les données sont hébergées chez nos prestataires techniques (base de données et stockage des fichiers). Le code PIN n’est jamais conservé en clair.

Pour consulter, corriger ou supprimer vos données, contactez le responsable de votre groupe ou le partenaire (rubrique Aide)."""

TERMS_DRAFT = """Conditions d’utilisation — brouillon à faire relire.

MSG est réservée aux membres des groupes inscrits sur la plateforme. Votre accès est créé par le partenaire à la demande du responsable de votre groupe.

Votre code PIN est personnel : ne le communiquez à personne. Prévenez le responsable de votre groupe si vous pensez qu’il est connu d’un tiers.

Les informations publiées (annonces, convocations, calendrier) engagent leur auteur et son rôle dans le groupe. Utilisez l’application avec respect et uniquement pour la vie du groupe.

Le partenaire peut suspendre un accès en cas d’usage abusif, à la demande du groupe ou pour la sécurité de la plateforme."""


class PlatformSettings(models.Model):
    """The partner's own details (back-office → Plateforme), shown in the
    app's Aide / À propos (owner, 2026-10-26). One row for the platform."""

    support_phone = models.CharField("téléphone d’assistance", max_length=20, blank=True)
    support_whatsapp = models.CharField("WhatsApp d’assistance", max_length=20, blank=True)
    support_email = models.EmailField("e-mail de contact", blank=True)
    website = models.URLField("site web", blank=True)
    privacy_text = models.TextField("politique de confidentialité", default=PRIVACY_DRAFT)
    terms_text = models.TextField("conditions d’utilisation", default=TERMS_DRAFT)
    # Goes up each time terms_text changes; members accept it again at login.
    terms_version = models.PositiveIntegerField("version des conditions", default=1)

    class Meta:
        verbose_name = "réglages de la plateforme"

    @classmethod
    def get(cls):
        obj, _ = cls.objects.get_or_create(pk=1)
        return obj


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


# The colours offered in the back-office and the app (white text stays
# readable on each: contrast ≥ 4.5). Any other #RRVVBB is accepted too.
APP_COLORS = [
    ("#2E7D46", "Vert"), ("#00695C", "Sarcelle"), ("#1E5AA8", "Bleu"), ("#23395B", "Bleu nuit"),
    ("#5B3FA0", "Violet"), ("#8E1B3A", "Bordeaux"), ("#B3261E", "Rouge"), ("#7A4E1D", "Brun"),
    ("#8A6514", "Or"),
]


class Settings(models.Model):
    """A group's settings (back-office → Paramètres): place, motto, welcome
    message, amounts and times. One row per group; the name is the group's."""

    group = models.OneToOneField(Group, on_delete=models.CASCADE, default=default_group_id, related_name="settings")
    parish = models.CharField("lieu ou rattachement", max_length=160, blank=True)
    motto = models.CharField(max_length=120, blank=True)
    # Shown to the group's members when they open the app (owner, 2026-10-23).
    welcome_message = models.TextField("message de bienvenue", max_length=600, blank=True)
    # The app's main colour for this group (owner, 2026-10-23); members can
    # still pick their own in the app.
    color = models.CharField("couleur de l’application", max_length=7, default="#2E7D46",
                             validators=[RegexValidator(r"^#[0-9A-Fa-f]{6}$", "Couleur au format #RRVVBB.")])
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
