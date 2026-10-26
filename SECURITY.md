# Security notes

## App login (members)

- Identifier: phone number, normalised to E.164 on the server (`apps/accounts/phone.py`).
- Secret: a 4-digit PIN, hashed with Django's password hasher (`User.pin`). 4 digits is weak on
  its own; it is acceptable only because of the lockout and the throttles below.
- **Lockout**: 3 wrong PINs lock the account for 15 minutes (`PIN_MAX_ATTEMPTS`,
  `PIN_LOCKOUT_MINUTES`). Counted on the server under a row lock, so parallel guesses can't share
  an attempt. A lock is written to the audit log.
- **Throttles** (Redis-backed, per client IP): phone lookup 30/h, PIN login 30/h, token refresh
  120/h. Without a reachable Redis these endpoints fail rather than run unthrottled.
- **Deliberate disclosure**: `POST /api/auth/phone/` returns the member's first name, because the
  design greets the member on the PIN screen ("Bonjour Ingrid"). Anyone can therefore check
  whether a number belongs to a member, up to 30 times an hour per IP. Unknown, suspended and
  archived numbers get the same answer.
- **Tokens**: JWT access token 15 min, refresh token 30 days, rotated on every use, old one
  blacklisted. The app shares one in-flight refresh between concurrent requests
  (`AuthSession.refreshAccessToken`) so rotation never logs a member out.

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
  Verify. Only super admins can pass the first step (`access.can_enter`); everyone else, a group
  officer included, gets the same "wrong number or password" message. A session whose holder
  stops being super admin ends on its next request.
- Super admin accounts are refused in the mobile app (`backoffice_only`, after a correct PIN so a
  stranger learns nothing; existing app tokens are rejected by `AppJWTAuthentication`).
- "Trust this computer for 30 days" sets a signed, HTTP-only cookie tied to the password hash:
  changing the password revokes every trusted device.
- Without Twilio configured, codes are only logged, and only when `SMS_DEV_FALLBACK` is on
  (dev settings). Otherwise login fails with a clear error instead of pretending a code was sent.
- The HTML forms have their own per-IP rate limit (20/h) in the same Redis.

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
- Deleting a group takes two super admins (`apps/core/group_admin.py`): one asks, with a reason
  and the group's name typed back; a different one confirms, again typing the name, within 3
  days (the request lapses after). The platform's last active group can't be deleted. A deleted
  group is hidden (`is_active=False`): its members can't open it in the app and it leaves the
  back-office's group choice, but its data is kept and a super admin can restore it. Request,
  cancellation, refusal, deletion and restore are in the platform audit log.

Each refusal is written to the audit log.

## Data visible by role

Minors' parent contacts are a separate resource (`members.minor_contacts`), granted to the
président and the secrétaire général only by default. Data a role can't see must never be sent
to that role's app; filter on the server, not in the UI.
