# Changes, for whoever deploys next

One numbered section per logical change: what and why, where it lives, how to verify it, and
whether it touches real data.

## At a glance

| # | Change | Touches data |
|---|---|---|
| 1 | Backend skeleton, settings split, Docker + Render Blueprint | No |
| 2 | Members, phone + PIN login, JWT | New tables |
| 3 | Roles, permission matrix, fixed rules, audit log | New tables + seeded roles |
| 4 | Back-office: 2FA login, dashboard, users, roles, audit | No |
| 5 | Flutter app: login and role-based tabs | No |
| 6 | Staging database and storage on Supabase | Staging schema created |
| 7 | First beta APK (0.1.0 build 1) | No |
| 8 | Bilingual app (FR/EN) | No |
| 9 | Members, calendar, announcements (API + app); beta build 2 | New tables; staging demo content |

## 1. Backend skeleton

**What/why.** Django 6.1 + DRF, settings split into `base`/`dev`/`prod`, every value with a safe
default. Postgres and Redis everywhere (no SQLite). Sentry with `trace_propagation_targets=[]`,
and the boto3 checksum/SigV4 config for Supabase Storage, both copied from Spekooh's incidents
before they can recur. Docker runtime chosen up front.

**Where.** `backend/config/`, `backend/Dockerfile`, `render.yaml`, `.github/workflows/`.

**Verify.** `cd backend && .venv/bin/python manage.py check` and, with prod settings,
`check --deploy` (CI runs both). After a deploy, `GET /healthz/` → `{"status": "ok"}`.

## 2. Members and PIN login

**What/why.** `accounts.User`, identified by phone (E.164), with a hashed 4-digit PIN for the
app and a separate Django password for the back-office only. Login is two steps:
`POST /api/auth/phone/` (returns the first name for the greeting), then `POST /api/auth/login/`.
3 wrong PINs lock the account 15 minutes. JWT 15 min / 30 days, rotating, blacklisted.

**Where.** `apps/accounts/{models,views,services,phone}.py`.

**Verify.**
```bash
curl -X POST $API/auth/phone/ -H 'Content-Type: application/json' -d '{"phone":"6 77 45 21 08"}'
curl -X POST $API/auth/login/ -H 'Content-Type: application/json' -d '{"phone":"677452108","pin":"1234"}'
```
Three wrong PINs in a row → the third answers 423. Tests: `pytest apps/accounts`.

**Data.** New tables only (migration `accounts.0001`). Rollback: `migrate accounts zero` on an
empty database.

## 3. Roles, permissions and audit

**What/why.** `Role`, `RolePermission` (role × resource × action), dated `RoleAssignment`
(temporary roles expire by date, nothing has to run). The vocabulary and the fixed rules live in
`apps/accounts/registry.py`: the trésorier never validates, trésorier and commissaire can't be
the same person, the super admin never sees finances, at least 2 super admins. Changes go through
`apps/accounts/services.py`, require a reason, and write `core.AuditLog`; refusals are logged too.
`GET /api/me/` returns roles, effective permissions and the tabs the app must show.

**Where.** `apps/accounts/{registry,services,models}.py`, `apps/core/{models,audit}.py`.

**Verify.** `pytest apps/accounts -k "tabs or super_admin or treasurer"`.

**Data.** Migration `accounts.0002_seed_default_roles` creates the 11 default roles from the
design's role table. It only creates missing roles, so re-running never overwrites an admin's
edits. Reverse is a no-op (roles in use are protected).

## 4. Back-office

**What/why.** Server-rendered at `/bo/`, using the design's CSS files unchanged. Login = phone +
password, then a 6-digit SMS code (Twilio Verify), with an optional 30-day trusted-device cookie.
Pages: dashboard (counts, recent sensitive actions, finances masked for the super admin), users
(search, status filter), roles (permission matrix editor, locked cells, mandatory reason),
audit log.

**Where.** `apps/backoffice/`, `backend/static/backoffice/`, `apps/core/sms.py`.

**Verify.** Locally: `seed_demo`, then log in at `/bo/` as `677000001` / `msg-demo-2026!`; the
code is printed in the `runserver` output. On staging the code arrives by SMS. Tests:
`pytest apps/backoffice`.

## 5. Flutter app: login and tabs

**What/why.** Splash (restores the session), phone screen, PIN screen with keypad (submits on the
4th digit; shows the server's message and remaining attempts; keypad disabled when locked),
shell with only the tabs from `/api/me/`. Accueil shows the greeting, roles and sign-out; other
tabs show "Bientôt disponible". One `ApiClient` (base URL from `--dart-define=API_BASE_URL`),
concurrent 401s share one token refresh, offline never signs out.

**Where.** `app/lib/`.

**Verify.** `cd app && flutter test`. On a device against a local backend:
`flutter run --dart-define=API_BASE_URL=http://<your-ip>:8000/api`, log in as `677452108` /
`1234` (Fotso Ingrid, trésorière) → 5 tabs; as `691347702` / `1234` (Essomba Kévin, membre) →
3 tabs.

## 6. Staging database and storage (Supabase)

**What/why.** Staging uses the existing Supabase project "MSGes Project" (eu-west-1) through the
transaction pooler (port 6543). `prod.py` now sets `prepare_threshold=None`: psycopg 3 otherwise
prepares repeated queries server-side, which fails when the pooler hands the next run to another
connection.

**Where.** `config/settings/prod.py`; secrets in gitignored `backend/.env.staging`.

**Verify.** With `.env.staging` loaded and prod settings: `manage.py showmigrations` all `[X]`;
saving a file through `default_storage` returns a URL containing
`X-Amz-Algorithm=AWS4-HMAC-SHA256` that downloads with status 200.

**Data.** Staging schema created and 11 roles seeded. No members yet.

## 7. First beta APK — 0.1.0 (build 1)

**What/why.** Release APK for testers, pointed at staging. Fixes found while building: the
release manifest had no `INTERNET` permission (Flutter adds it to debug/profile only, so the
release app could never have reached the API); app label is now "MSG Gestion"; launcher icon is
the MSG monogram. Release builds are signed with a real upload key when
`app/android/key.properties` exists (git-ignored), else the debug key.

**Where.** `app/android/app/build.gradle.kts`, `app/android/app/src/main/AndroidManifest.xml`,
`app/android/app/src/main/res/mipmap-*/ic_launcher.png`.

**Build.**
`flutter build apk --release --dart-define=API_BASE_URL=https://msg-staging.onrender.com/api --build-number=1`

**Verified (2026-10-20).** `aapt2 dump badging`: package `cm.msgyapoma.msg_gestion`, versionCode 1,
label "MSG Gestion", INTERNET present. Not debuggable. `apksigner`: signer
`CN=MSG Gestion, O=Mouvement Garde Suisse` with SHA-256
`5efeb9ea…f17194`, matching the keystore. `libapp.so` contains
`https://msg-staging.onrender.com/api` and not `10.0.2.2`. APK SHA-256
`4c75324dfdc883c027c780b3c7036a2d9cc5c2b0a5d968f0883dd18576489c89`.

**Hosting.** `~/msg-beta/` (only the APK and a download page) served by
`python3 -m http.server 8790 --bind 127.0.0.1` behind `cloudflared tunnel --protocol http2`.
The link lives only as long as both processes; re-host (don't rebuild) after a restart and
re-check the SHA-256.

## 8. Bilingual app (French / English)

**What/why.** Owner requirement: the app is dual-language. FR/EN switch on the login screen and in
"Mon compte", remembered on the phone (`LocaleController`, shared_preferences); default follows
the phone, French unless the phone is in English. The app sends `Accept-Language`. API errors
carry a stable `code` (+ numbers such as `attempts_left`, `minutes`) so the app words them in the
chosen language; `detail` stays as the French fallback. Seeded role names are translated by slug.
New UI strings go through `app/tool/add_strings.py`, which writes both ARB files at once.

**Verify.** `flutter test` (language switch test); on a phone, switch FR ↔ EN on the login
screen and enter a wrong PIN: the message follows the language.

## 9. Members, calendar, announcements — beta build 2

**What/why.** First real modules, following the design screens.
- **API** (`apps/members`, `apps/events`, `apps/announcements`): member list with counts and
  filters, bureau, profile (minors' phone and parent contact only for
  `members.minor_contacts:view`; a `restricted` list says what was withheld), registration
  (Membre role, audited, temporary PIN returned once until SMS exists); events by date range,
  create/update/delete (audited), roll call (bulk PUT), member absence notice (can't override a
  censor's mark); announcements and convocations (convocation requires an event), pinned first,
  unread flags, read receipts for the author / `announcements.posts:change`.
- **App**: Members (search, chips with counts, bureau, profile, add member), Calendar (month grid
  with dots, agenda, event detail, report absence, roll call, new event), Announcements (filters,
  unread dot + tab badge, compose, convocation event picker, read receipts), new Accueil (next
  meeting, latest announcement) and Mon compte (roles, language, sign-out).
- Fixes found by tests: Django drops `Meta.ordering` from `GROUP BY` queries (feed now ordered
  explicitly); add-member spinner kept spinning behind the PIN dialog.

**Data.** Migrations `events.0001`, `announcements.0001` (new tables; applied on staging).
`manage.py add_demo_content` loads 11 demo events and 3 announcements tagged "[démo]";
re-running replaces them, `--remove` deletes them. Loaded on staging 2026-10-20.

**Build 2.** versionCode 2, same upload key (SHA-256 `5efeb9ea…f17194`), not debuggable,
staging URL in `libapp.so`. APK SHA-256
`750a67a966d2a2b87a26b2710d8cdc813ab6db6a1cec8c54ffda4d85f7c6871c`.

**Verify.** `pytest` (103) and `flutter test` (26).
