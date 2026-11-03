from django.conf import settings
from django.core.validators import MaxValueValidator, MinValueValidator, RegexValidator
from django.db import models

from .groups import default_group_id, scoped


class Network(models.Model):
    """A family of groups in levels, like the MGS's parish groups, zones
    paroissiales and dioceses (owner, 2026-11-03: "similar to the government
    system"). Created in the back-office, which also names its levels. A
    group of level 2 or more is an umbrella: a full group of its own (its
    bureau, cash book, calendar) with groups of lower levels attached."""

    # Up to six (owner, 2026-11-03: the Church goes paroisse › zone ›
    # diocèse › province › national; other organisations may need more).
    LEVELS = (1, 2, 3, 4, 5, 6)

    name = models.CharField("nom du réseau", max_length=120)
    level1 = models.CharField("niveau 1", max_length=40, default="Groupe local")
    level2 = models.CharField("niveau 2", max_length=40, default="Zone")
    level3 = models.CharField("niveau 3", max_length=40, default="Région")
    level4 = models.CharField("niveau 4", max_length=40, default="National")
    level5 = models.CharField("niveau 5", max_length=40, blank=True)
    level6 = models.CharField("niveau 6", max_length=40, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    created_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="+")

    class Meta:
        ordering = ["name"]
        verbose_name = "réseau"

    def __str__(self):
        return self.name

    def level_name(self, level):
        return getattr(self, f"level{level}", "") if level in self.LEVELS else ""

    @property
    def labels(self):
        return [self.level_name(n) for n in self.LEVELS]


class NetworkLevelModel(models.Model):
    """For a level of a network, the group whose roles (names, mandates,
    permissions) every new group of that level starts with (owner,
    2026-11-03: a zone or a diocese has its own roles — coordinateur,
    aumônier… — not a parish's). Edited like any group's roles."""

    network = models.ForeignKey(Network, on_delete=models.CASCADE, related_name="models")
    level = models.PositiveSmallIntegerField()
    group = models.ForeignKey("Group", on_delete=models.CASCADE, related_name="+")

    class Meta:
        constraints = [models.UniqueConstraint(fields=["network", "level"], name="one_model_per_level")]


class Group(models.Model):
    """A group using the Huddle platform (e.g. the Mouvement Garde Suisse).
    Its people are linked through Membership; its roles, money, calendar,
    planning and announcements all carry it. Like a Slack workspace, it shows
    its own name and logo inside the app (owner, 2026-11-02)."""

    name = models.CharField(max_length=120)
    slug = models.SlugField(unique=True)
    # Shown where the logo would be when there is none ("MSG"); else the
    # initials of the name.
    short_name = models.CharField("sigle", max_length=8, blank=True)
    logo = models.ImageField(upload_to="groups/", null=True, blank=True)
    # False = deleted by two super admins: hidden from the app and the
    # back-office's group list, its data kept; a super admin can restore it.
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    deleted_at = models.DateTimeField(null=True, blank=True)
    deleted_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="+")
    # Its place in a network (owner, 2026-11-03): the back-office sets the
    # network and the level; the parent comes from an invitation the group
    # accepted (apps.core.network). An umbrella only informs the groups
    # under it; it has no say in how they run.
    network = models.ForeignKey(Network, on_delete=models.SET_NULL, null=True, blank=True, related_name="groups")
    level = models.PositiveSmallIntegerField("niveau", default=1, choices=[(n, str(n)) for n in Network.LEVELS])
    parent = models.ForeignKey("self", on_delete=models.SET_NULL, null=True, blank=True, related_name="children")
    attached_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ["name"]
        verbose_name = "groupe"

    def __str__(self):
        return self.name

    SMALL_WORDS = {"de", "du", "des", "la", "le", "les", "et", "d", "l", "of", "the", "and"}

    @property
    def initials(self):
        """The sigle, else the first letters of the name's main words (3 at
        most): "Chorale Saint Joseph" → "CSJ"."""
        if self.short_name:
            return self.short_name.upper()
        words = [w for w in self.name.replace("’", " ").replace("'", " ").split() if w.lower() not in self.SMALL_WORDS]
        return "".join(w[0] for w in words[:3]).upper() or "?"

    @property
    def level_name(self):
        return self.network.level_name(self.level) if self.network_id else ""

    def ancestors(self):
        """Parent, grand-parent… (nearest first)."""
        out, g, seen = [], self.parent, {self.pk}
        while g is not None and g.pk not in seen:
            out.append(g)
            seen.add(g.pk)
            g = g.parent
        return out

    def descendants(self):
        """Every group below, at any depth (active ones)."""
        out, frontier = [], [self.pk]
        while frontier:
            kids = list(Group.objects.filter(parent_id__in=frontier, is_active=True))
            out += kids
            frontier = [k.pk for k in kids]
        return out


class GroupLink(models.Model):
    """Two groups twinned (owner, 2026-11-03: groups "communicate with each
    other"), in any network or none: one président issues a code, the
    other accepts it. Either side ends it, with a reason. Stored with the
    lower id first."""

    a = models.ForeignKey(Group, on_delete=models.CASCADE, related_name="+")
    b = models.ForeignKey(Group, on_delete=models.CASCADE, related_name="+")
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    created_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, related_name="+")
    ended_at = models.DateTimeField(null=True, blank=True)
    ended_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="+")
    ended_reason = models.CharField(max_length=300, blank=True)

    class Meta:
        constraints = [models.UniqueConstraint(fields=["a", "b"], name="one_link_per_pair")]

    def __str__(self):
        return f"{self.a} ↔ {self.b}"

    def other(self, group):
        return self.b if self.a_id == group.pk else self.a


class GroupShare(models.Model):
    """What a group shows the groups of its network (owner, 2026-11-03:
    "share information base on what they allow to share"). One row per
    audience and kind; no row = nothing shared. Audience "up" = the groups
    above it; neighbours and twinned groups come with links."""

    class Audience(models.TextChoices):
        UP = "up", "Groupes au-dessus"
        NEIGHBOURS = "neighbours", "Groupes voisins"
        TWINS = "twins", "Groupes jumelés"

    class Level(models.TextChoices):
        NONE = "none", "Rien"
        SUMMARY = "summary", "Résumé"
        DETAIL = "detail", "Détail"

    group = models.ForeignKey(Group, on_delete=models.CASCADE, related_name="shares")
    audience = models.CharField(max_length=12, choices=Audience.choices, default=Audience.UP)
    kind = models.CharField(max_length=16)
    level = models.CharField(max_length=8, choices=Level.choices, default=Level.NONE)
    updated_at = models.DateTimeField(auto_now=True)
    updated_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="+")

    class Meta:
        constraints = [models.UniqueConstraint(fields=["group", "audience", "kind"], name="one_share_per_kind")]

    def __str__(self):
        return f"{self.group} · {self.audience} · {self.kind}: {self.level}"


class GroupInvitation(models.Model):
    """An umbrella group invites a group of a lower level to join it
    (owner, 2026-11-03: "joind each group with invitation link"). The code
    is single-use; the invited group's président accepts it in the app."""

    class Status(models.TextChoices):
        PENDING = "pending", "En attente"
        USED = "used", "Utilisée"
        REVOKED = "revoked", "Annulée"

    class Kind(models.TextChoices):
        ATTACH = "attach", "Rattachement"
        TWIN = "twin", "Jumelage"

    # For a twinning code (build 43), `umbrella` is simply the group that
    # issued it, at any level, in any network.
    umbrella = models.ForeignKey(Group, on_delete=models.CASCADE, related_name="invitations")
    kind = models.CharField(max_length=8, choices=Kind.choices, default=Kind.ATTACH)
    code = models.CharField(max_length=8, unique=True)
    status = models.CharField(max_length=8, choices=Status.choices, default=Status.PENDING)
    created_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, related_name="+")
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()
    used_by_group = models.ForeignKey(Group, on_delete=models.SET_NULL, null=True, blank=True, related_name="+")
    used_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="+")
    used_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"Invitation {self.code} · {self.umbrella}"

    @property
    def pretty(self):
        return f"{self.code[:4]}-{self.code[4:]}"


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
    # With "en congé": the last day of leave, if known (design: "En congé
    # jusqu’au 15 novembre"). The daily job makes the member active again after it.
    leave_until = models.DateField("en congé jusqu’au", null=True, blank=True)
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
        REPORT = "report", "Rapport"
        NETWORK = "network", "Réseau"

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
    # Optional second colour: the app's header goes from one to the other
    # (owner, 2026-10-29). Empty = a plain colour.
    color2 = models.CharField("deuxième couleur (dégradé)", max_length=7, blank=True,
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
    # A second, finance-only code to open Finances (owner, 2026-10-30).
    finance_code_required = models.BooleanField("code finances obligatoire", default=False)
    # --- Wider group settings (owner, 2026-11-02) -----------------------
    # Money & dues.
    currency = models.CharField("monnaie", max_length=8, default="FCFA")
    dues_monthly = models.PositiveIntegerField("cotisation mensuelle", default=0, help_text="0 = pas de cotisation mensuelle")
    dues_day = models.PositiveSmallIntegerField("jour de la cotisation", default=5, validators=[MinValueValidator(1), MaxValueValidator(28)])
    low_balance_alert = models.PositiveIntegerField("alerte de solde bas", default=0, help_text="0 = pas d’alerte")
    # Membership rules.
    probation_days = models.PositiveSmallIntegerField("période d’essai (jours)", default=0)
    max_leave_days = models.PositiveSmallIntegerField("congé maximum (jours)", default=0, help_text="0 = sans limite")
    absence_alert = models.PositiveSmallIntegerField("absences avant alerte", default=0, help_text="sur 90 jours ; 0 = pas d’alerte")
    inactive_months = models.PositiveSmallIntegerField("inactif après (mois)", default=0, help_text="0 = jamais signalé")
    # Events & duty.
    report_hours = models.PositiveSmallIntegerField("délai du rapport (heures)", default=24,
                                                    validators=[MinValueValidator(1), MaxValueValidator(168)])
    remind_before_hours = models.PositiveSmallIntegerField("rappel avant l’événement (heures)", default=2,
                                                           validators=[MinValueValidator(1), MaxValueValidator(12)])
    event_minutes = models.PositiveSmallIntegerField("durée par défaut d’un événement (minutes)", default=120,
                                                     validators=[MinValueValidator(15), MaxValueValidator(1440)])
    # Language & identity.
    language = models.CharField("langue par défaut", max_length=2, blank=True, default="",
                                choices=[("", "Celle du téléphone"), ("fr", "Français"), ("en", "English")])
    contact_phone = models.CharField("téléphone de contact", max_length=20, blank=True)
    contact_email = models.EmailField("e-mail de contact", blank=True)
    rules_text = models.TextField("règlement du groupe", max_length=6000, blank=True)
    website = models.URLField("lien (site, page, groupe WhatsApp)", blank=True)
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


class FaqEntry(models.Model):
    """A question and its answer in the app's Aide → Questions fréquentes
    (owner, 2026-11-02): common to every group (group empty) or one group's
    own. Written in the back-office by the platform team, often from a
    member's suggestion. Not scoped: the API picks common + current group."""

    group = models.ForeignKey(Group, on_delete=models.CASCADE, null=True, blank=True, related_name="faq")
    question = models.CharField(max_length=200)
    answer = models.TextField(max_length=3000)
    position = models.PositiveSmallIntegerField(default=0)
    updated_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, related_name="+")
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["position", "pk"]

    def __str__(self):
        return self.question


class FaqSuggestion(models.Model):
    """A member's proposed question (and answer) for the FAQ, sent from the
    app to the platform team, who edit and publish it or decline it."""

    class Status(models.TextChoices):
        PENDING = "pending", "À traiter"
        PUBLISHED = "published", "Publiée"
        DECLINED = "declined", "Non retenue"

    group = models.ForeignKey(Group, on_delete=models.CASCADE, related_name="+")
    author = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, related_name="+")
    question = models.CharField(max_length=200)
    answer = models.TextField(max_length=3000, blank=True)
    status = models.CharField(max_length=10, choices=Status.choices, default=Status.PENDING)
    created_at = models.DateTimeField(auto_now_add=True)
    decided_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, related_name="+")
    decided_at = models.DateTimeField(null=True, blank=True)
    note = models.CharField(max_length=300, blank=True)
    entry = models.ForeignKey(FaqEntry, on_delete=models.SET_NULL, null=True, blank=True, related_name="+")

    class Meta:
        ordering = ["-created_at"]
