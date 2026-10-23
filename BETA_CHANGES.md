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
| 13 | Super admin: every right and every figure, in the back-office only | Permissions changed |
| 14 | Finances in two hands (commissaire enters, trésorier validates); back-office for super admins only; group-neutral wording | Permissions changed |
| 15 | MSG, a platform for several groups: groups, memberships, access requests, welcome message, per-group activity types and dress codes | New tables; every group-owned table gets a group |
| 16 | Member status per group (actif, congé, classé, suspendu, archivé) | One column added, filled from the account |

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

## 13. Super admin: everything, in the back-office only

- **The super admin can do and see everything**, finances included (owner, 2026-10-23,
  replacing the design's "sans voir les montants"). `registry.all_cells()` is granted in
  `User.permission_set()`, even alongside a role with locked cells; `accounts.0008` ticks every
  cell for the role so the matrix shows it. Planning changes by a super admin count as
  exceptional (audited, formateurs notified), like the président's.
- **Dashboard**: the Finances panel shows the cash balance, the total owed by members, what is
  paid (validated), what is left to pay, lines waiting for validation and open collections, with
  a link to "Bilan financier".
- **Not in the mobile app**: a super admin account is refused at app login with code
  `backoffice_only` (checked after a correct PIN, so the answer reveals nothing to a stranger;
  audited), and any older app token stops working (`AppJWTAuthentication`). The app explains:
  "Les comptes super admin s'utilisent uniquement sur le back-office". On staging this concerns
  only the two super admin accounts.

**Data.** `accounts.0008_super_admin_everything`. Runs on deploy.

**Verify.** `pytest` (190) and `flutter test` (57).

## 14. Two hands on the money; back-office for super admins only; group-neutral wording

Owner decisions, 2026-10-23. They replace part of §12.

- **The commissaire aux comptes enters, the trésorier validates.** The trésorier collects and
  keeps the money, so he checks that the figures entered match what he holds before validating
  them. `registry.LOCKED`: the commissaire can never validate; the trésorier can never create,
  change or delete. The trésorier also validates the quarterly report. Nobody validates a line
  they entered. Every line now starts "à valider" (no more validation on entry).
- **Only super admins get into the back-office.** It is the platform's administration console;
  the group's officers work in the app. `access.can_enter` checks the super admin role; back-
  office permissions are locked for every other role; a session ends as soon as its holder
  stops being super admin. A back-office password can only be given to a super admin. The
  commissaire and the trésorier download the balance statements from the app.
- **Group-neutral wording**: login help and errors no longer name "le secrétaire général" or
  "l'assise du samedi" ("Demandez au responsable de votre groupe…"); the back-office presents
  itself as the platform's console and shows the group's name from Paramètres ("Groupe",
  "Lieu ou rattachement").

**Data.** `accounts.0009_two_hands_backoffice_super_admin_only` (commissaire: view, create,
change, delete, export; trésorier: view, validate, export; back-office permissions removed from
every role but super admin). Runs on deploy.

**Verify.** `pytest` (189) and `flutter test` (57).

## 15. MSG: one platform, several groups

Owner decisions, 2026-10-23: MSG is the platform's name; one platform serves several groups
(option B); one phone number can belong to several groups; roles are each group's own; the
partner who creates accesses is the super admin; accesses are requested from the app.

- **Groups and memberships.** `core.Group` and `core.Membership` (an account in a group). The
  existing data all becomes the first group's ("Mouvement Garde Suisse"); everyone already there
  is a member of it, except the super admins, who run the platform. Settings are per group, with a
  new **welcome message** shown on Accueil.
- **Scoping.** Every group-owned table carries its group (events, announcements, money,
  planning, roles, notifications, settings…). The app names its group in the `X-Group` header (the
  member's first group by default; a group they're not in is refused with `not_in_group`). The
  back-office has a group switcher under the logo. Default managers filter on the current group,
  so a forgotten filter can't show another group's data (`apps/core/groups.py`).
- **Roles per group.** A new group starts with a copy of the first group's roles and permissions,
  activity types and dress codes. Super admin is a platform role (no group).
- **Access process.** The group leader (whoever may register members: président, secrétaire by
  default) sends "Demander un accès" from the app (name, phone, role, note). The partner sees it in
  back-office → Demandes d'accès and creates the access, or refuses with a reason. A new account
  gets a temporary PIN that the leader sees **once** in the app ("Demandes d'accès"), then it is
  erased (or dropped after 7 days); a number that already has an account just joins the group. The
  member signs in, chooses their own PIN and sees their role. Direct registration in the app is
  retired (`410 use_access_request`).
- **Per-group lists.** Activity types (with "planning" and "présences" switches) and dress codes are
  edited in back-office → Paramètres. The app shows the group's wording (the defaults stay
  translated).
- **Back-office**: Groupes page (create a group with its welcome message, switch), Demandes
  d'accès (with a pending count in the menu), name MSG. **App**: named MSG, group switcher and
  welcome message on Accueil, requests and PIN screen, offline cache and queued writes kept per
  group.

**Data.** `core.0004_groups`, `accounts.0010_roles_per_group`, `members.0001_access_requests`,
`events.0002`/`0003`, `finances.0002`, `planning.0003`, `announcements.0003`. Run on deploy.

**Verify.** `pytest` (201) and `flutter test` (61). Isolation tests: `apps/core/test_groups.py`;
the access process end to end: `apps/members/test_access.py`.

## 16. A member's status is per group

Owner, 2026-10-23: one person can be on leave in one group and active in another.

- `Membership.status` (actif, congé, classé, suspendu, archivé), filled from the account's status by
  `core.0005_membership_status`. Member lists, counts, reminders, collections, the planning pool and
  the balance statement use the status in the current group (`User.objects.members()` annotates it
  as `gstatus`; `user.group_status` for one person). The app shows it as before (`status`).
- Suspending from the back-office suspends in the group being worked on only. A member suspended or
  archived in a group no longer reaches that group from the app; their other groups are unchanged.
  The account-wide status stays for the platform (a fully blocked account).

**Verify.** `pytest` (202): `test_status_is_per_group`.

## 17. Accueil's header, the app colour, header buttons

Owner, 2026-10-23 (screenshots).

- **Accueil header** after the owner's reference: a dark band (a deep shade of the app colour)
  reaching under the status bar, with the avatar (opens Mon compte), a greeting by time of day
  and the first name, the FR/EN switch, an Apparence button and the bell; the member's role as a
  gold chip; a row of gold and clay diamonds. Under 380 dp of width, FR/EN moves next to the chip.
- **App colour.** Each group has one (back-office → Paramètres → Couleur de l’application: nine
  colours or any #RRVVBB; `core.0006_group_color`). Sent in `/api/me/` (`group.color`) and
  `/api/settings/`. A member can pick their own in the app (Apparence, from the gear on Accueil);
  "Couleur du groupe" goes back to the group's. All the app's greens are derived from it.
- **Header buttons** (Finances CSV/PDF, Calendrier +, Membres, Notifications) were drawn in the
  middle of the screen; they are now pinned to the right edge, as round buttons.

**Verify.** `pytest` (`test_group_color_is_set_in_settings`, `/me` colour in
`test_groups.py`); `flutter test test/appearance_test.dart`.

## 18. Edit and delete a group (two super admins)

Owner, 2026-10-23. Back-office → Groupes.

- **Modifier** on each group: name, place, motto, welcome message, app colour. Audited (platform).
- **Supprimer** is a double validation: a super admin asks, with a mandatory reason and the
  group's name typed back. Nothing is deleted yet; a red banner on Groupes and a count in the menu
  show the request. **Another** super admin confirms (typing the name again) within 3 days; then
  the group is **hidden, its data kept** (owner's choice): its members can no longer open it in
  the app, it leaves the group choice, and it is listed under "Groupes supprimés" with a
  **Restaurer** button that brings it back as it was. The asker can't confirm their own request;
  either can cancel it; after 3 days it lapses. The platform's last active group can't be
  deleted. `core.0007_group_deletion`, `core.0008_group_soft_delete`.

**Verify.** `pytest apps/backoffice/test_group_delete.py` (edit, refusals, the two-admin
deletion with money and roles kept, members locked out, restore, cancel, expiry, last group).

## 19. Every member changes their own profile picture

Owner, 2026-10-23.

- **App**: Mon compte → tap the avatar (camera badge) or "Photo de profil": choose from the
  gallery, take a photo (front camera), or remove it. The picture is resized to 1024 px before
  upload and shows at once on Mon compte and in Accueil's header.
- **Server**: `POST /api/me/photo/` (multipart `photo`, JPEG/PNG ≤ 5 MB, content checked) and
  `DELETE /api/me/photo/`; no permission needed, the member's own account only; audited.
  `/api/me/` returns `photo`. Officers with members.profile:change still set others' photos.
- iOS: camera and photo-library usage texts in Info.plist.

**Verify.** `pytest apps/members/tests.py::test_every_member_changes_their_own_photo`;
`flutter test test/my_photo_test.dart`.

## 20. Roles of the day requested in the app

Owner, 2026-10-23: an active member with no role can be given, for one session, the role of
président, censeur, secrétaire, formateur, commissaire aux comptes or trésorier "du jour".

- Roles have a "peut être donné pour une journée" switch (`Role.daily`, `accounts.0011_daily_roles`),
  on for président, censeur du jour, secrétaire général, formateur, commissaire aux comptes and
  trésorier in every group; new groups copy it; the back-office role page toggles it
  ("Autoriser comme rôle du jour").
- **App**: on a member's profile, officers who can propose roles get **Demander un rôle du jour**
  when the member is active and holds no role: pick the role, one date (today or later), a reason.
- **Server**: `POST /api/members/<id>/role-requests/` with `daily: true, day`; refused for a past
  day, a member not active or already holding a role that day, a role not marked daily, or a
  second pending request for the same day. `GET /api/members/requestable-roles/?daily=1`.
- **Back-office**: the request appears in "Demandes de rôle" as "rôle du jour, le …". Approving
  gives the role for that day only (it ends that night) and notifies the member. The separation of
  duties still applies (one person can't be trésorier and commissaire the same day).

**Verify.** `pytest -k "role_of_the_day or daily"`; `flutter test test/modules_test.dart`.
