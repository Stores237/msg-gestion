# TODOs

## Owner action items (block the matching engineering work)

These need an account, a decision or a person — not code.

- [x] **Logo** — "MSG" monogram for now (2026-10-20). A drawn version later only replaces
  `MsgLogo` / `.msg-logo`. Still to do: the Android/iOS launcher icon.
- [x] **Supabase staging project** (2026-10-20, "MSGes Project", eu-west-1).
- [ ] **Render account** + Render Key Value — see
  `RENDER_STAGING.md` §1. Blocks: any deploy.
- [ ] **Twilio** account, Verify Service and API key. Blocks: back-office login on staging
  (codes can't be sent without it) and SMS PIN reset.
- [ ] **Sentry** project (free). Strongly recommended before the first tester.
- [ ] **The first two super admins** — contactgardesuisse@gmail.com and storefix237@gmail.com.
  Still needed for each: full name and mobile number (back-office login is phone + SMS code).
- [ ] **Real member list** to import (spreadsheet: name, phone, group, date of birth, parent
  contact for minors). For now `seed_demo` has 21 made-up members (10 added 2026-10-20).
- [ ] **Revoke the Supabase access token** pasted in chat on 2026-10-20, once setup is done.
- [ ] **Beta window**: start date, length, and who the testers are.
- [ ] Confirm the default role permissions (migration `accounts.0002`), taken from the design's
  "Navigation par rôle" table — e.g. should the président be able to *validate* the quarterly
  report, or only approve it?

## Engineering backlog

### P0 — before the first tester
- [ ] PIN setup and reset by SMS (imported members get an SMS to create their PIN; "Code
  oublié ?"). Today a PIN can only be set with `manage.py set_pin`.
- [ ] Back-office: create a user, assign/revoke a role (services and rules already exist in
  `apps/accounts/services.py`, with tests), suspend, reset PIN.
- [ ] Back-office: bulk import from a spreadsheet (design: BImport).
- [ ] Back-office: active sessions page and sign-out of other sessions (design: BSessions).
- [ ] Beta APK build/verify/host workflow (playbook §9) rehearsed once.

### P1 — the app's modules, one vertical slice each
- [ ] Members: list, profile (with minors' contacts gated), add member.
- [ ] Finances: cash book (entry → validation by the commissaire), solidarity contributions in
  thirds, quarterly report, PDF export.
- [ ] Calendar: month/agenda, event detail, reminders, attendance call (works offline).
- [ ] Planning: weekly grid, assign post/group, my duties, swaps, alb-washing rotation.
- [ ] Announcements: feed, composer, convocation linked to an event, read receipts.
- [ ] Offline: local store + "pending send" queue + sync line (design: États).

### P2
- [ ] Biometric unlock (fingerprint key is shown disabled).
- [ ] Notifications (push).
- [ ] Mandate-expiry reminder 30 days before the end (a scheduled job; see
  `RENDER_STAGING.md` §3 for how jobs are added).
- [ ] Audit log export (CSV/PDF) and filters by author/module.

## Recently shipped

### 2026-10-20 — Foundation (v0.1)
Backend skeleton, phone + PIN login with lockout, roles and permission matrix with fixed rules,
audit log, back-office (2FA login, dashboard, users, roles matrix editor, audit log), Flutter
shell (login, role-based tabs), CI, Render Blueprint. See `BETA_CHANGES.md` §1–§5.
