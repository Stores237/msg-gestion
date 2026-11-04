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

## 21. Fix: back-office login answered 500 once there were several groups

Staging, 2026-10-23. The login side panel showed "the" group's name, looked up before any group
is chosen; with a second group on the platform (even a deleted one) that lookup refuses on purpose
(`NoGroupContext`), so `/bo/connexion/` failed for everyone, phone or desktop. The panel now says
"Plateforme MSG", and the `group_settings` tag returns nothing before a group is chosen.

**Verify.** `pytest apps/backoffice/test_group_delete.py::test_login_pages_work_with_several_groups`
(fails on the old code with the same error as staging).

## 22. App lock: PIN on reopening, fingerprint or face

Owner, 2026-10-23: the PIN wasn't asked when the app was reopened; biometrics weren't set up.

- **Lock screen** (MSG logo, "Entrez votre code PIN", keypad): when the app opens on a saved
  session, and when it comes back after 2 minutes or more in the background. Works offline (the
  PIN is checked against a salted hash kept in the phone's secure storage). 5 wrong PINs close
  the session; "Se connecter autrement" signs out to the number screen.
- **Fingerprint or face**: Mon compte → "Déverrouiller avec l’empreinte ou le visage" (shown
  greyed when the phone has none enrolled; asks for it once when turned on). Then the lock
  screen prompts at once; the fingerprint key on the keypad retries; the PIN always works.
- After installing this version, members who were already signed in sign in once more (their
  PIN had never been saved on the phone).
- Android: `MainActivity` is a `FlutterFragmentActivity`, launch theme AppCompat,
  `USE_BIOMETRIC`. iOS: `NSFaceIDUsageDescription`.

**Verify.** `flutter test test/lock_test.dart` (reopen, wrong PIN count, 5 wrong → signed out,
old session → sign in again, fingerprint auto-unlock and retry key, background → locked, the
switch in Mon compte). On a phone: sign in, close the app from recent apps, reopen → PIN.

## 23. Bureau posts and plans with their role shown; Aide / À propos; storage errors

Owner, 2026-10-26.

- **Every bureau role** (all groups) can now post announcements and convocations and create,
  change and delete calendar events (`accounts.0012_bureau_announcements_calendar`; adjustable in
  the back-office matrix). Authors still edit only their own announcements unless they manage them.
- **The author's role is shown**: saved when posting (`Announcement.author_role`,
  `Event.created_by_role`; `announcements.0004`, `events.0004`), shown as a pill next to the name
  on announcements and as "Ajouté par … [rôle]" on an event. A role of the day reads "Président du
  jour". Older posts show the author's current role.
- **Aide / À propos** in Mon compte (owner's reference): FAQ (in the app, FR/EN), Aide et
  assistance (call), Assistance WhatsApp, Nous contacter (e-mail); site web, politique de
  confidentialité, conditions d'utilisation. Contacts and texts are the partner's, edited in the
  back-office → **Plateforme · aide** (`core.PlatformSettings`, `core.0009`; `GET /api/platform/`).
  The two texts start as drafts to be reviewed. A contact not filled in shows "Pas encore
  disponible". Log out is now red, as in the reference. The row icons use the app colour
  (owner, 2026-10-26), so they follow the group's or the member's choice.
- **Profile picture upload** failed on staging because the Supabase storage refuses every request
  (403: the S3 access key or its region is no longer valid). Owner action: new S3 access key.
  The API now answers `503 storage_unavailable` with a clear message (app: "le stockage est
  indisponible") instead of a 500, for every upload. Resolved: the owner set a new S3 key on
  Render (2026-10-27).

**Verify.** `pytest -k "bureau or plain_member or platform or storage"`;
`flutter test test/help_and_roles_test.dart`.

## 24. Back-office staff: support, IT helpdesk, integration ops

Owner, 2026-10-26: the back-office gets staff teams, each with access by role and level.

- **Six platform roles** (`accounts.0013_backoffice_staff`): Support · agent / responsable,
  IT helpdesk · agent / responsable, Intégrations · agent / responsable. Back-office only, across
  every group (group switcher), never in the app.
- **The back-office is split into areas** so each team gets only its part: comptes et membres,
  demandes d'accès, rôles et affectations, groupes, paramètres des groupes, plateforme · aide,
  sécurité et sessions, intégrations et services, journal. Every page and menu entry checks its
  own area. Default access:
  - Support agent: sees accounts, access requests, roles, groups, settings, platform, journal.
    Responsable: also resets PINs and suspends, creates accounts, approves access requests,
    edits group settings and the help page, exports.
  - IT agent: sees accounts, groups, the team and its sessions, services, journal. Responsable:
    also resets PINs, closes staff sessions and issues new backup codes, tests services, exports.
  - Integration agent: sees services, platform, group settings, groups, journal. Responsable:
    also tests services, edits the help page, exports accounts and journal.
  The super admin adjusts all of this in Rôles et permissions.
- **Fixed rules** (`registry.STAFF_LOCKED`): staff never change roles and permissions, never
  create, change or delete groups, never touch finances or anything outside the back-office, and
  never act on a super admin's account. Refusals are in the journal.
- **Équipe du back-office** page: the super admin adds a staff member (name, number without an app
  account, team and level, reason) and gets a temporary password and 10 backup codes shown once
  (the backup codes replace the SMS step until Twilio is live); changes level; removes access.
  The IT helpdesk closes a colleague's sessions and issues new backup codes.
- **Intégrations et services** page: storage, SMS, push, e-mail, error tracking and API docs,
  configured or pending, with a live "Tester maintenant" for the file storage. No secret shown.

**Verify.** `pytest apps/backoffice/test_staff.py`.

## 25. Authors edit and delete their own announcements and events

Owner, 2026-10-26.

- **Server**: `PATCH`/`DELETE /api/announcements/<id>/` and `/api/events/<id>/` are allowed to the
  author, whatever their role's change/delete rights; people with those rights still can for
  anyone's. Others get `403 author_only`. Each item tells the app `can_edit` / `can_delete`.
  Pinning stays with whoever manages announcements. Deleting an announcement removes its
  attachments; every change is in the journal.
- **App**: "Modifier · Supprimer" under the announcement and the event when allowed; the
  composer and the event form open pre-filled; deleting asks first.

**Verify.** `pytest -k author_edits`; `flutter test test/owner_edit_test.dart`.

## 26. Conditions of use checkbox at login

Owner, 2026-10-26.

- **App**: the phone-number screen has "J’ai lu et j’accepte les conditions d’utilisation"
  (EN: "I have read and accept the terms of use"); the link opens the text. Continue without the
  box says "Cochez la case pour continuer." The version shown is sent with the PIN (and with a
  PIN reset by SMS).
- **Server**: login and PIN reset answer `428 terms_required` until the member accepts the
  current version; acceptance is saved on the account and in the journal. `GET /api/auth/terms/`
  gives the text before login. The back-office member page shows "Conditions d’utilisation :
  version N acceptée le …".
- **Back-office → Plateforme · aide**: changing the terms text raises the version (shown under
  the field); every member accepts the new text at their next login.
- Migrations `accounts.0014_terms_acceptance`, `core.0010_terms_acceptance`. Builds before 15
  can't tick the box, so after this deploy members need build 15 to sign in.

**Verify.** On the phone: Continue without ticking → the red line; tick → PIN → in. Back-office
→ the member's page shows the version and date. Change the terms text in Plateforme · aide →
the next login asks again. `pytest apps/accounts/test_terms.py`;
`flutter test test/terms_login_test.dart`.

## 27. Security check fixes

2026-10-26; full report in SECURITY.md "Security check — 2026-10-26".

- Rate limits and audit addresses use the real client address (`CF-Connecting-IP` behind
  Cloudflare), so a forged `X-Forwarded-For` no longer gets around them.
- The phone's offline copy is erased on sign-out (asks first if changes are unsent), after 5
  wrong PINs, and when another account signs in. Android backup is off.
- Pillow 13.0.0 (37 published vulnerabilities in 12.3.0).
- `/api/schema/` and `/api/docs/` need a back-office session; CORS headers only on `/api/`.
- Back-office → Intégrations shows "Adresse du visiteur": the address the limits key on.

**Verify.** After the deploy, Intégrations → "Adresse du visiteur" shows your own public address
(green). Opening `/api/docs/` signed out → refused. In the app, sign out with a change waiting
offline → the warning. `pytest apps/core/test_security.py`;
`flutter test test/offline_owner_test.dart`.

## 28. Event types, chef de groupe and the report

Owner, 2026-10-27. There was no design for these screens: they reuse the event form's fields,
the event detail's cards and chips, the member picker and the announcement composer.

- **Autre**: choosing "Autre" asks "Précisez le type" (required); the event then shows the
  author's words instead of "Autre".
- **Messe intérieure / extérieure**: a Messe says which, with two chips in the form (required).
  "Service extérieur" is retired: its events became Messe · Extérieur, existing masses are
  Intérieur. On cards and on the event, Extérieur has an amber chip and an amber date box.
  Back-office → Paramètres → Types d’activités has a new "Int./Ext." switch per type.
- **Chef de groupe**: chosen when the event is created (required for every type except Réunion;
  back-office switch "Chef" per type), among active members. They are notified at once, with the
  report deadline. The planning's chef is now the event's chef (`planning.Service.chef` moved to
  `events.Event.chef`); the formateur can still change it from the planning.
- **Report**: on the event, "Rapport du chef de groupe" shows the deadline (24 h after the end)
  and the status (Attendu / Remis / En retard / Non remis). The chef writes it in the app and/or
  attaches a PDF (≤ 10 MB) once the event has started; until the deadline they can send it
  again. After the deadline a first report is still accepted, marked "en retard", and can't be
  changed. It goes to the formateur, with the formateur adjoint, secrétaire général, censeur
  général and vice-censeur in copy (notifications; they read it on the event). The chef gets a
  reminder when the event ends; if 24 h pass with no report, the formateur, the copies and the
  chef are told (the `send_soon_reminders` job, every 30 min).
- New role **Vice-censeur** in every group (the censeur général's rights). New permission
  "Rapports des chefs de groupe" (read), given to those five roles.
- Migrations: `events.0005`, `events.0006`, `planning.0004`, `accounts.0015`, `accounts.0016`,
  `core.0011`. Builds before 16 can't create events for types that need a chef (the server now
  requires one).

**Verify.** Create a Messe without choosing intérieur/extérieur or a chef → both are asked.
Create one as Extérieur with a chef → the chef gets "Chef de groupe" with the deadline; the card
shows the amber Extérieur chip. After the event, the chef opens it → "Rédiger le rapport" →
text and/or PDF → the formateur gets "Rapport : …", the four copies "Copie · Rapport : …", and
"Lire le rapport" shows it. `pytest apps/events/test_reports.py`;
`flutter test test/event_chef_report_test.dart`.

## 29. Startup that shows where it stops

2026-10-27. The event update's first deploy hung before its migrations and never opened its
port; Render kept the previous version. The container now starts with `start.sh`, which prints
a timestamped marker before each step. The database connection gives up after 10 s instead of
waiting, and `migrate` skips the system checks (they run in the tests), saving ~20 s of boot.

**Verify.** Render → Logs after a deploy: `[start …] collectstatic`, `migrate` (with `Applying
events.0005…` the first time), `ensure_superuser`, `gunicorn on port 10000`, then "Your service
is live". `curl https://msg-staging.onrender.com/api/events/1/report/` answers 401, not 404.

## 30. Report locked once opened; roll call lists the lineup with each post

Owner, 2026-10-27.

- **Report locked when the bureau opens it**: the first time a reader of reports (formateur,
  formateur adjoint, secrétaire général, censeur général, vice-censeur; not the chef) opens a
  report, it is locked: the chef can no longer change it (`409 report_read`), is notified "Rapport
  lu", and the event shows "Ouvert par … : ne peut plus être modifié". The report shows who
  opened it and when; the composer says so up front. Migration `events.0007_report_read`.
- **Roll call for an event with a lineup**: only the guards lined up (and the chef de groupe)
  are listed, in lineup order with the chef first, each with a chip for what they served as
  ("Chef de groupe", "Première centrale · Pariso"); the event type line (Messe · Intérieur /
  Extérieur) heads the list. Marks for anyone else are ignored. Events without a lineup (assise,
  réunion…) still list every member.
- **Ma présence**: on an event with a lineup, the member sees their post, or "Vous n’êtes pas de
  service pour cet événement" with no absence button (the server refuses it: `not_on_duty`).

**Verify.** Open a report as the secrétaire général → the chef's "Modifier le rapport" is gone
and the event shows the lock line. Take the roll call of a Messe with a lineup → only the lined-up
guards, each with their post. `pytest apps/events/test_reports.py`;
`flutter test test/event_chef_report_test.dart`.

## 31. Design features that were missing (planning, leave, event details, drafts)

Owner, 2026-10-27, from the design screenshots. Group-neutral throughout: every list and text
below belongs to the group (Paramètres, memberships), none names one group's habits.

- **Drag and drop in the planning**: hold a name and drag it to another cell ("Maintenir pour
  glisser ; la case cible s’éclaire"). A free cell takes the guard; a filled cell of the same
  service swaps the two; another service checks it like a new assignment (double service →
  "Quand même"). One transaction (`PUT /api/planning/assignments/<id>/move/`). Guards of a
  published plan are told their new post.
- **Leave with an end date, per group**: back-office → member → "Mettre en congé" (optional
  "jusqu’au", reason journalled) and "Fin du congé". Shown as "En congé jusqu’au …" on the
  candidates, the planning alerts and the member's profile; a guard on leave shows red in the
  grid (design: "Rouge : conflit (double service, congé)"). The evening job makes the member
  active again after the date and tells them. Migration `core.0012_membership_leave_until`.
- **Fix (multi-group)**: the planning read the account-wide status instead of the status in the
  group being planned, so leave in one group blocked service in another.
- **Swaps validated by the event's chef de groupe** (design: "Validation : …, chef de groupe"):
  the chef is told "Échange à valider", sees it in Demandes (also reachable from Mes services) and
  can approve or fill an absence, for their own events only; the lineup makers still can for all.
  The swap sheet says who validates and shows each colleague's services this month.
- **Planning**: "Brouillon" next to "Publier et notifier"; the group sheet shows who is on leave
  and what happens; the chef is changed from the planning with the member picker (any active
  member — the chef belongs to the event since §28).
- **Event details**: a second line under the place ("Quartier, ville"), and under the dress
  what it means in the group — each group writes it in back-office → Paramètres → Tenues →
  Détail. Migration `events.0008_dress_description_place_detail`.
- **Announcement draft**: "Brouillon" in the composer keeps title and text on the phone (one per
  group) and brings them back next time, until sent.

**Verify.** Planning: hold a name, drag it to a free cell → it moves; onto a filled cell of the
same service → they swap. Back-office: put a member on leave until a date → the planning shows
"En congé jusqu’au …". Paramètres → Tenues → fill a Détail → it shows under the dress on the
event. `pytest apps/planning/test_design_gaps.py`; `flutter test test/planning_test.dart
test/design_details_test.dart`.

## 32. Version and developer signature (from build 18)

Owner, 2026-10-28: "Propulsé par STORES" with the S mark, and a visible version.

- **App**: login screen and the bottom of Mon compte show "Propulsé par [S] STORES" and
  "Version 0.1.0 (18)", read from the build (`package_info_plus`).
- **Back-office**: the sidebar (under the account) and the login page show the signature and
  "MSG 0.1.0 · <commit>".
- **Server**: `/healthz/` answers `{"status": "ok", "version": "0.1.0", "commit": "<short
  sha>"}` (Render's `RENDER_GIT_COMMIT`), so a deploy that didn't start is visible at once.
- **Versioning**: the version lives in `app/pubspec.yaml` (`0.1.0+18`) and
  `backend/config/version.py` (`0.1.0`), checked equal by a test; builds no longer pass
  `--build-number`. Process in `RELEASING.md`.

**Verify.** App: login screen bottom → "Version 0.1.0 (18)". Back-office sidebar → "MSG 0.1.0 ·
…". `curl …/healthz/` → version and commit. `pytest apps/core/test_version.py`;
`flutter test test/powered_by_test.dart`.

## 33. Stockage et données; back-office sidebar footer (build 19)

Owner, 2026-10-28 (after the phone's own "Storage and data" screen).

- **Mon compte → Stockage et données**:
  - *Gérer le stockage*: what the app keeps on the phone (offline data, unsent changes, images in
    memory), with "Vider" for the offline data (reloaded from the server; unsent changes kept)
    and the images.
  - *Utilisation du réseau*: what the app sent and received through its API, since a date;
    tap to reset.
  - *Économiser les données mobiles*: on mobile data, no automatic member photos and photos sent
    in standard quality.
  - *Qualité d’envoi des photos*: standard (≤ 1024 px) or high (≤ 2048 px); profile photos use
    it.
  - *Téléchargement automatique*: member photos on mobile data / on Wi-Fi (off shows the
    initials). Attachments still download only when opened. Proxy and roaming left out (a phone
    setting / not detectable).
  - Settings and counters are kept on the phone (`DataSettings`); the network type comes from
    `connectivity_plus`.
- **Back-office**: the sidebar's menu now scrolls; the account, log-out and the "Propulsé par
  STORES · MSG x.y.z · commit" footer stay pinned at the bottom (they were cut off on windows
  under ~900 px tall). On the login page the signature sits under "Plateforme MSG", aligned.

**Verify.** App: Mon compte → Stockage et données; turn on the saver → "Sur données mobiles" says
"Désactivé : économie de données". Back-office on a short window: log-out and signature visible.
`flutter test test/storage_data_test.dart`.

## 34. Photos in announcements; "Expiré" on past events and convocations (build 20)

Owner, 2026-10-28.

- **"Ajouter une photo"** in the announcement composer (gallery or camera). Every photo has
  one frame: **landscape 4:3**. After picking, "Cadrer la photo" shows it under the frame; move
  and zoom it, only what is inside is kept. The app resizes it (quality from Stockage et
  données: 1024×768 standard, 2048×1536 high) and compresses it to **2 MB at most**;
  **4 photos** per announcement.
- The server checks the same rules on every image attached to an announcement (format 4:3 ±2 %,
  320–2048 px, ≤ 2 MB, 4 per announcement: `photo_frame`, `photo_size`, `photo_too_large`,
  `too_many_photos`). "Joindre un fichier" is now for PDFs (10 MB); pictures go through the
  frame.
- Photos show **in the announcement**: the first on the feed card (with "+N" when there are
  more), all of them in the announcement, tap for full screen. With automatic photos off for
  the network (Stockage et données), they show "Afficher la photo" until tapped.
- **"Expiré"** (grey chip) on an event once it is over (its end, or its start without an end),
  wherever the event shows: calendar, Accueil, event page, report, roll call. And on a
  convocation once its date has passed (the date line turns grey).

**Verify.** New announcement → Ajouter une photo → pick a portrait photo → the frame is
landscape; move it, Utiliser cette photo → send → the card shows the photo. A past event in the
calendar shows EXPIRÉ. `pytest apps/announcements/test_photos.py`;
`flutter test test/announcement_photo_test.dart test/design_details_test.dart`.

## 35. Back-office: a more modern, smoother shell

Owner, 2026-10-28. Same design tokens; `static/backoffice/bo-modern.css` (loaded last) and
`shell.html`. Server-only: live after a Render deploy.

- **Sidebar**: sections (Membres · Groupe · Plateforme, each only when the account has something
  in it); hover state, a green bar on the current page (`aria-current`), visible keyboard focus;
  counts as pills; the group switcher as a card. **Icon rail**: the button next to the logo folds
  the sidebar to icons (labels as tooltips, still read by screen readers); remembered on this
  computer; on the rail, the group card unfolds the menu.
- **"Aller à…"**: a search button in the top bar, or **Ctrl/⌘ K** or **/**, finds any page the
  account can open as you type (accents ignored), arrows + Enter.
- **Messages as toasts** (top right; bottom on phones): confirmations fade after 5 s, errors stay
  until closed.
- **Busy buttons**: a clicked button shows a spinner and the form can't be sent twice (the
  button's value is still sent); reset when coming back with the browser's back button.
- **Smoothness**: the top bar stays in view with a soft shadow once the page scrolls; table rows
  highlight under the pointer; pages fade into each other (browsers that support it); the phone
  drawer slides in. Everything honours "reduce motion".
- **Phones**: search beside the title, action buttons wrap instead of overflowing.

**Verify.** Back-office: Ctrl K → type "rol" → Enter opens Rôles. Fold the menu with the button
by the logo, reload: it stays folded. Save a setting: the toast fades. `pytest
apps/backoffice/test_shell.py`.

## 36. Back-office sidebar stays in place

Owner, 2026-10-28: "the side bar has to be static". The sidebar and the top bar were meant to stay
put while a page scrolls, but the page frame used `overflow:hidden`, which made it its own
scroll container, so both scrolled away with the page. The frame now uses `overflow:clip`
(clips the same, scrolls nothing): measured scrolled 700 px down, both stay at the top. The top
bar is now nearly opaque so scrolled rows don't show behind the title.

**Verify.** Back-office → Utilisateurs (a long list) → scroll down: the menu and the title bar
don't move.

## 37. Back-office account menu; change your own password

Owner, 2026-10-28 (reference screenshot: an account menu at the foot of the sidebar).

- The account row (avatar, name, role, ↕) opens a menu above it — beside it on the folded rail:
  **theme** (Clair · Sombre · Comme l’appareil, kept in this browser), **Voir le site** (the
  website from Plateforme · aide, when set), **Changer le mot de passe**, **Sécurité du compte**
  (sessions, backup codes) and **Se déconnecter** in red. Escape or a click outside closes it.
- **Changer le mot de passe** (`/bo/mot-de-passe/`): current password, new one twice; the
  platform's password rules (10 characters, not common, not only digits). This browser stays
  signed in; every other session and every trusted computer of the account is signed out. Both
  the change and a wrong current password go to the audit log.

**Verify.** Back-office → click your name at the bottom of the menu → Sombre: the page turns
dark and stays dark after a reload. Changer le mot de passe → wrong current one → refused; a good
one → "Mot de passe modifié", still signed in. `pytest apps/backoffice/test_shell.py`.

## 38. Edit a person's details in the back-office

Owner, 2026-10-28 ("why is it that we couldn't edit user infos at back office"). The user page
showed the identity read-only, as in the design; there was no way to correct a name or a number.

- **Identité → Modifier** opens a form: last name, first names, birth date, member since,
  diaspora and city, parent or guardian (name, relation, phone), photo (replace, JPEG/PNG ≤ 5 MB,
  or remove). Same rules as creating a member: names required, no date in the future, a minor
  needs a parent's phone. A refused form reopens with what was typed and changes nothing (a bad
  photo doesn't save the rest either). The audit log gets "Identité modifiée" with the old and
  new value of each field changed.
- **Téléphone → ✎ (Changer le numéro)**, apart because the number is the login: valid, unique
  across the platform, mandatory reason. The person's phones are signed out (refresh tokens
  blacklisted; the 15-minute access token runs out) and they sign in with the new number and the
  same PIN. For a back-office account, its other back-office sessions end too. Journaled with old
  number, new number and reason; a number already in use is refused and journaled.
- Who: "Utilisateurs › Modifier" for members (super admin, support responsable); a super admin
  or back-office staff account only by a super admin. Rules in `accounts/services.py`
  (`update_identity`, `change_phone`).

**Verify.** Back-office → Utilisateurs → a member → Identité → Modifier → fix the name →
Enregistrer: the page shows it, Journal d'audit shows "Identité modifiée" with before/after.
✎ next to the phone → another member's number → refused; a new number with a reason → the
member's app asks to sign in again, with the new number. `pytest apps/backoffice/test_identity.py`.

## 39. Choose who is notified of an announcement or convocation (build 21)

Owner, 2026-10-29: "select among members who should be notified, like a tag; the announcement or
convocation could still be seen by everyone".

- **Rédiger → Notifier** (was a fixed "Tous les membres" row) opens **Qui notifier ?**: the
  group's active and on-leave members, search by name (accents ignored), tick any number,
  **Valider (n)**; **Tout le monde** clears the choice. The names chosen show under the form as
  chips (✕ removes one). Also when editing; members added then are notified, the others aren't
  notified twice.
- With members chosen, only they get the notification ("Annonce pour vous" / "Convocation pour
  vous"); without, everyone does, as before. **Everyone still sees it** in the feed.
- On the card: **POUR VOUS** for a tagged reader, and "@ Pour : names" (3 names + n on the feed,
  all on the announcement). New feed filter **Pour moi**. Read receipts mark the tagged members;
  "Relancer les non-lecteurs" then reminds only the tagged ones who haven't read it.
- Server: `Announcement.tagged` (migration announcements 0005); `tagged` ids on POST/PATCH,
  checked against the group's audience; `tagged_members` and `for_me` in the response;
  `?filter=for_me`; `GET /api/announcements/recipients/` for whoever may post (no need for the
  member directory). Audit: "notifiés" and "mentionnés" counts.

**Verify.** As a secretary: new announcement → Notifier → tick 2 members → Publier. Those two get
"Annonce pour vous"; a third member gets no notification but sees it in Annonces, with "Pour :"
and no POUR VOUS. `pytest apps/announcements/test_tagged.py`,
`flutter test test/announcement_tagged_test.dart`.

## 40. Photos scroll vertically, notifications open the announcement, three latest on Accueil (build 22)

Owner, 2026-10-29, with screenshots: "images have to be vertical scrolling"; "when clicking on a
notification (announcement) he is not redirected to the announcement, and 'announce pour vous'
should be a small notice, not the title"; "latest announcement … at least 3 visible".

- **Photos.** Tapping a photo (feed card with "+N", or the announcement) opens all of the
  announcement's photos, one under the other, starting at the one tapped ("3 photos" on top);
  tap one to zoom it.
- **Notifications.** An announcement or convocation notification now opens it (it did nothing).
  For a tagged member the notification carries the announcement's **own title** and text, with a
  small amber "@ Pour vous" under the title (was the title "Annonce pour vous"). Server: target
  `{"type": "announcement", "id", "for_me": true}`.
- **Accueil → Dernières annonces**: the three newest, newest first, pinned or not (pinned ones
  used to win), as short rows (title, unread dot, "@ Pour vous", kind · date · author).

Notifications sent before this deploy keep their old "Annonce pour vous" title; they open the
announcement all the same.

**Verify.** Tag a member in a new announcement with 3 photos. On that member's phone: the
notification shows the title and "@ Pour vous"; tapping it opens the announcement; tapping a
photo shows the three stacked. Accueil lists the 3 newest. `pytest apps/announcements/test_tagged.py`,
`flutter test test/announcement_open_test.dart`.

## 41. Photos slide side by side by themselves; pinned on top of Accueil (build 23)

Owner, 2026-10-29: "make the announcement picture view a horizontal scrolling view with auto
scrolling"; "an announcement that has been pinned should stay at the top of the latest
announcements".

- **Photos** (feed card and announcement): one 4:3 frame holding all the photos side by side.
  Swipe left/right; they also move on by themselves every 4 s, back to the first after the last.
  "2/3" in the corner and dots underneath. A finger on the photos pauses it; the phone's
  "remove animations" setting turns the automatic sliding off. Replaces "+N" on the feed and the
  stack on the announcement.
- **Full screen** (tap a photo): the photos side by side too, opened at the one tapped, "2 / 3" on
  top; pinch to zoom (swiping waits until it's zoomed out). Replaces the vertical list of build 22.
- **Accueil → Dernières annonces**: pinned announcements first (pin icon), then the three newest
  others.

**Verify.** An announcement with 3 photos: on the feed the photos change every 4 s and loop; swipe
works; hold a finger and they stop. Tap one → full screen at that photo, swipe to the others.
Pin an old announcement → it heads Accueil's list, with three recent ones under it.
`flutter test test/announcement_photo_test.dart test/announcement_open_test.dart`.

## 42. Roles have a duration; only the super admin's is without end (back-office)

Owner, 2026-10-29, with a screenshot of a Formateur held "sans fin": "the infinite role has to be
that of the 2 admins, and the admin should be able to define the duration for a role".

- Every role but **Super admin** (and **Membre**, the membership itself: if it ran out the person
  would lose the app) has a **duration in months**. **Rôles et permissions → [rôle] → Durée**
  (1–120 months, reason required, audited "Durée du rôle modifiée"); the chip next to the name
  shows "Durée N mois" or "Sans fin". **Nouveau rôle** asks for it (12 by default).
- Assigning a role fills its end date from that duration (the date can still be changed in the
  dialog); a role without a duration can't be given ("Refus · durée du rôle" in the journal).
  A new duration applies to the next assignments; current ones keep their end date (renew from
  Affectations).
- Migration accounts 0017: bureau roles keep their 24-month mandate; the other roles (formateur,
  temporary roles, back-office staff…) get 12 months; open-ended assignments of those roles get
  their end (start + duration, or a full term from today if that is already past). Back-office
  staff roles are included: renew them before they end.

**Verify.** Back-office → Rôles et permissions → Formateur: "Durée 24 mois" (or 12), button
**Durée**; set 6 with a reason → the chip says 6. Super admin: "Sans fin", no Durée button. A
user page: the Formateur role now has an end date. `pytest apps/backoffice/test_role_duration.py`.

## 43. Download photos and PDFs; what was seen stays viewable offline (app, build 24)

Owner, 2026-10-29: "User should be able to download a picture seen on an announcement, a pdf
report, and when offline view what has already been downloaded or even what he had already viewed".

- **Photos**: full-screen viewer → **Télécharger** (download icon): saved to the phone's gallery
  (Pictures/MSG) and kept in **Mon compte → Téléchargements**.
- **PDFs** (quarterly report, cash book, balance statements, a member's statement, the chef's event
  report, announcement attachments): tapping downloads the file, copies it to the phone's
  Download/MSG folder (once per version), keeps it in Téléchargements and opens it in the phone's
  PDF viewer. If none is installed the app says so; the file stays in Téléchargements.
- **Offline**: every photo shown (announcements, member photos) is kept on the phone (up to
  150 MB, oldest dropped first), so it shows without network, even with data saver on. A PDF
  opened before opens again from its kept copy ("Hors ligne : copie du …"). An announcement opened
  from a notification falls back to the copy in a feed already loaded.
- **Mon compte → Téléchargements**: the list (name, size, date, "sur le téléphone"), tap to open,
  ⋮ → Enregistrer sur le téléphone / Supprimer. **Stockage et données** shows Téléchargements and
  "Photos vues" (with Vider).
- Sign-out (and the other cases that erase the offline copy) also erases the kept photos and
  downloads; copies already put in the phone's Pictures/Download folders stay (the member put them
  there).
- Android: MediaStore on Android 10+ (no permission); on 7–9 the storage permission is asked the
  first time. Native code in `MainActivity.kt` (channel `msg/files`), FileProvider limited to the
  app's `msg_files/downloads/`.

**Verify.** Open an announcement with photos → tap a photo → download icon → "Photo enregistrée
dans la galerie"; it's in the phone's gallery (album MSG). Finances → PDF icon → the PDF opens and
is in Download/MSG. Turn on airplane mode: the announcement photos still show, the same PDF opens
again ("Hors ligne : copie du …"), Mon compte → Téléchargements lists both.
`flutter test test/downloads_test.dart`.

## 44. App colour: any colour and a gradient (back-office and app)

Owner, 2026-10-29, with a screenshot of Paramètres → Couleur de l'application: "the color palette
couldn't be changed whereas it has to be", "also add the possibility to form gradient color".

- **Back-office** (Paramètres and Groupes → Modifier): one picker for both pages: the swatches and
  **Autre…** (any colour) set one hidden field each, so what is shown selected is what is saved
  (the old radio + named-on-input custom field could disagree). **Dégradé avec une deuxième
  couleur** opens a second row; a live **Aperçu** shows the result. The Groupes list dot shows the
  gradient.
- Server: `Settings.color2` (empty = plain), migration core 0013, sent in `/api/me/` as
  `group.color2`.
- **App**: Accueil's header goes from the first colour to the second (darkened less than a plain
  header so the change shows). **Apparence**: **Autre couleur…** (hue and shade sliders, kept dark
  enough for white text), a **Dégradé** switch with a second row of colours, and a preview. The
  member's choice still wins on their phone; "Couleur du groupe" returns to the group's, gradient
  included.

**Verify.** Back-office → Paramètres: click a swatch → preview changes, Enregistrer → it stays
selected after reload; tick Dégradé, pick a second colour, save. In the app (after reopening it),
Accueil's header shows the gradient. Apparence → Autre couleur… → move Teinte → Choisir.
`pytest apps/backoffice/test_admin.py -k color`, `flutter test test/appearance_test.dart`.

## 45. One phone at a time

Owner, 2026-10-30: "restrict account usage for multi device, that is only one login per device";
when asked, the owner chose "the new phone wins".

- Signing in on a phone (PIN, or "Code oublié ?") signs the account out of any other phone. The
  other phone is told at its next request (opening the app, pulling to refresh, any tap that
  reaches the server): it goes back to the login screen with "Votre compte a été ouvert sur un
  autre téléphone, celui-ci a donc été déconnecté. Si ce n'est pas vous, reconnectez-vous et
  changez votre code PIN." Its offline copy, photos seen and downloads are erased, as on sign-out.
- A lost or broken phone never locks anyone out: signing in on the new one is enough.
- Server: `User.app_session` (migration accounts 0018), the `sid` claim in the tokens, `401
  other_device` from every endpoint and from `/api/auth/refresh/`; journal "Connexion sur un autre
  téléphone". Phones signed in before the deploy keep working until the member signs in elsewhere.

**Verify.** Sign in with the same account on two phones (or the emulator and a phone): the first
one, on its next action, shows the login screen with the message. `pytest
apps/accounts/test_one_phone.py`, `flutter test test/one_phone_test.dart`.

## 46. Planning: published lineups go down and can be reused; the date matters

Owner, 2026-10-30: "after published the lineup have to go down, given possible to create a new
planning but also reusing the published one; the date is very important: a planning whose due date
is passed [can't] be published (should notify the user)" — the owner chose "can't publish, the user
is told".

- **Planning · semaine**: drafts on top ("Brouillons à publier"), published lineups below
  ("Publiés"). A new lineup is still made from "Prévoir le service".
- **Réutiliser** on a published lineup: pick an upcoming event that has no lineup yet (next 90
  days); the same size, team and posts are copied as a **draft** (nobody is notified) and the view
  jumps to that week to check and publish. Guards who can't serve that day (on leave, no longer
  active, already on duty) are left out and named in the message.
- **Date passed**: a draft whose event has started shows "Date passée"; "Publier et notifier"
  publishes only the drafts still to come, and when only past ones are left the button reads "Date
  passée" with a notice saying to reuse them for an upcoming event (server: `400 date_passed`). A
  new lineup can't be made for a past event either.

**Verify.** Calendrier → Planning: publish a week → its columns move under "Publiés" with
**Réutiliser** → pick next Sunday's mass → snack "Planning repris pour …", the next week shows it as
a draft. Go back to a past week with an unpublished lineup: "Date passée", nothing to publish.
`pytest apps/planning/test_reuse.py`, `flutter test test/planning_reuse_test.dart`.

## 47. Finances: edit before validation, members required and ticked, "Autre"

Owner, 2026-10-30: "the trésorier should be able to edit an operation that hasn't yet been
validated; member selection should be a must, with check boxes and an option to check all; on the
categories add an option Autre with a description". Choices made with the owner: the edited line is
marked, the two steps remain (after the trésorier's validation the commissaire finalises it); a
member is required on Entrées only; several ticked members make one line each; "Autre" for Entrées
only (Sorties already have their description).

- **Edit (trésorier)**: tapping a line "À valider" offers **Modifier** next to Valider. Amount,
  date, description, category, member and direction can be corrected (for a payment towards a share
  or a fine, only amount, date and description). The line shows **Modifié** and "modifié par …";
  every change is journaled with before/after ("Opération modifiée avant validation") and the
  commissaire who entered it is notified. Editing is part of the trésorier's *validate* right: the
  two-hands rule still never gives him *change*.
- **Two steps**: validating an edited line puts it **À finaliser**; it doesn't count in the balance
  yet. The commissaire (Accueil "N opérations à finaliser", or tapping the line) **Finalise** it, or
  **Renvoie** it to the trésorier with a reason (back to À valider). Whoever edited it can't
  finalise it. An unedited line is still validated in one step.
- **Members**: an Entrée needs at least one member. Nouvelle opération → Membres opens a list with
  check boxes and **Tout cocher** (on the names the search shows). Several members → one line each,
  same amount, with "N membres × montant = total" shown before saving; sent as one request, safe to
  resend offline. Sorties keep an optional single member.
- **Autre**: a new Entrée category; its description is required (shown in the cash book,
  statements and PDFs).
- **Solidarité** collection screen: **Tout cocher** ticks everyone still owing, with their next
  instalment.
- Server: `Entry.Status.TO_CONFIRM`, `edited_by/at`, `confirmed_by/at`, `Category.OTHER`
  (migration finances 0003), `PATCH /api/finances/entries/<id>/`, `POST …/confirm/`
  (`{accept}` or `{accept: false, reason}`), `members` on `POST /api/finances/entries/`.

**Verify.** As the commissaire: Nouvelle opération → Entrée, no member → "Choisissez au moins un
membre"; Membres → Tout cocher → OK → "N membres × …" → save: N lines. Catégorie Autre without a
description → refused. As the trésorier: tap one of them → Modifier → change the amount → the line
shows Modifié → Valider → À finaliser. As the commissaire: tap it → Finaliser (or Renvoyer with a
reason). `pytest apps/finances/test_corrections.py`, `flutter test
test/finance_corrections_test.dart`.

## 48. Cash book: Modifier on the line, grouping, a cleaner card

Owner, 2026-10-30 (with a screenshot of the cash book): "the trésorier can't still edit; cash-book
contributions should be grouped by day (who contributed on a date), by contribution type, by
validity, and others; correctly render the card". The server already accepted the edit (build 26,
staging at 7a09cf8, replayed with the app's exact request); the edit was only reachable through the
dialog that opens when the line is tapped, so it wasn't found.

- **Actions on the line**: for the trésorier, each line "À valider" shows **Modifier** (opens the
  form directly) and **Valider** buttons; for the commissaire, a line "À finaliser" shows
  **Finaliser**. Tapping the line still opens the dialog.
- **Grouping**: "Grouper par" Jour (default, newest day first: who paid on that date) · Type
  (category) · Statut (pas encore envoyé, à valider, à finaliser, validé) · Membre (A→Z, "Sans
  membre" last). Each group shows its name, the number of operations and the net total; tapping
  the header folds it. The choice and folded groups stay while the app is open.
- **Card**: the member (or the description when there is none) and the amount on the first line;
  the category below, followed by the description only when it differs, so "Contributions de
  solidarité · Contributions de solidarité" no longer appears; then who entered, edited, validated,
  the badges and the buttons. Long names wrap to two lines; the amount shrinks to fit at large text.
- How to verify: sign in as the trésorier → Finances: a pending line shows Modifier and Valider;
  Modifier opens "Modifier l'opération". Switch Grouper par between Jour, Type, Statut, Membre; tap
  a header to fold it. App only, no server change.

## 49. Sign-in: shared carrier addresses and a safer session refresh

Owner, 2026-10-30: "don't know why I can't login, check that and fix". Checked on staging (commit
600f351): health, number check, conditions, PIN sign-in, /me and refresh all answer correctly for a
verified tester. Two causes found that stop members signing in or keep signing them out:

- **Limits per address too low.** In Cameroon many phones share one carrier address (CGNAT), and
  the limits were per address: 30 sign-ins/h, 30 number checks/h, 120 session refreshes/h for
  everyone behind that address. Raised to 120 sign-ins and number checks, 600 conditions, 1200
  refreshes per hour. Wrong PINs stay limited per account (3 → locked 15 min).
- **The app signed out on any refused refresh.** A "too many requests" (429) or the server
  restarting after a deploy (502/503) ended the session like a revoked token. Now only a refused
  token (401/400, including "opened on another phone") signs out; the others keep the session and
  the screen shows the error. A refresh that fails after the member has signed in again no longer
  wipes the new session.
- How to verify: deploy, install build 28, sign in on several phones on the same mobile network
  one after the other; all get in. Restart the service on Render while the app is open: it shows
  an error and stays signed in.

## 50. Builds 27 and 28 withdrawn: built without the server address

Owner, 2026-10-30: "I have tried many different accounts and the message is still the same: can't
connect, check your network". Builds 27 and 28 were built with a bare `flutter build apk`, so they
pointed at the emulator's local server (`http://10.0.2.2:8000/api`) instead of staging: no phone
could reach anything. Builds 25 and 26 were correct. Build 29 is the same code as build 28, built
with the staging address. New `app/tool/build_apk.sh` builds with the address and refuses to
finish if it isn't inside the APK; RELEASING.md now uses it. The two broken APKs were removed
from the download folder.

- How to verify: install build 29 over 27/28 and sign in; the login works on mobile data and Wi-Fi.

## 51. Finances: the trésorier and the commissaire agree on each operation; validate several at once

Owner, 2026-10-30: "select multiple operations and validate them at once (long press); it's only
the trésorier who validates whereas it has to be mutual work between the trésorier and the
auditor: they align on each operation before recording it". Chosen with the owner: either one
enters, the other approves. The trésorier collects and keeps the money, so he records what he
receives and the commissaire audits it; when the commissaire records one, the trésorier's approval
confirms he holds the money.

- **Both enter, the other approves.** Both roles now have the cash-book and solidarity rights
  (migration accounts 0019; `registry.LOCKED` no longer splits them; one person still can't hold
  both). A line counts only when someone other than who entered it, or last changed it, approves
  it. Entering notifies the other side ("Opération à approuver"; one notice for several members).
  Approving notifies who entered/changed it ("Opération approuvée") and the member.
- **Corrections**: either one can correct a line not yet counted; the correction is its author's
  agreement, so the other one approves it ("Opération modifiée · à approuver"). The "À finaliser"
  step is no longer created; lines already in it keep Finaliser / Renvoyer.
- **On the line**: the other one sees Modifier and Valider; its author sees "En attente de l'autre"
  and Modifier. Accueil "N opérations à valider" counts only lines waiting for you. A line is
  deleted only by who entered it (the other corrects it instead).
- **Several at once**: long press a line to pick it (check circles), tap others, or "Tout
  sélectionner" (every line you may approve); "Valider (N)" asks once with the total, then reports
  how many were validated and how many were left (e.g. your own). Server:
  `POST /api/finances/entries/validate/ {"ids": [...]}` → `{validated, skipped}`, each line under
  the same rule, refusals audited.
- How to verify: deploy, then as the trésorier enter an Entrée → it shows "En attente de l'autre";
  as the commissaire it shows Valider. Enter three as the commissaire; as the trésorier long press
  one, Tout sélectionner, Valider (3).

## 52. Expense requests: member → domain lead → commissaire → trésorier with proof

Owner, 2026-10-30: "for any expense an expense request has to be submitted; it is validated by the
concerned board lead only, not the vice (paper for a training exam asked by the vice-formateur or a
member is validated by the formateur), but they can also tag another coordinator with higher
responsibility; then the auditor approves and passes it to the treasurer, who provides the amount
and shows a proof with a screenshot of the transaction as a comment in the thread". Choices made
with the owner: the lead or any tagged coordinator decides (first one); the proof records the
Sortie, counted at once; the amount paid is at most the approved one, otherwise the member cancels
(kept on record) and asks again with the exact amount.

- **Domains** (each group's own, back-office → Paramètres → Domaines de dépense): a name and the
  role that approves first. Seeded per group: Formation (formateur), Discipline (censeur général),
  Secrétariat (secrétaire général), Fonctionnement général (président). A new group copies them.
- **App**: Accueil → Demandes de dépense (every member): À traiter / Mes demandes / Toutes (finance
  team). New request: domain (shows who approves), what for, amount, details, optional tagged
  coordinators. The request shows its four steps, the buttons the viewer may use, and the thread
  (comments with a photo or PDF; each step written in it).
- **Rules (server)**: the first step belongs to the holders of the domain's lead role and the
  tagged; nobody decides on their own request (a lead asking for himself must tag someone). The
  commissaire (`finances.expenses` validate) approves next, not if he asked or decided before. The
  trésorier (`finances.expenses` change) pays 1 … approved amount with a required screenshot (JPEG,
  PNG or PDF, 10 MB); that creates the Sortie (Dépenses, member = requester) validated in the
  commissaire's name and posts the proof in the thread. Refusing and cancelling need a reason.
  Every step notifies who's next and the requester; refusals of a step are audited.
- Server: `ExpenseDomain`, `ExpenseRequest`, `ExpenseMessage` (migrations finances 0004, 0005;
  accounts 0021 gives the commissaire view+validate and the trésorier view+change),
  `/api/finances/expense-domains/`, `/api/finances/expenses/` (?box=todo|mine|all),
  `…/<id>/decide|review|cancel|pay|messages/`.
- How to verify: as a member, Accueil → Demandes de dépense → Nouvelle demande (Formation, 5 000).
  As the formateur: À traiter → Approuver. As the commissaire: Approuver. As the trésorier: Payer et
  joindre la preuve (4 800 + a screenshot) → the Sortie is in the cash book, the proof in the thread.

## 53. Finance code: a second code to open Finances

Owner, 2026-10-30: "add another pass verification to access the finance page"; chosen: a separate
finance code (not the PIN again).

- Back-office → Paramètres → Sécurité des finances → **Code finances obligatoire** (per group, off
  by default).
- When on, opening Finances asks a 4-digit **code finances**, different from the PIN, each
  person's own. The first time, the member chooses it and confirms with the PIN; "Code finances
  oublié ?" resets it the same way. A right code opens Finances for 5 minutes; it closes again
  when the app locks or the member signs out.
- Server: hashed (`User.finance_code`), `POST /api/auth/finance-code/` {pin, code} (wrong PINs
  count like a login), `POST /api/auth/finance-code/check/` (3 misses lock it 15 min, audited);
  /me gives `group.finance_code_required` and `finance_code_set`. Offline, the phone checks against
  the last code the server accepted on it (salted hash, like the app lock).
- How to verify: turn it on; open Finances → choose the code with the PIN; leave the app and come
  back after the lock: the code is asked again; three wrong codes → locked.

## 54. Check of the day's features, and what was missing

Owner, 2026-10-30: "I am not seeing [Domaines de dépense, Code finances] in the back office and
multi select is not applied; verify all the functionalities we implemented today and determine
what's lacking". Staging was on build 30 (commit 4174009): build 31's back-office settings need
the deploy. Every feature of the day was then run end to end against a local server, as each role
over HTTP (one phone at a time, finance corrections, mutual approval, bulk validation, expense
requests from request to proof, finance code): 42 checks pass, and the server's real answers were
parsed by the app's models. Found and fixed:

- **Multi-select was hidden**: only a long press, and only on lines the viewer may approve (none
  for a line you entered yourself). The cash book now has a **Sélectionner** button next to the
  hint; picking starts with nothing ticked and "Valider (0)" stays off.
- **French counts of zero read as one** ("1 sélectionnée" for none, "1 photo" for 0): Flutter
  puts 0 with 1 in French. Every French plural (24) now has its own zero form.
- **The finance code could be bypassed from Accueil**, which showed the cash balance. When the
  group requires the code, Accueil shows the balance only after the code was given.
- **The back-office had no expense requests**: Finances → Demandes de dépense (filter by step,
  counts) and each request's page (steps, who and when, thread, proof file), read only.
- **Expense requests from Finances**: the finance team gets a "Demandes de dépense · N à traiter"
  row above the cash book; the Accueil row shows the same count.
- **A Sortie paid on a request** says so in the cash book ("Payée sur la demande n° …") and opens
  the request with its proof (`expense` on each cash-book line).
- Back-office Finances footnote updated to the mutual rule.

## 55. Expense requests: attach a photo or a PDF on the form

Owner, 2026-10-30: "add the possibility to add an attachment on the expense request form like a
picture or pdf".

- New request → **Pièces jointes** → "Joindre une photo ou un PDF" (quote, invoice, photo of the
  item): JPEG, PNG or PDF, 10 MB each, 3 at most; each can be removed before sending.
- They are sent with the request and appear first in its thread ("Pièce jointe à la demande"),
  where the lead, the commissaire, the trésorier and the back-office see and open them. Joining
  them doesn't send a second notice (`initial` on `POST …/messages/`, the requester's own files
  while the request waits for the lead).
- If a file fails to upload, the request is still sent and the member is told to add it again
  from the thread.
- How to verify: Accueil → Demandes de dépense → Nouvelle demande → join a photo and a PDF →
  Envoyer: both are in the request's Échanges.

## 56. Finance code that applies at once, Finances ⚙, and "Approbation des dépenses"

Owner, 2026-10-30: "Domaines de dépense and Code finances do nothing; I don't see the use of the
domaines de dépense, the name is weird; on the finance page add a settings button where the user
can change the code and set it on or off".

- **The switch applied only at the next app start**: the app read the group's settings once.
  Opening Finances now asks the server again (a short wait), so "Exiger le code finances pour
  tous" counts the next time anyone opens Finances. Offline, the last known settings apply.
- **Finances → ⚙ Réglages des finances** (everyone with Finances): "Demander mon code finances"
  turns the code on for one's own account even when the group doesn't require it (choosing the
  code first if needed); turning it off asks the current code. When the group requires it, the
  switch is on and locked ("Exigé par votre groupe"). "Changer mon code finances" (with the PIN,
  also when forgotten). Server: `User.finance_code_on` (migration accounts 0022),
  `POST /api/auth/finance-code/switch/` {on, code}, `finance_code_on` in /me; audited.
- **Back-office wording**: Sécurité des finances → "Exiger le code finances pour tous", with what
  happens when it's on or off. "Domaines de dépense" is now **Approbation des dépenses**: an
  explanation (the types offered on the app's expense request form, and the role that approves
  each first, e.g. Formation → Formateur), columns "Type de dépense" / "Approuvé d'abord par".
  In the app the form says "Type de dépense".
- How to verify: back-office → Paramètres → tick "Exiger le code finances pour tous" → in the
  app, open Finances (no restart): the code is asked. Untick it; Finances → ⚙ → turn "Demander
  mon code finances" on: asked again next time; turning it off asks the code.

## 57. Huddle: the app's name and logo; each group's own, like Slack

Owner, 2026-11-02: "the main app is Huddle with this logo; groups choose their name and logo,
visible in the app, like Slack; keep the in-app logo but the main app logo and name are Huddle".
Chosen with the owner: the président (and the super admin in the back-office) changes the group's
name and logo; several groups → a pick screen after signing in; opening and sign-in screens show
Huddle only; signature "Huddle · Propulsé par STORES".

- **Huddle everywhere outside a group**: phone icon (redrawn as a vector from the owner's image:
  `design/brand/` — mark, icon, Android adaptive foreground, wordmark), app name "Huddle"
  (Android label, iOS display name), the Android opening screen, the app's opening, sign-in and
  lock screens, the signature, the download page, and the back-office (sidebar, sign-in page,
  page titles, "Plateforme Huddle"). On a dark background the mark's bar turns white. Downloads now
  go to Pictures/Huddle and Download/Huddle. Internal names stayed in build 35; build 36 renamed the app's ID
  (§58).
- **Each group's identity, like a Slack workspace**: a logo (JPEG/PNG, cropped to a 512 px square
  on the server) and a sigle; without a logo, the sigle (or the name's initials) on the group's
  colour, so the Garde Suisse shows "MSG" until a logo is set. Shown on top of Accueil (logo and
  name), in the group list and on the pick screen.
- **Who changes it**: the président in the app (Accueil → the group's name → "Nom et logo du
  groupe": logo from the gallery or camera, remove, name, sigle; new right `group.profile` change,
  migration accounts 0024, editable per role in the back-office), the super admin in back-office →
  Paramètres (logo upload or remove, Sigle). Every change is journaled.
- **Signing in**: someone in several groups and none chosen yet sees "Choisissez votre groupe"
  (Huddle mark, each group's logo and name); one group goes straight in; the choice is remembered.
  Accueil → the group's name switches group.
- Server: `core.Group.short_name`, `logo` (migration core 0015), `initials`; /me `group` and
  `groups` carry name, initials, sigle, logo and colours; `GET/PATCH /api/group/`,
  `POST/DELETE /api/group/logo/`.
- How to verify: install over the current app → the icon and name are Huddle; open → Huddle, then
  Accueil shows the group's sigle and name. As the président: tap the group's name → Nom et logo
  du groupe → pick a logo → it shows on Accueil. Back-office → Paramètres → upload a logo.

## 58. Huddle's own app ID (build 36)

The owner saw the MSG icon and name when sharing the app with Xender (2026-11-02) and asked for
the project's name to change too. The build 35 file was already "Huddle" with the Huddle icon
(`aapt2 dump badging`); Xender showed the older copy installed on the phone, and the app's ID
was still `cm.msgyapoma.msg_gestion`.

- Android application ID and namespace `cm.stores.huddle` (Kotlin package moved), iOS bundle ID
  `cm.stores.huddle`, Flutter project `huddle` (imports `package:huddle/…`).
- **Android sees a new app**: build 36 installs beside the old MSG app instead of over it.
  Each tester installs it, signs in again (phone number + PIN), and uninstalls the old "MSG"
  or "Huddle" app with the old ID. Nothing is lost: the data is on the server; only this phone's
  downloads and offline copy start empty. Same release key.
- Server addresses (msg-staging…), the repo and on-device storage keys keep their names.
- How to verify: `aapt2 dump badging huddle-0.1.0-build36.apk` → `package: name='cm.stores.huddle'`,
  label `Huddle`. On a phone: the app's details (long press → App info) show Huddle; share it
  with Xender → Huddle icon and name.

## 59. Build 37: the owner's list of 2026-11-02

1. **Tagging on an expense request**: the list shows each person's roles under the name
   (coordinators first; the search finds roles too), and the request shows "J. Mballa
   (Formateur)" for the people tagged.
2. **Hide the balance**: an eye beside the balance in Finances hides it (•••••) on this phone,
   on Finances and Accueil, until tapped again.
3. **Know what you download**: the bilan général, the livre de caisse, the quarterly report and a
   member's relevé first say what the PDF contains and where it goes, then download on
   "Télécharger" (Annuler downloads nothing).
4. **Notifications**: cash-book and low-balance notices open Finances, dues notices open Accueil
   (Mes contributions), planning notices open the Calendar, a role of the day opens Mon compte,
   absence alerts open the member's profile, FAQ answers open the FAQ. Before, these opened
   nothing.
5. **Ended events** (end time, or start + the group's default length): no more editing,
   deleting, announcing an absence or changing the lineup (`event_ended`, 409); the roll call
   stays open. The edit buttons disappear in the app.
6. **FAQ**: Aide → Questions fréquentes shows the group's own questions, then the common ones
   (the built-in six plus those the platform adds). Members propose a question with its answer
   ("Proposer une question"); back-office → Questions fréquentes lists the suggestions to correct
   and publish (for the group or for all groups) or decline with a reason; the author is told.
7. **Recovery code**: back-office → a person → "Code de récupération" shows an 8-digit code once,
   valid 24 h, one use. In the app: "Code oublié ?" → "J'ai un code de récupération" → the code
   and a new PIN. The SMS message now points to it.
8. **Group settings** (back-office → Paramètres; 0 or empty = off):
   - Cotisations et caisse: currency (on every amount, PDF and back-office), monthly dues and
     their day (the evening job adds the month's due for each active member, once, and tells
     them), low-balance alert (trésorier and commissaire told when a validated expense takes
     the balance under it).
   - Règles des membres: probation days ("À l'essai" badge), longest leave (back-office refuses
     longer), absences in 90 days before an alert (member and roll-call keepers told once),
     months without presence before "Inactif".
   - Calendrier: default event length (decides when an event without an end is over), reminder
     delay ("N heures avant"), report deadline for the chef de groupe.
   - Langue et contacts: default language (the app's until the member picks one), group phone,
     e-mail, link and rules, shown in Mon compte → Aide → Mon groupe.
   Left for later: per-group time zone, fees as an editable list.
- Server: migrations core 0016, accounts 0025, finances 0006; `/api/faq/`,
  `/api/faq/suggestions/`; /me `group.currency` and `group.language`; `/api/settings/` carries the
  new values. PDFs now say "Huddle · <group>".
- How to verify: back-office → Paramètres → set Monnaie "EUR" → amounts in the app show EUR.
  Back-office → a member → Code de récupération → in the app "Code oublié ?" → "J'ai un code de
  récupération" → code + new PIN signs in. Open a past event → no Modifier; Appel still works.
  Finances → eye → balance hidden on Finances and Accueil. Finances → PDF → the dialog explains it.

## 60. Build 38: a period for the finance exports

Owner (2026-11-03), after build 37's download window: add a period choice, in the app and the
back-office.

- **App**: the download window of the bilan général, the livre de caisse and a member's relevé
  now has "Période": Tout, Ce mois, Mois dernier, Cette année, Choisir… (a date range); the line
  under it says which days. The quarterly report keeps its quarter. A PDF for a period is its own
  file (the period is in its name) and its own offline copy.
- **Back-office**: Finances and a member's page get a "Période" bar (same quick choices, or two
  dates + Appliquer). The figures on the page, the member links and every export (Bilan général
  PDF, CSV, member PDF and the new **Livre de caisse (PDF)**) follow it; file names carry the
  dates.
- What a period means: debts created and payments dated within it; the cash book lists the
  operations dated within it, with the validated balance at its start and end. The PDF says
  "Période : du … au …". Wrong dates: `bad_period` (app) or a message and the whole history
  (back-office). Each export's journal entry records the period.
- Server: `?from=YYYY-MM-DD&to=YYYY-MM-DD` on `/api/finances/statement/` (+ `/pdf/`),
  `/api/finances/statement/<id>/` (+ `/pdf/`), `/api/finances/entries/pdf/`;
  `/bo/finances/livre-de-caisse.pdf`. No migration.
- How to verify: app → Finances → PDF icon → "Ce mois" → Télécharger → the PDF says "Période :
  du 01/… au …". Back-office → Finances → "Mois dernier" → the totals change → Livre de caisse
  (PDF) shows the balance at the start and end of last month.

## 61. Build 39: networks of groups (phase 1, the tree)

Owner (2026-11-03): the Garde Suisse groups of several parishes form a zone paroissiale, the zones
a diocese, "similar to the government system". Agreed with the owner: an upper level is an
**umbrella group** (the parish groups keep existing under it); the **back-office** creates
networks and upper levels; an umbrella **only informs** the groups under it; four levels are
enough.

- **Back-office → Réseaux de groupes** (new, `backoffice.groups`): create a network and name its
  levels (e.g. Paroisse · Zone paroissiale · Diocèse · National); place each group in a network at
  a level; for a group of level 2+, **Code d’invitation** (8 characters, `ABCD-EFGH`, valid 14
  days, single use; cancel with ×); **Détacher** a group (reason). The tree shows each umbrella
  with the groups attached under it.
- **App → Accueil → the group's name → Réseau** (everyone; the line now opens the sheet for every
  member): the network and the group's level, the groups above it (nearest first) and the groups
  attached to it. The président (`group.profile`, now "Nom, logo et rattachement du groupe"):
  **Rejoindre avec un code** (shows who invites, then "Rattacher"), **Se détacher de …** (reason),
  and in an umbrella group **Inviter un groupe** (code to copy, pending codes to cancel).
- Rules: a group joins only a group of a higher level in the same network (a group outside any
  network joins it); one parent at a time; no loops; a level change can't pass its parent or its
  children; a group with links can't change network. Both présidents get a "Réseau" notification
  and every change is in both groups' journal; refused codes are journaled too. Code lookups are
  limited to 60 an hour per address.
- Server: `core.Network`, `Group.network/level/parent/attached_at`, `core.GroupInvitation`
  (migrations core 0017, accounts 0026); `apps/core/network.py`; `/api/network/`,
  `/api/network/invitations/` (GET `?code=` preview, POST new, DELETE `?code=`),
  `/api/network/join/`, `/api/network/leave/`; `/api/me/` groups carry `level_name` and `parent`.
- Not yet (next phases): what each group shares with its network, announcements and events that
  reach the groups below, links between groups, money between levels.
- How to verify: back-office → Réseaux de groupes → Nouveau réseau → place the MGS group at level
  1 and a new "Zone" group at level 2 → Code d’invitation. In the app, as the MGS président:
  Accueil → group name → Réseau → Rejoindre avec un code → the zone shows under "Rattaché à";
  the zone's président gets a notification. "Se détacher" with a reason undoes it.

## 62. Build 40: networks, phase 2 — what each group shares

Owner (2026-11-03): groups "share information base on what they allow to share".

- **App → Réseau → Ce que nous partageons** (attached groups): kind by kind, what the groups
  above may see — Membres, Finances, Calendrier (Rien · Résumé · Détail), Annonces (Rien ·
  Détail), Présences et rapports (Rien · Résumé · Détail). Nothing is shared until the président
  chooses; members see the choice, read-only. Summary / detail:
  - Membres: how many (by status) / + names and roles.
  - Finances: validated balance, the year's income and spending / + the last 30 validated lines.
  - Calendrier: events in the next 30 days (count) / + dates and places.
  - Annonces: the last 10 announcements (not convocations).
  - Présences: attendance rate over 3 months / + present-absent-excused per event, report in.
  Never shared: phone numbers, PINs, minors' contacts, attachments, personal statements.
- **Upper group**: Réseau lists each attached group with what it shares and a total ("42
  membres, d’après 1 groupe sur 2 qui partage ses membres"); tapping a group opens what it
  shares. Each part is read only by those whose role in the upper group covers it (finances →
  `finances.cashbook` view, members → `members.profile` view, calendar → `calendar.events`,
  announcements → `announcements.posts`, reports → `calendar.reports`); otherwise "Partagé, mais
  votre rôle… ne couvre pas cette partie". Only groups below can be opened.
- Each change is journaled in the group and its parent's présidents are told what is now shared.
  Back-office → Réseaux de groupes shows a "Partage vers le haut" column.
- Server: `core.GroupShare` (migration core 0018), `apps/core/sharing.py`;
  `/api/network/sharing/` (GET, PUT), `/api/network/groups/<id>/`; `/api/network/` gains
  `totals`, `sharing` and each child's `shares`.
- How to verify: attach a parish to a zone (build 39), then as the parish président Réseau → Ce
  que nous partageons → Membres: Détail, Finances: Résumé → Enregistrer. As the zone's
  président, Réseau → the parish → names and roles, and the balance.

## 63. Build 41: networks, phase 3 — announcements and events sent down

Owner (2026-11-03): the groups of a network "communicate with each other"; an umbrella informs.

- **Announcements**: a group with groups attached below gets "Aussi pour les groupes rattachés"
  in the composer (announcements for everyone; not convocations nor tagged ones). The members of
  every group below (all levels) get it in their Annonces, marked "De la part de Zone Nord ·
  Zone paroissiale" with the zone's logo, and a notification "Annonce de Zone Nord". They read it
  and it counts as read; they can't edit or delete it. The author's read counter includes them.
- **Events**: the event form gets the same switch. The event shows in the calendars (and
  Accueil) of every group below, marked with its origin; notification "Événement de Zone Nord".
  There it is read-only: no "Prévenir une absence", no roll call, no report (those stay in the
  zone). Detaching a group removes the zone's posts from its lists.
- Names of activity types and dress codes come from the sending group.
- Server: `Announcement.cascade`, `Event.cascade` (migrations announcements 0006, events 0009),
  `apps/core/network.py` `visible`, `origin`, `send_down`; list, detail and mark-read include
  what comes from above; `from_group` in both payloads; `/api/me/` group gains `below`.
- Not yet: reminders the evening before for events sent down; joint planning (next).
- How to verify: zone président → Annonces → Nouvelle → "Aussi pour les groupes rattachés" →
  Publier; a parish member sees it with "De la part de …". Same with an event in Calendrier.

## 64. Build 42: networks, phase 4 — joint planning

Owner (2026-11-03): joint duty across the parishes of a zone, without the zone running them.

- On an event a group sent down, that group's planning officers (`calendar.planning` change) get
  **Personnes demandées aux groupes**: for each group attached directly below, − / + the number
  of people wanted, then "Envoyer les demandes". Each group's planning officers are notified
  ("Zone Nord demande 6 personnes", with the date and the note). 0 cancels a request.
- In the parish, the event (from above) shows "Zone Nord demande 6 personnes · 2 désignée(s) sur
  6". Its planning officer opens it → **Désigner les personnes** (the usual member picker, with
  roles; active members of this group only). The people named are notified ("Vous êtes
  désigné(e)") and see "Vous êtes désigné(e)" on the event; people removed are told; the zone's
  planners get "GS Yapoma a désigné 6/6".
- The zone sees, per group, the names or "En attente des noms". It never picks a parish's
  members itself. Nothing changes once the event is over.
- Server: `events.EventContingent` (migration events 0010), `apps/events/contingents.py`;
  `/api/events/<id>/contingents/` (GET, PUT `requests`), `/api/events/<id>/contingent/` (GET, PUT
  `members`); the event payload gains `contingent`.
- How to verify: zone → an event sent down → Personnes demandées aux groupes → + on a parish →
  Envoyer. Parish planning officer → the event → Désigner → pick two → the zone sees the names.

## 65. Build 43: networks, phase 5 — neighbours and twinning

Owner (2026-11-03): groups "communicate with each other", sharing "what they allow". Asked for a
proposal for links outside the tree; proposed and built: neighbours + twinning.

- **Neighbours**: groups attached to the same group above (the parishes of one zone) see each
  other in Réseau → Groupes voisins, with what each shares; tapping one opens it.
- **Twinning** ("jumelage"), any two groups, any network or none: one président → Réseau →
  **Jumeler** (an 8-character code, 14 days, single use); the other → **Accepter un jumelage** →
  sees who → "Jumeler". Both présidents are told. Either side ends it (× on the row, with a
  reason); the back-office lists twinnings (Réseaux de groupes → Jumelages) and can end one.
- **Sharing is set per audience**: Réseau → Ce que nous partageons now has one row each for the
  groups above, the neighbours and the twinned groups (only those that exist), each with the same
  Rien / Résumé / Détail choices; nothing is shared until chosen. The readers' roles still apply.
  A change notifies the groups concerned.
- An attach code can't be used to twin and the reverse ("wrong_kind").
- Server: `core.GroupLink`, `GroupInvitation.kind`, audiences `neighbours` / `twins` (migration
  core 0019); `/api/network/invitations/?kind=twin`, `/api/network/twins/join/`,
  `/api/network/twins/<id>/end/`, `/api/network/sharing/?audience=…`; `/api/network/groups/<id>/`
  works for groups below, neighbours and twins (`relation`); `/api/network/` gains `neighbours`,
  `twins`, `sharing_neighbours`, `sharing_twins`, `twin_invitations`.
- How to verify: two parishes in one zone each see the other under Groupes voisins. A parish and
  a choir: choir → Jumeler → code; parish → Accepter un jumelage → the choir appears under
  Groupes jumelés; the choir sets Ce que nous partageons → Avec les groupes jumelés → Annonces:
  Détail → the parish opens it and reads its announcements.

## 66. Build 44: networks, phase 6 — contributions between levels

Owner (2026-11-03): money between the levels of a network (yes to "do parish groups pay the zone or
diocese?").

- **Finances → Quotes-parts du réseau** (groups with a group above or groups below):
  - **Demandé aux groupes rattachés**: the finance team (`finances.cashbook` create) → "Demander
    une quote-part": title, amount per group, optional deadline → one contribution per group
    attached directly below; their finance teams are notified. An open one can be cancelled with
    a reason (the group is told).
  - **À payer au groupe au-dessus**: each contribution with its status (À payer, En retard,
    Payée à confirmer, Reçue, Annulée). "Régler" asks to confirm, then records a money-out line
    in this group's cash book and a money-in line in the asking group's ("Quote-part 2027 · GS
    Yapoma"), both pending and approved by each finance team as usual (the approvers of both are
    notified). It becomes "Reçue" when the group above validates its line.
- New cash-book category "Quotes-parts du réseau", used only by this flow (by hand: refused,
  `network_auto`).
- The group above never touches a lower group's money: it asks, the lower group pays.
- Server: `finances.NetworkDue` + category `reseau` (migration finances 0007),
  `apps/finances/network_dues.py`; `/api/finances/network-dues/` (GET, POST),
  `/api/finances/network-dues/<id>/pay/`, `…/cancel/`.
- How to verify: zone trésorier → Finances → Quotes-parts du réseau → Demander une quote-part →
  25 000 → the parish trésorier is notified → Régler → each cash book has a pending line; the
  zone validates its line → the contribution shows "Reçue" on both sides.

## 67. Build 45: networks — reminders, report, back-office contributions

Owner (2026-11-03): the three items left after build 44.

- **Reminders**: the evening-before and "2 heures avant" jobs now include the events sent down
  from above, for the members of each group below (with their usual settings). The people named
  for such an event get their own reminder whatever their setting: "Rappel : vous êtes attendu(e)
  demain 09:00 · Pèlerinage · Zone Nord". Running a job twice still sends nothing more.
- **Quarterly report** (app and PDF): a "Quotes-parts du réseau" section with the contributions
  paid to the group above and received from the groups below during the quarter (by their
  cash-book date), and what is still to pay / to receive. Groups outside any network don't see it.
  The PDF also names the "Quotes-parts du réseau" and "Autre" categories.
- **Back-office → Réseaux de groupes → Quotes-parts** (`backoffice.groups` view): every
  contribution, filtered by network and status, with totals (demandé, reçu, payé à confirmer, à
  payer). Read only.
- **Demo network** to try it all: `python manage.py seed_network_demo --out demo.txt` builds
  "MGS Cameroun (démo)" (a diocese, two zones, four parishes, a twinned choir, 64 made-up
  people with one PIN, sharing, a diocesan announcement, zone events asking for people, a
  contribution); `--delete` removes it. See RUNNING_LOCALLY.md "Demo network".
- No migration.
- How to verify: a zone event sent down for tomorrow with a named parish member → after the
  evening job the member has "Rappel : vous êtes attendu(e)…". Finances → Rapport shows the
  contributions of the quarter. Back-office → Réseaux de groupes → Quotes-parts.

## 68. Build 46: networks — six levels, roles per level, setting up a network, « à compléter »

Owner (2026-11-03), after sharing the Church's hierarchy (paroisse › zone, e.g. Zone Wouri 9 with
7 parishes › archidiocèse de Douala › province ecclésiastique › Église au Cameroun): "go ahead with
the 4"; groups stop at the diocese for now, national later; and Huddle is not only for the Garde
Suisse, which is a good starting point.

1. **Up to six levels** per network (was four). Back-office → Réseaux de groupes → Modifier: six
   level names; a level can stay named but empty (e.g. Province ecclésiastique, National).
2. **Roles per level.** A new group of a level copies the roles of that level's **model group**
   (the first group created there, changeable on the network's panel "Rôles des nouveaux groupes,
   par niveau"). The first one takes a preset: *Bureau de zone* (coordinateur de zone,
   coordinateur adjoint, secrétaire, trésorier, commissaire aux comptes, membre), *Bureau
   diocésain* (aumônier diocésain, président diocésain, vice-président diocésain, secrétaire,
   trésorier, commissaire aux comptes, membre), *Bureau simple* (président, vice-président,
   secrétaire, finances) or *Bureau complet* (like the first group). Each keeps a parish role's
   rights and rules underneath; names and rights are edited in Rôles et permissions as usual.
3. **Setting up a network from the back-office**: on each network, **Nouveau groupe** (name,
   level, attached to, roles, place) creates the group in place, and **Importer une liste** takes
   one line per group, « Nom ; niveau ; rattaché à », all or nothing (the error names the line).
   A group the platform team set up and that has no président can be attached directly
   ("Rattacher à…"); a group that runs itself (has a président) still joins with a code.
4. **« À compléter »**: a group with no président yet shows that badge in the back-office tree and
   "À compléter (pas encore de président)" in the app's Réseau. It fills in once someone is given
   its président role.
- The demo network now mirrors the real one: Archidiocèse de Douala (démo) › Zone Wouri 9 (GS
  Yapoma, GS Bonamoussadi, GS Kotto + GS Paroisse 4–7 à compléter) and Zone Akwa (2 parishes);
  GS Yapoma joins its zone with a code; the diocese has its aumônier diocésain, the zones their
  coordinateur de zone.
- Server: `Network.level5/level6`, `core.NetworkLevelModel` (migration core 0020);
  `group_admin.ROLE_PRESETS`, `network.create_in_network`, `import_groups`, `attach_direct`,
  `set_level_model`, `has_president`; `/api/network/` items carry `waiting`.
- How to verify: back-office → Réseaux de groupes → Modifier → add "Province ecclésiastique",
  "National" → Importer une liste with the archdiocese, Zone Wouri 9 and its parishes → the tree
  shows them, « À compléter »; the zone's roles are "Coordinateur de zone"…; give GS Yapoma's
  président the zone's code → it joins.

## 69. Build 47: the demo network from the back-office (staging)

Owner (2026-11-03): "I can't use the Render shell due to my plan."

- Back-office → Réseaux de groupes → **Démonstration** (super admins, staging only): "Créer le
  réseau de démonstration" runs what `seed_network_demo` does and shows, once, the shared PIN and
  every demo account (group, role, name, phone). "Supprimer le réseau de démonstration" (type
  SUPPRIMER) removes it. Both are journaled. A second "Créer" is refused while it exists.
- Staging only: on when `DEMO_TOOLS=true` (now in render.yaml for staging) or the staging task
  token is set; production sets neither, so the page doesn't exist there (404).
- How to verify: deploy staging → back-office as super admin → Réseaux de groupes → Démonstration
  → Créer → note the PIN → sign in to the app with a listed number, e.g. the Zone Wouri 9
  coordinateur → Accueil → group name → Réseau.

## 70. Fix (server only, after build 47): creating the demo network on staging

Owner (2026-11-04): "Créer le réseau de démonstration" answered *Internal Server Error*.

- Cause: the whole demo (13 groups, 68 accounts, ~2 250 queries) was built inside the request,
  including 68 slow PIN hashes (~0.2 s each here, more on Render's small instance). On staging it
  ran past gunicorn's 60 s limit, so the request was cut off (and, being one transaction, nothing
  was kept).
- Fix: the PIN is hashed once and shared (16 s → 2 s locally), and the back-office now starts the
  creation in the background: the page says "Création en cours…" and refreshes itself every few
  seconds, then shows the PIN and the accounts once, to whoever started it. A failure is shown
  with its reason, and nothing is kept. A second "Créer" while one runs is refused; so is
  "Supprimer". The progress waits in Redis (15 min at most), so it works whichever server worker
  answers.
- No migration, no new APK (the app is unchanged; build 47 stays current).
- How to verify: deploy staging → back-office → Réseaux de groupes → Démonstration → Créer → the
  page shows "Création en cours…", then the PIN and the accounts.

## 71. Build 48: networks — files reach other groups, choose who receives, clearer sharing, ask for more

Owner (2026-11-04): photos and files of announcements sent to the network weren't visible; the
sender should choose who receives (like the member picker of a group announcement), also for the
calendar; the sharing levels weren't explained; a linked group's page should show, with filters,
what is visible, what isn't and how to ask for it.

- **Photos and files reach the other groups.** The list and the detail of announcements read the
  attachments with the scoped manager, which kept only the current group's: an announcement from
  the zone came without its files in a parish. Fixed (`_with_files`).
- **"Diffuser dans le réseau"** replaces the on/off switch, in a new announcement and in an event:
  a full page lists the groups this one can reach — below at any depth, neighbours, twins — with
  filters (Tous · En dessous · Voisins · Jumelés), search past 6 groups, "Tout sélectionner", and
  **Qui la reçoit: Tous les membres / Le bureau seulement** (holders of a bureau role in each
  chosen group; the others neither see it nor get reminders). The sender's card then says
  "Diffusé à : GS Kotto · Le bureau seulement". Events: only the chosen groups directly below can
  be asked for people (contingents); adding a group to an event later tells that group only.
  Server: `Announcement.reach` / `Event.reach` (M2M) and `reach_audience`; no list = every group
  below, as before (older posts keep working). `GET /api/network/recipients/`.
- **What we share, spelled out.** Each part has its levels as cards that say exactly what is shown
  (e.g. Finances · Résumé: the balance and the year's totals; Détail: + the last 30 approved
  entries), who reads it in the other group, an "Always private" card, and **Aperçu**: the group
  as the audience would see it with the choices on screen, before saving
  (`POST /api/network/sharing/preview/`; only parts the viewer reads in their own group).
  Announcements now have two levels: Résumé = title and text (what "Détail" was), Détail = + photos
  and files. Groups that had chosen "Détail" are moved to "Résumé" by the migration, so nothing
  more is shown than they agreed to.
- **A linked group's page**: header with its relation (Rattaché · Voisin · Jumelé), three counters
  (Visibles · Réservés à d'autres rôles · Non partagés) that filter, filter chips, one card per
  part with its state and data, and **Demander l'accès / Demander le détail** (choose the level, a
  message). A waiting request shows on the card with "Annuler la demande"; a declined one says when
  and why. Who may ask: whoever would read that part in their group, or the président.
- **Demandes de partage** (Réseau → new row, with a count for the président; the notification opens
  it): Reçues / Envoyées. The président accepts — which shares that part at that level with the
  whole audience (every group above, every neighbour…), said before confirming — or declines with an
  optional reason; the asking group is told. All audited in both groups. `ShareRequest`,
  `/api/network/groups/<pk>/requests/`, `/api/network/requests/`, `/api/network/requests/<pk>/`.
- Demo network: a zone post for two parishes' bureaux only, and two requests waiting (Zone Wouri 9
  → GS Kotto: finances in detail; Zone Akwa → GS Bonapriso: finances).
- Also: the network's level names in Réseau now include levels 5 and 6; test phone numbers no longer
  collide with the demo's.
- Migrations: core 0021, announcements 0007, events 0011.
- How to verify (demo network): as Zone Wouri 9's président, new announcement → Diffuser dans le
  réseau → pick GS Kotto, "Le bureau seulement" → send; GS Kotto's président sees it, a plain
  member doesn't. Attach a PDF to a zone announcement sent to all: a parish member opens it. As
  GS Kotto's président: Réseau → Demandes de partage → accept the zone's request; as the zone's
  treasurer, Réseau → GS Kotto shows finances in detail. Réseau → Ce que nous partageons → Aperçu.

