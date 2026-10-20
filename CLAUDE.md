# MSG Gestion

Administration app for the Mouvement Garde Suisse, Paroisse Notre-Dame de Lourdes de
Yapoma (Douala): members, cash book, calendar and duty planning, announcements.
Android first (iOS-compatible), plus a web back-office for the super admin.

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
