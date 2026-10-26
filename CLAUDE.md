# MSG Gestion

A group management platform: members, cash book, calendar and duty planning, announcements.
Its first group is the Mouvement Garde Suisse, Paroisse Notre-Dame de Lourdes de Yapoma
(Douala), and it is meant to serve other groups later, so group-specific facts (name, place,
amounts, times) live in `core.Settings`, not in code or copy.
Two surfaces: the Android app (iOS-compatible) for the group's members and officers, and a web
back-office that is the platform's administration console, for super admins and the back-office
staff teams (support, IT helpdesk, integration ops; `registry.STAFF_ROLES`), each limited to its
areas. These platform accounts work only in the back-office.

Built on the Spekooh architecture playbook (`app-architecture-playbook` skill). Read its
"Lessons learned" table before debugging anything that only fails when deployed.

## Layout

- `backend/` — Django + DRF. Apps: `accounts` (members, PIN login, roles, permissions),
  `core` (audit log, SMS codes, health check), `backoffice` (server-rendered web back-office).
- `app/` — Flutter client. Screens depend on repository interfaces in
  `lib/data/repositories/`, never on `ApiClient` directly.
- `design/` — the Claude Design source (`MSG Gestion.html`, `MSG Back-office.html` and their
  `.jsx`/`.css`). The reference for every screen. Open with `python3 -m http.server` from `design/`.
- `render.yaml` — staging + production Blueprint.

## Conventions

- **Every group-owned model is scoped.** Give it `group = FK("core.Group", default=default_group_id)`
  (or reach a group through a parent) and `objects = scoped(...)` + `all_groups = models.Manager()`
  (`apps/core/groups.py`). The current group comes from the app's `X-Group` header
  (`AppJWTAuthentication`) or the back-office session; `objects` then filters on it. Use
  `User.objects.members()` for a group's people (accounts are platform-wide; `Membership` puts one
  in a group). Jobs loop over groups with `in_group(g)`. Never create group data with several
  groups and no group chosen — `default_group_id` refuses on purpose.
- **Group-neutral wording.** Copy that names this group's people or habits ("le secrétaire
  général", "l'assise du samedi") belongs in settings or role names, not in fixed strings.
- **French first.** UI copy, server error messages and the back-office are in French. Every
  user-visible app string goes in both `app/lib/l10n/app_fr.arb` (template) and `app_en.arb`
  before `flutter gen-l10n`; CI fails on a key missing from either.
- **Permissions come from the server.** The role → permission matrix lives in the database
  (edited in the back-office); the *vocabulary* and the fixed rules (separation of duties,
  two super admins minimum) live in `backend/apps/accounts/registry.py`. The app never decides
  which tabs to show; it renders `/api/me/`'s `tabs`.
- **Every sensitive change goes through `apps/accounts/services.py`**, which enforces the rules
  and writes `core.AuditLog` with a mandatory reason. Don't assign roles or edit permissions with
  raw ORM calls outside tests.
- **Refusals are audited outside the transaction** that refuses them (an audit row written in a
  block that then raises is rolled back with it).
- **Postgres + Redis everywhere**, including tests. No SQLite.
- Design tokens: `app/lib/theme/tokens.dart` and `backend/static/backoffice/` are the source of
  truth; `DESIGN.md` logs every decision.

## Docs to keep current

`BETA_CHANGES.md` (one numbered section per change, with how to verify), `DESIGN.md` (dated
decision log), `TODOS.md` (owner actions vs. engineering), `RENDER_STAGING.md` /
`RENDER_PRODUCTION.md`, `RUNNING_LOCALLY.md`, `SECURITY.md`.
