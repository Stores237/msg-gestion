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

## Back-office login

- Phone + password (Django's hasher, minimum 10 characters), then a 6-digit SMS code via Twilio
  Verify. Only people whose roles grant `backoffice.users:view` or `backoffice.audit:view` can
  pass the first step; everyone else gets the same "wrong number or password" message.
- "Trust this computer for 30 days" sets a signed, HTTP-only cookie tied to the password hash:
  changing the password revokes every trusted device.
- Without Twilio configured, codes are only logged, and only when `SMS_DEV_FALLBACK` is on
  (dev settings). Otherwise login fails with a clear error instead of pretending a code was sent.
- The HTML forms have their own per-IP rate limit (20/h) in the same Redis.

## Fixed rules (cannot be changed from the back-office)

Defined in `apps/accounts/registry.py`:

- The trésorier can never *validate* finances; the commissaire aux comptes validates.
- One person can't be both trésorier and commissaire aux comptes.
- The super admin role can never see finances, whatever other role the same person holds.
- There must always be at least 2 active super admins; removing one below that is refused.

Each refusal is written to the audit log.

## Data visible by role

Minors' parent contacts are a separate resource (`members.minor_contacts`), granted to the
président and the secrétaire général only by default. Data a role can't see must never be sent
to that role's app; filter on the server, not in the UI.
