# TODOs

## Owner action items (block the matching engineering work)

These need an account, a decision or a person — not code.

- [x] **Logo** — "MSG" monogram for now (2026-10-20). A drawn version later only replaces
  `MsgLogo` / `.msg-logo`. Still to do: the Android/iOS launcher icon.
- [x] **Supabase staging project** (2026-10-20, "MSGes Project", eu-west-1).
- [x] **Render** staging service + Key Value (2026-10-20) — see
  `RENDER_STAGING.md` §1. Blocks: any deploy.
- [ ] **Twilio** account, Verify Service and API key. Blocks: back-office login on staging
  (codes can't be sent without it) and SMS PIN reset.
- [ ] **Sentry** project (free). Strongly recommended before the first tester.
- [x] **The first two super admins** on staging (2026-10-20): Alpha Suisse Japoma
  (659802679, contactgardesuisse@gmail.com) and Omega Store's User (654858138,
  storefix237@gmail.com). Temporary credentials in gitignored `backend/.staging-admins.txt`.
  Back-office login still needs Twilio.
- [ ] **Real member list** to import (spreadsheet: name, phone, group, date of birth, parent
  contact for minors). For now `seed_demo` has 21 made-up members (10 added 2026-10-20).
- [ ] **Revoke the tokens pasted in chat on 2026-10-20**, once setup is done: the Supabase access
  token (supabase.com/dashboard/account/tokens), the Render API key (dashboard → Account
  Settings → API Keys) and the GitHub personal token (github.com/settings/tokens — revoke this
  one now; it was never needed).
- [ ] **Back up the Android upload key**: `app/android/keystore/upload-keystore.jks` and
  `app/android/key.properties` (git-ignored, only on this machine). Losing them means the app
  can never be updated on Google Play under the same listing.
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
- [x] Beta APK build/verify/host workflow rehearsed (0.1.0 build 1, 2026-10-20).

### P1 — the app's modules, one vertical slice each
- [x] Members: list, profile (with minors' contacts gated), add member (2026-10-20).
- [ ] Finances: cash book (entry → validation by the commissaire), solidarity contributions in
  thirds, quarterly report, PDF export.
- [x] Calendar: month/agenda, event detail, absence notice, roll call (2026-10-20). Still to do:
  reminders, offline roll call, editing/deleting events in the app.
- [ ] Planning: weekly grid, assign post/group, my duties, swaps, alb-washing rotation.
- [x] Announcements: feed, composer, convocation linked to an event, read receipts (2026-10-20).
  Still to do: PDF attachments, "relancer les non-lecteurs" (needs push notifications).
- [ ] Offline: local store + "pending send" queue + sync line (design: États).

### P2
- [ ] Back-office in English too (the app is bilingual; the back-office is French only for now).
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
