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
| 10 | Everything else in the design (except SMS/push delivery); build 3 | New tables |
| 11 | Who makes the lineup; chef de groupe per service; roles of the day; back-office on phones | Roles and permissions changed; one column moved |
| 12 | Finance rights (commissaire: all; trésorier: read); members' balance statement in the app and back-office | Permissions changed |

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

## 10. The rest of the design — build 3

**What.** Every screen in `design/` is now functional, except what needs an outside account
(SMS through Twilio, push notifications to the phone).
- **PIN**: change own PIN; forced change after a temporary PIN; secretary resets (temporary PIN
  shown once); "Code oublié ?" by SMS (works as soon as Twilio is configured; until then it says
  to ask the secretary). Trivial PINs (1111, 1234…) refused.
- **Finances**: cash book with who entered / who validated, never one's own entry, validated lines
  locked; solidarity collections in thirds with bulk payments; fines and "Mes contributions";
  quarterly report blocked while lines are pending; PDF exports; registration fee at signup.
- **Planning**: week grid (2–12 guards → posts × Pariso/Yapoma), alerts (short-staffed, double
  service, on leave), fair candidates, group fill, publish + notify, "Mes services"
  (confirm / swap / absence), requests inbox (colleague accepts → chef approves; replacement for
  absences), alb-washing rotation with 12-month fairness.
- **Announcements**: PDF/JPEG/PNG attachments (type checked on content, ≤ 10 MB), read receipts,
  "Relancer les non-lecteurs".
- **Notifications** (in-app): duties, convocations/announcements, validated payments, new members,
  day-before and 2-hours-before reminders (`send_reminders`, `send_soon_reminders`, Render cron
  jobs in production, `/internal/tasks/` on staging), per-member preferences.
- **Offline**: cached reads + sync line + offline banner; entries, payments, roll call, absence,
  confirmations and "read" queued and sent when back (idempotent on the server).
- **Members**: photos, call/SMS buttons, last-4-assises attendance, "Proposer un rôle".
- **Back-office**: account security (sessions you can close, **backup codes** — usable for login
  without SMS), user detail (assign with mandate end, revoke with reason, reset PIN, suspend /
  reactivate, give back-office access with a temporary password + backup codes, groups), new
  user, spreadsheet import (.xlsx / CSV, error lines excluded, temporary PINs as CSV), bulk
  actions, filters, assignments with mandate alerts + renew, role requests, role management
  (new / rename / duplicate / archive), settings (amounts used by the app), CSV exports.

**Data.** New tables: finances, planning, notifications, settings, role requests, backup codes,
back-office sessions, attachments. Applied with `migrate` (Render runs it on start).

**Verify.** `pytest` (166) and `flutter test` (52).

## 11. Lineup rules, chef de groupe per service, roles of the day, mobile back-office

**What/why.** Owner rules (2026-10-23):
- **The lineup is made by the formateur or the formateur adjoint** (new bureau role), and on
  exceptional occasions by the président or vice-président. `registry.LINEUP_ROLES` locks
  create/change/validate/delete on `calendar.planning` for every other role, so the back-office
  can't grant it. When the président or vice-président changes or publishes the lineup, it is
  written to the audit log as "à titre exceptionnel", and the formateurs are notified when
  they publish. Swap and absence decisions go to the formateurs too.
- **The chef de groupe is designated for each service**, among that service's guards, whenever
  the lineup is made (`Service.chef`, `PUT /api/planning/services/<id>/chef/`). It is no
  longer a standing role: the "Chef de groupe" role is archived and its holders'
  assignments ended (audited). The chef sees "Vous êtes chef de groupe" in Mes services and
  is told in the duty notification; absences go to the formateurs and to that day's chef.
  Freeing the chef's post or approving their swap removes the designation.
- **Roles of the day**: the super admin can give anyone any role except super admin
  (censeur du jour or a bureau role) for a single day: from Affectations → "Rôle du jour",
  or "Rôle du jour" in the assign dialog on a member's page. It ends on its own at midnight,
  the member is notified, and it isn't counted as a mandate (no expiry alert, not in the
  app's bureau list).
- **Back-office on phones**: under 820px the sidebar opens as a drawer from a menu button,
  and spacing is tightened for 360px screens. Checked at 375px: login, code, dashboard,
  users, member page + dialogs, roles, assignments, audit, settings; nothing scrolls
  sideways except the tables, which scroll inside their card.

**Data.** `accounts.0006_lineup_roles` (adds Formateur adjoint; removes lineup rights from
non-lineup roles; archives Chef de groupe and ends its assignments, with audit rows) and
`planning.0002_service_chef` (moves `chef` from the group to the service; existing group
chefs are not carried over). Both run on deploy.

**Verify.** `pytest` (181) and `flutter test` (54). On staging after deploy, run
`add_role_testers` to create the formateur adjoint tester.

## 12. Finance rights and the members' balance statement (bilan)

- **The commissaire aux comptes holds every finance right** (cash book, solidarity
  collections, quarterly report: view, create, change, validate, delete, export). A line they
  enter is validated at once under their name ("Opération saisie et validée" in the audit
  log). A line entered by someone else (e.g. a registration fee taken at signup) still waits
  for their validation, and nobody validates a pending line they entered themselves.
- **The trésorier only reads and downloads**: `registry.LOCKED` locks create, change, validate
  and delete on every finance resource for that role, so the back-office matrix can't hand
  them back.
- **Bilan général and bilan individuel**: per member, what they owe (fines, solidarity shares,
  registration), what they paid (validated), what waits for validation, and what is left.
  - API: `GET /api/finances/statement/`, `/statement/<id>/`, and `/pdf/` on each (needs
    `finances.cashbook` view / export). Every download is audited.
  - App: Finances → summary icon (bilan général PDF); a member's profile → "Bilan financier
    (PDF)".
  - Back-office: new "Bilan financier" page (totals, search, "Avec un reste à payer" filter,
    PDF and CSV of the whole list, a page per member with its own PDF). Reading the cash book
    now opens the back-office: a finance-only account lands on this page and sees only it,
    plus its own security page. The super admin still never sees an amount.

**Data.** `accounts.0007_finance_rights` (commissaire gets every finance right; trésorier
keeps view + export). Runs on deploy. A trésorier or commissaire needs a back-office password
(super admin: member page → "Accès back-office") to use the back-office page.

**Verify.** `pytest` (189) and `flutter test` (56). Back-office checked at 1280px and 375px.
