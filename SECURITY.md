# Security notes

## App login (members)

- Identifier: phone number, normalised to E.164 on the server (`apps/accounts/phone.py`).
- Secret: a 4-digit PIN, hashed with Django's password hasher (`User.pin`). 4 digits is weak on
  its own; it is acceptable only because of the lockout and the throttles below.
- **Lockout**: 3 wrong PINs lock the account for 15 minutes (`PIN_MAX_ATTEMPTS`,
  `PIN_LOCKOUT_MINUTES`). Counted on the server under a row lock, so parallel guesses can't share
  an attempt. A lock is written to the audit log.
- **Throttles** (Redis-backed, per client address, see "Client address" below): phone lookup
  30/h, PIN login 30/h, PIN reset 10/h, terms 120/h, token refresh 120/h. Without a reachable
  Redis these endpoints fail rather than run unthrottled.
- **Deliberate disclosure**: `POST /api/auth/phone/` returns the member's first name, because the
  design greets the member on the PIN screen ("Bonjour Ingrid"). Anyone can therefore check
  whether a number belongs to a member, up to 30 times an hour per IP. Unknown, suspended and
  archived numbers get the same answer.
- **Tokens**: JWT access token 15 min, refresh token 30 days, rotated on every use, old one
  blacklisted. The app shares one in-flight refresh between concurrent requests
  (`AuthSession.refreshAccessToken`) so rotation never logs a member out.
- **One phone at a time** (owner, 2026-10-30): each app sign-in (PIN, or "Code oublié ?")
  gives the account a new session id (`User.app_session`), carried in the tokens as `sid`, and
  blacklists the account's other refresh tokens. A token with an older `sid` is refused on every
  request and on refresh (401 `other_device`), so the previous phone is signed out at its next
  request — within seconds, not when its 15-minute access token runs out — erases its offline copy
  and shows why. The newest phone wins, so a lost phone never locks its owner out; the sign-in is
  journaled ("Connexion sur un autre téléphone"). Tokens from before the rule (no `sid`) work
  until the member's next sign-in.

### Conditions of use at login (owner, 2026-10-26)

- The phone-number screen has a checkbox "J’ai lu et j’accepte les conditions d’utilisation";
  the link opens the text from back-office → Plateforme · aide (`GET /api/auth/terms/`, public,
  throttled). Continue tells the member to tick it first.
- The server enforces it: `POST /api/auth/login/` and `/api/auth/pin/forgot/confirm/` answer
  `428 terms_required` unless the member has accepted the current version, or sends
  `accept_terms: true` with that `terms_version`. Checked after the PIN (a stranger learns
  nothing) and, for the PIN reset, before the SMS code is used up.
- Acceptance is recorded on the account (`terms_version`, `terms_accepted_at`, shown on the
  back-office member page) and in the audit log ("Conditions d’utilisation acceptées").
- Editing the terms text in the back-office raises the version: everyone accepts the new text at
  their next login. A box ticked on the old text doesn't count. Re-saving the same text (browsers
  send CRLF) does not raise it.
- Members already signed in accept at their next login; the app lock is not a login.

### App lock (owner, 2026-10-23)

- The PIN is asked whenever the app opens on a saved session, and when it comes back after 2
  minutes or more in the background. Fingerprint or face unlock (the phone's own prompt,
  `local_auth`, biometric only) can be turned on in Mon compte; it is confirmed once when turned
  on, and the PIN always works too.
- The lock checks the PIN on the phone, so it works offline: at sign-in, PIN change or PIN reset
  the app keeps a salted hash (SHA-256 × 20 000, 16-byte random salt) in the phone's secure
  storage (Android Keystore / iOS Keychain), never the PIN itself. The server still checks the
  PIN at every sign-in and keeps its own attempt counter and lock-out.
- 5 wrong PINs on the lock screen close the session (tokens, PIN hash and biometric setting are
  erased); the member signs in again with number and PIN. Signing out erases them too.
- A session opened before this version has no PIN hash: the member signs in once more.

## Back-office login

- Phone + password (Django's hasher, minimum 10 characters), then a 6-digit SMS code via Twilio
  Verify (backup codes until Twilio is set up). Only platform accounts (super admins and the
  back-office staff) can pass the first step (`access.can_enter`); everyone else, a group officer
  included, gets the same "wrong number or password" message. A session whose holder stops being
  a platform account ends on its next request.
- Super admin accounts are refused in the mobile app (`backoffice_only`, after a correct PIN so a
  stranger learns nothing; existing app tokens are rejected by `AppJWTAuthentication`).
- "Trust this computer for 30 days" sets a signed, HTTP-only cookie tied to the password hash:
  changing the password revokes every trusted device.
- Without Twilio configured, codes are only logged, and only when `SMS_DEV_FALLBACK` is on
  (dev settings). Otherwise login fails with a clear error instead of pretending a code was sent.
- The HTML forms have their own per-address rate limit (20/h) in the same Redis.
- A back-office account changes its own password from the account menu (`/bo/mot-de-passe/`):
  current password required, Django's password validators, the other sessions and trusted
  devices end (the session renews its key and stays). Changes and wrong attempts are audited.
- A member's phone number (their login) is changed only in the back-office, with a reason, by
  "Utilisateurs › Modifier" (a platform account's only by a super admin); it must be unique, the
  person's refresh tokens are blacklisted so their phones are signed out, and the old and new
  numbers are audited. Identity edits are audited field by field (before/after).
- The API schema and docs (`/api/schema/`, `/api/docs/`) open only in a signed-in back-office
  session (`IsPlatformAccount`), not to the public.

## Client address

Rate limits and the audit log key on `apps.core.audit.client_ip`, never on the left of
`X-Forwarded-For` (the client writes that part). In production the address comes from
`CF-Connecting-IP`, set by Cloudflare in front of Render (`CLIENT_IP_HEADER`); without that
header, from the last `X-Forwarded-For` entry (added by the proxy); otherwise the socket address.
Check after each infrastructure change: back-office → Intégrations → "Adresse du visiteur" must
show your own public address. A Cloudflare or Render address there means every member shares one
login limit; fix `CLIENT_IP_HEADER` on Render.

## On the phone

- Tokens, the PIN hash and the biometric setting are in secure storage (Keystore / Keychain).
- The offline copy (cached answers and unsent changes) is in the app's private files. It is
  erased on sign-out (after a warning if changes are still unsent), after 5 wrong PINs on the
  lock screen, and when a different account signs in on the phone (`OfflineState.belongsTo`).
- Photos seen and downloaded files (`FileStore`, `msg_files/` in the app's private files) are
  erased with the offline copy. Only `msg_files/downloads/` is shared, read-only and one file at a
  time, with the phone's PDF viewer (FileProvider, not exported). A copy the member puts in the
  phone's Pictures/MSG or Download/MSG is outside the app and stays after sign-out; that is the
  member's choice. The storage permission is requested only on Android 7–9 (`maxSdkVersion=28`).
- Android backup is off (`allowBackup="false"`, `data_extraction_rules.xml`): member data never
  leaves the phone in a Google backup or a device transfer.

## Groups

- Every app request works inside one group: the `X-Group` header, checked against the member's
  memberships (`not_in_group` otherwise). Group-owned tables are filtered by the current group in
  their default manager; cross-group access goes through `all_groups` explicitly.
- Access requests: the temporary PIN of a new account is stored in clear only until the leader
  has seen it once (then erased, audited) and for 7 days at most; the member must replace it at
  first sign-in.

## Fixed rules (cannot be changed from the back-office)

Defined in `apps/accounts/registry.py`:

- Finances take two hands: the commissaire aux comptes enters (never validates); the trésorier,
  who holds the money, validates (never enters, changes or deletes). Nobody validates a line they
  entered.
- One person can't be both trésorier and commissaire aux comptes.
- Back-office permissions belong to platform roles only: the super admin and the back-office
  staff (support, IT helpdesk, integration ops; agent and responsable levels). Staff roles can
  never hold anything outside the back-office (finances, a group's members, calendar…), changing
  roles and permissions, or creating, changing or deleting groups. Only the super admin creates,
  changes or removes staff accounts, sets back-office passwords, and acts on a super admin's
  account; staff never act on platform accounts except the IT helpdesk's session/backup-code
  help for other staff.
- Platform accounts (super admin, staff) work only in the back-office; the app refuses them
  (`backoffice_only`), and an access request can't add one to a group.
- The super admin holds every permission, finances included, but only in the back-office.
- There must always be at least 2 active super admins; removing one below that is refused.
- Only the super admin role (and Membre, the membership itself) is held with no end
  (`OPEN_ENDED_ROLES`). Every other role, back-office staff included, is given for the duration
  set on it (1–120 months, changed with a reason, audited); a role without one can't be given.
- Deleting a group takes two super admins (`apps/core/group_admin.py`): one asks, with a reason
  and the group's name typed back; a different one confirms, again typing the name, within 3
  days (the request lapses after). The platform's last active group can't be deleted. A deleted
  group is hidden (`is_active=False`): its members can't open it in the app and it leaves the
  back-office's group choice, but its data is kept and a super admin can restore it. Request,
  cancellation, refusal, deletion and restore are in the platform audit log.

Each refusal is written to the audit log.

- **Finance edits** (owner, 2026-10-30): the trésorier may correct a line only while it is "À
  valider", only through his *validate* right (never *change*), never his own entry, and every
  change is journaled with before/after. An edited line needs a second person after him: the
  commissaire finalises it (whoever edited or validated it can't), or sends it back with a reason.
  Until then it is not in the balance.

## Data visible by role

Swap and absence requests are decided by the lineup makers (calendar.planning change) for any
event, and by an event's chef de groupe for that event only (`planning.services.can_decide`);
others get `403 not_decider`.

Chef de groupe reports (owner, 2026-10-27) are read by the event's chef and by roles with
"Rapports des chefs de groupe" (formateur, formateur adjoint, secrétaire général, censeur
général, vice-censeur by default); others get `403 report_forbidden`. Only the event's chef hands
one in; a PDF is checked on its bytes, 10 MB at most, and served by signed URL.

Minors' parent contacts are a separate resource (`members.minor_contacts`), granted to the
président and the secrétaire général only by default. Data a role can't see must never be sent
to that role's app; filter on the server, not in the UI.

## Security check — 2026-10-26

Scope: the Django API and back-office, the Flutter app, the Android build, the dependencies and
the repository. Method: `pip-audit` on `requirements.txt`; `bandit` on the server code;
`manage.py check --deploy` with production settings; a scan of the git history for keys,
tokens and passwords; `flutter pub outdated`; a manual review of login, rate limits,
permissions and group isolation, uploads, templates (escaping, redirects), CORS, settings, the
offline cache and the Android manifest; the staging response headers (one `/healthz/` request).

### Found and fixed

| # | Finding | Severity | Fix | Test |
|---|---|---|---|---|
| 1 | Rate limits keyed on `X-Forwarded-For` as sent by the client: DRF used the whole header, the back-office the left entry. A script sending a new fake address per request walked past the limits on phone lookup, PIN login, PIN reset and back-office login (password spraying across members); audit-log addresses could be forged too | High | `client_ip` reads Cloudflare's `CF-Connecting-IP`, else the proxy-added (last) entry; one throttle class for the whole API (`ClientIPScopedRateThrottle`). The per-account lockout (3 wrong PINs) was always in place | `apps/core/test_security.py` |
| 2 | Offline copy kept after sign-out: the next person signing in on the same phone could see the previous member's cached lists (finances included) when offline, and the previous member's unsent changes would have been sent under the new account | Medium | Erased on sign-out (warning if unsent), after 5 wrong PINs, and when another account signs in | `app/test/offline_owner_test.dart` |
| 3 | Android cloud backup on by default: the offline copy could be copied to the member's Google backup | Medium | `allowBackup="false"`, `fullBackupContent="false"`, data-extraction rules excluding everything | manifest review |
| 4 | Pillow 12.3.0: 37 published vulnerabilities (fixed in 13.0.0). Uploads are already limited to JPEG/PNG by their bytes, so the TIFF/GIF/PPM ones were not reachable | Medium | Pillow 13.0.0; `pip-audit` now reports none | full test suite |
| 5 | API schema and Swagger docs public: a full map of the endpoints for anyone | Low | Back-office session only | `test_api_map_is_for_back_office_accounts_only` |
| 6 | CORS headers sent on every path, the back-office included | Low | Limited to `/api/` (`CORS_URLS_REGEX`); the back-office never sends them | `test_cors_headers_only_on_the_api` |

### Checked, nothing to fix

- **Secrets**: no key, token, password or `.env` in the git history; `.env*`, keystores,
  `key.properties` and the tester/admin credential files are git-ignored. The only hard-coded
  password is `seed_demo`'s, and that command refuses to run with `DEBUG` off.
- **Deploy settings**: `check --deploy` raises only HSTS subdomains/preload, which don't apply
  to an `onrender.com` host. HTTPS redirect, secure cookies, HSTS 30 days, `X-Frame-Options`
  DENY, no `DEBUG` in production.
- **Templates**: every `format_html` escapes its values; the one `mark_safe` is a fixed icon
  (bandit's only medium finding, a false positive). The group switch's `next` is checked with
  `url_has_allowed_host_and_scheme`. Colours are validated as `#RRGGBB` before reaching a
  `style` attribute.
- **SQL**: no raw SQL except `SELECT 1` in the health check.
- **Uploads**: type checked on the bytes (PDF/JPEG/PNG), 5 MB photos, 10 MB attachments, stored
  on Supabase under cleaned names (Django's storage name check), served by signed URLs.
- **Groups**: default managers filter by the current group; `all_groups` is used only by the
  platform's own code (group creation, staff roles), never from an app request.
- **Back-office**: the session is opened only after the second factor; refusals are audited;
  the scheduler endpoint is off unless `TASK_TRIGGER_TOKEN` is set and compares it in
  constant time.
- **SMS codes**: Twilio Verify allows 5 tries per code; the PIN reset is throttled 10/h.
- **App dependencies**: patch updates only (`crypto`, `file_picker`); no published advisory.

### Open (accepted for the beta, or for the owner)

- **4-digit PIN**: weak on its own; acceptable with the server lockout, the rate limits (now
  reliable, finding 1) and the app lock. Revisit (6 digits) before opening to the public.
- **Number check discloses membership** (deliberate, above). Rate-limited.
- **Shared mobile addresses**: in Cameroon many phones share one carrier address (CGNAT), so
  30 logins/h per address can be reached by a group signing in together after an assise. Watch
  for 429s in Sentry; raise `pin_login` if it happens.
- **Offline copy is not encrypted on the phone**: private to the app, erased as above, never
  backed up; a rooted or forensically examined phone could read it. Encrypting it with a key in
  secure storage is in the engineering backlog.
- **No Content-Security-Policy on the back-office**: the templates use inline handlers; a CSP
  needs them moved to scripts first. Backlog.
- **Owner**: revoke the tokens pasted in chat on 2026-10-20 (TODOS.md);
  have the terms and privacy drafts reviewed; confirm "Adresse du visiteur" after the next deploy.
