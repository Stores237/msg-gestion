"""
The permission vocabulary, in code.

Roles and which boxes are ticked live in the database (the super admin
edits them in the back-office). *What can be ticked at all* lives here:
every resource, the actions that make sense for it, and the fixed
separation-of-duties rules no role edit can override.
"""

VIEW, CREATE, CHANGE, VALIDATE, DELETE, EXPORT = "view", "create", "change", "validate", "delete", "export"
ACTIONS = [VIEW, CREATE, CHANGE, VALIDATE, DELETE, EXPORT]
ACTION_LABELS = {
    VIEW: "Voir",
    CREATE: "Créer",
    CHANGE: "Modifier",
    VALIDATE: "Valider",
    DELETE: "Supprimer",
    EXPORT: "Exporter",
}

MODULES = {
    "members": "Membres",
    "finances": "Finances",
    "calendar": "Calendrier et planning",
    "announcements": "Annonces",
    "backoffice": "Back-office",
}

# resource key -> (module, label, applicable actions, sensitive?)
RESOURCES = {
    "members.profile": ("members", "Fiches membres", [VIEW, CREATE, CHANGE, DELETE, EXPORT], False),
    "members.minor_contacts": ("members", "Contacts des mineurs", [VIEW, CHANGE, EXPORT], True),
    "finances.cashbook": ("finances", "Livre de caisse", ACTIONS, False),
    "finances.solidarity": ("finances", "Contributions de solidarité", ACTIONS, False),
    "finances.report": ("finances", "Rapport trimestriel", [VIEW, VALIDATE, EXPORT], False),
    "calendar.events": ("calendar", "Événements", [VIEW, CREATE, CHANGE, DELETE, EXPORT], False),
    "calendar.attendance": ("calendar", "Appel des présences", [VIEW, CHANGE, EXPORT], False),
    "calendar.planning": ("calendar", "Planning des services", ACTIONS, False),
    "announcements.posts": ("announcements", "Annonces et convocations", [VIEW, CREATE, CHANGE, DELETE], False),
    "backoffice.users": ("backoffice", "Utilisateurs et rôles", [VIEW, CREATE, CHANGE, DELETE, EXPORT], True),
    "backoffice.audit": ("backoffice", "Journal d’audit", [VIEW, EXPORT], True),
}

# Fixed rules (design: "le trésorier saisit, le commissaire aux comptes
# valide. Le super admin gère les accès sans voir les montants"). A locked
# cell can never be granted, whatever the database says.
LOCKED = {
    "tresorier": {("finances.cashbook", VALIDATE), ("finances.solidarity", VALIDATE), ("finances.report", VALIDATE)},
    "super-admin": {(res, act) for res, spec in RESOURCES.items() if spec[0] == "finances" for act in spec[2]},
}

# Two roles one person may never hold at the same time.
INCOMPATIBLE_ROLES = [
    ("tresorier", "commissaire-aux-comptes"),
]

# Bottom-nav tabs, in display order, and the permission that unlocks each.
# Accueil is always present.
TABS = [
    ("accueil", None),
    ("membres", ("members.profile", VIEW)),
    ("finances", ("finances.cashbook", VIEW)),
    ("calendrier", ("calendar.events", VIEW)),
    ("annonces", ("announcements.posts", VIEW)),
]

MIN_SUPER_ADMINS = 2
SUPER_ADMIN_SLUG = "super-admin"


def is_locked(role_slug, resource, action):
    return (resource, action) in LOCKED.get(role_slug, set())


def is_applicable(resource, action):
    return resource in RESOURCES and action in RESOURCES[resource][2]
