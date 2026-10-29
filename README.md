# MSG Gestion

**MSG** is a group management platform: members, roles, cash book, calendar and duty
planning, reports and announcements, for any number of groups on one platform. Its first group
is the Mouvement Garde Suisse, Paroisse Notre-Dame de Lourdes de Yapoma (Douala); each group's
own facts (name, place, amounts, activity types, dress codes, welcome message, colour) live in
its settings, not in the code.

Developed and powered by **STORES** ("Propulsé par [S] STORES").

**Version 0.1.0 (build 23)** · staging: <https://msg-staging.onrender.com>
(`/healthz/` reports the deployed version and commit).

## Two surfaces

| | For | What |
|---|---|---|
| **Mobile app** (Flutter, Android first, iOS-ready) | The groups' members and officers | Accueil, calendar and events, duty planning (line-up, swaps, absences), roll call, chef de groupe reports, announcements and convocations with photos, finances (two hands: entry and validation), members, notifications, PIN login with app lock and fingerprint/face, offline use, French and English |
| **Web back-office** (Django templates) | The platform: super admins and the back-office staff teams (support, IT helpdesk, integration ops) | Groups, access requests, users and roles, permissions matrix, assignments, financial statements, group settings, staff, integrations, platform help texts, audit log |

Platform accounts work only in the back-office; group members only in the app. Permissions
come from the server (a role × permission matrix edited in the back-office, with fixed rules
such as separation of duties that no edit can override).

## Stack

- **Backend**: Python 3.13, Django 6.1 + Django REST Framework, PostgreSQL, Redis (throttling),
  Supabase Storage (S3) for files, Sentry. Apps in `backend/apps/`: `accounts`, `members`,
  `events`, `planning`, `finances`, `announcements`, `core`, `backoffice`.
- **App**: Flutter 3.44 (Dart 3.12), repository pattern (`app/lib/data/repositories/`), offline
  cache and outbox, l10n in `app/lib/l10n/` (French template + English).
- **Hosting**: Render (Docker) for staging and production (`render.yaml`), Supabase for the
  database and storage, beta APKs shared by link.

## Repository

```
backend/   Django API, back-office, migrations, tests
app/       Flutter app and its tests
design/    The design reference (Claude Design export): every screen starts here
*.md       The docs below
```

## Quick start

```bash
# Backend (needs PostgreSQL and Redis running)
cd backend
python3 -m venv .venv && .venv/bin/pip install -r requirements.txt
cp .env.example .env
.venv/bin/python manage.py migrate
.venv/bin/python manage.py seed_demo      # demo members, dev only
.venv/bin/python manage.py runserver 0.0.0.0:8000

# App
cd app
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

Back-office at <http://localhost:8000/bo/> (demo super admin `677000001`; the SMS code prints in
the server output). Full details, demo accounts and tests: **`RUNNING_LOCALLY.md`**.

**Tests**: `cd backend && .venv/bin/pytest && .venv/bin/ruff check .` ·
`cd app && flutter test && flutter analyze`.

## Versions and releases

One version for app and server: `app/pubspec.yaml` (`X.Y.Z+BUILD`) and
`backend/config/version.py` (`X.Y.Z`), kept equal by a test. Every APK gets the next build
number and a git tag `app-X.Y.Z-buildN`. The app shows its version at the foot of the login
screen and Mon compte; the back-office in its sidebar. Steps for the next build:
**`RELEASING.md`**.

## Docs

| File | What |
|---|---|
| `RUNNING_LOCALLY.md` | Setting up, demo data, tests |
| `RELEASING.md` | Version numbers, building, publishing and checking an APK |
| `RENDER_STAGING.md` · `RENDER_PRODUCTION.md` | Deployment, environment variables, reading a failed deploy |
| `BETA_CHANGES.md` | Every change, numbered, with how to verify it |
| `DESIGN.md` | Dated design decisions and why |
| `SECURITY.md` | Login, permissions, data on the phone, security check report |
| `TODOS.md` | Owner actions and the engineering backlog |
| `CLAUDE.md` | Conventions for working in this code (group scoping, wording, permissions, audit) |
