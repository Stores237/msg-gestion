# TODOs

- [x] **Owner — storage (2026-10-26):** new Supabase S3 access key set on Render and deployed
  (owner, 2026-10-27); photos, attachments and PDF reports use it.
- [ ] **Owner — after the next deploy (2026-10-26):** install build 15 (older builds can't tick
  the terms box, so they can't sign in); open back-office → Intégrations and check "Adresse du
  visiteur" shows your own public address (SECURITY.md "Client address").
- [ ] **Owner — events (2026-10-27):** after deploying, install build 16; give the new
  Vice-censeur role to someone in each group (back-office → Rôles), and check the "Int./Ext."
  and "Chef" switches in Paramètres → Types d’activités.
- [ ] **Owner — build 39 (2026-11-03, networks of groups):** deploy on Render (migrations core
  0017, accounts 0026), then back-office → Réseaux de groupes: create the MGS network and its
  levels, place each group, create the zones/dioceses as groups (Groupes → Nouveau groupe) and
  give each its président; send each parish président their zone's code. Install build 39.
- [ ] **Owner — build 40 (2026-11-03, network sharing):** deploy (migration core 0018); each
  attached group's président sets Réseau → Ce que nous partageons. Install build 40.
- [ ] **Owner — build 41 (2026-11-03, sent down):** deploy (migrations announcements 0006,
  events 0009); install build 41.
- [ ] **Owner — build 42 (2026-11-03, joint planning):** deploy (migration events 0010); install
  build 42.
- [ ] **Owner — build 43 (2026-11-03, neighbours and twinning):** deploy (migration core 0019);
  install build 43.
- [ ] **Owner — build 44 (2026-11-03, contributions):** deploy (migration finances 0007); install
  build 44. Networks phases 1–6 are all in (39–44): try them together on staging.
- [ ] **Owner — website (2026-11-05):** check the texts in `website/index.html`, above all the
  Emergensis line (written from its logo: "Les urgences de santé, localisées : trouver vite l'aide
  la plus proche") and the Spekooh / S@Learn lines; send the links of the other products if they
  should be clickable; choose where the site lives (domain, e.g. a Render static site) and a
  contact (phone, WhatsApp or e-mail) for "Contactez STORES".
- [ ] **Owner — build 48 (2026-11-04, network: files, recipients, sharing requests):** deploy
  (migrations core 0021, announcements 0007, events 0011); install build 48. To try it on the demo
  network, remove it and create it again (back-office → Réseaux de groupes → Démonstration): the new
  one has a bureau-only post and two sharing requests waiting.
- [ ] **Owner — build 47 (2026-11-03, demo from the back-office; fixed 2026-11-04):** deploy
  staging again (the first version timed out: "Internal Server Error"); check
  Environment has `DEMO_TOOLS=true` (add it if the Blueprint didn't); back-office → Réseaux de
  groupes → Démonstration → Créer; note the PIN; install build 47 and try the demo accounts.
- [ ] **Owner — build 46 (2026-11-03, network setup):** deploy (migration core 0020). In the
  back-office, name the MGS network's levels (Paroisse · Zone paroissiale · Diocèse · Province
  ecclésiastique · National), import the archdiocese, its zones and parishes (« Nom ; niveau ;
  rattaché à »), check the roles of the first zone and of the archdiocese (they become the
  models), then give Yapoma's président the Zone Wouri 9 code. Province and national: later.
- [ ] **Owner — build 45 (2026-11-03):** deploy (no migration) and install build 45.
- [ ] **Owner — build 38 (2026-11-03, export period):** deploy on Render (no migration of its own) and install build 38.
- [ ] **Owner — build 37 (2026-11-02, group settings, FAQ, recovery code):** deploy on Render
  (migrations core 0016, accounts 0025, finances 0006; also builds 35–36's if not yet deployed),
  then fill back-office → Paramètres → Cotisations et caisse, Règles des membres, Calendrier and
  Langue et contacts for each group (everything defaults to "off" / today's behaviour), and add
  questions in back-office → Questions fréquentes. Install build 37 (over build 36).
- [ ] **Engineering — later:** per-group time zone (all jobs run on Douala time today), and fees
  as an editable list instead of the 4 fixed amounts.
- [ ] **Owner — build 36 (2026-11-02, Huddle's own app ID):** every tester installs build 36 (a new app for Android), signs in again and uninstalls the old MSG app.
- [ ] **Owner — build 35 (2026-11-02, Huddle):** deploy on Render (migrations core 0015, accounts 0023 and 0024). Upload each group's logo (back-office → Paramètres, or the président in the app). Optional: send the Huddle logo as SVG if a designer has it (the app uses a redrawn version, design/brand/).
- [ ] **Owner — build 34 (2026-10-30):** deploy on Render (migration accounts 0022) and install build 34 (includes 33). Then back-office → Paramètres → Approbation des dépenses (check the types and who approves) and Sécurité des finances.
- [ ] **Owner — build 33 (2026-10-30):** deploy on Render and install build 33 (includes 30–32: attachments on the expense request form).
- [ ] **Owner — build 32 (2026-10-30):** deploy on Render (staging was still on build 30: the back-office's Domaines de dépense and Code finances arrive with this deploy; migrations accounts 0020, 0021; core 0014; finances 0004, 0005) and install build 32 (includes 30 and 31).
- [ ] **Owner — build 31 (2026-10-30):** deploy on Render (migrations accounts 0020, 0021; core 0014; finances 0004, 0005) and install build 31 (includes 30). In the back-office: check Paramètres → Domaines de dépense (names, lead roles) and decide whether to turn on Sécurité des finances → Code finances obligatoire. Tell members about Accueil → Demandes de dépense.
- [ ] **Owner — build 30 (2026-10-30):** deploy on Render (migration accounts 0019: trésorier and commissaire both get the cash-book and solidarity rights) and install build 30. Tell the finance team: both enter, the other approves; long press to validate several.
- [ ] **Owner — build 29 (2026-10-30):** deploy on Render (raised sign-in limits, no migration) and install build 29 (includes 27 and 28, which were withdrawn: built without the server address).
- [ ] **Owner — build 26 (2026-10-30):** deploy on Render (migrations accounts 0018 and finances
  0003) and install build 26 (it includes build 25). From then on an account works on one phone
  at a time; tell the testers who share an account, or use a phone and the emulator, that the
  older one gets signed out.
- [ ] **Owner:** fill in back-office → Plateforme · aide (support phone, WhatsApp, e-mail, website)
  and have the privacy policy and terms drafts reviewed.

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
  Staging also has one test account per staff role (`add_role_testers`, 2026-10-23); PINs in
  `backend/.staging-testers.txt`.
- [ ] **Revoke the tokens pasted in chat on 2026-10-20**, once setup is done: the Supabase access
  token (supabase.com/dashboard/account/tokens), the Render API key (dashboard → Account
  Settings → API Keys) and the GitHub personal token (github.com/settings/tokens — revoke this
  one now; it was never needed).
- [ ] **Back up the Android upload key**: `app/android/keystore/upload-keystore.jks` and
  `app/android/key.properties` (git-ignored, only on this machine). Losing them means the app
  can never be updated on Google Play under the same listing.
- [ ] **Beta window**: start date, length, and who the testers are.
- [ ] Confirm what a président / vice-président lineup change should require beyond the
  audit entry and the formateurs' notification (e.g. a written reason each time).
- [ ] Confirm the default role permissions (migration `accounts.0002`), taken from the design's
  "Navigation par rôle" table — e.g. should the président be able to *validate* the quarterly
  report, or only approve it?

## Engineering backlog

### Pending on the owner's accounts
- [ ] SMS (Twilio): "Code oublié ?" and back-office codes by SMS. Everything else works; back-office login uses backup codes meanwhile.
- [ ] Push notifications (Firebase project): notifications are in-app today; push to the lock screen needs an FCM project.

### Multi-group (found 2026-10-27, needs an owner decision)
- [ ] **Planning posts and sides are fixed in code** (`planning.models.POSTS`: première centrale,
  deuxième centrale, contrôle, petites portes, mésanie; `SIDES`: Pariso, Yapoma). They are this
  parish's layout; another group can't plan its own. Proposal: per-group posts and sides in
  Paramètres (the current ones copied for the first group), lineup sizes derived from them.
- [ ] App wording says "gardes" in a few planning strings (7 in `app_fr.arb`); neutral "membres"
  or a per-group term from Paramètres.

### Security backlog (SECURITY.md "Security check — 2026-10-26", open items)
- [ ] Encrypt the phone's offline copy with a key kept in secure storage.
- [ ] Content-Security-Policy for the back-office (move the inline handlers to scripts first).
- [ ] 6-digit PIN before opening to the public.
- [ ] Watch for 429s on login from shared carrier addresses (limits raised 2026-10-30: login 120/h, refresh 1200/h).

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
- [x] Several groups on one platform (2026-10-23, option B). Activity types and dress codes are
  per group (Paramètres).
- [ ] Group-neutral app, what's left: the duty grid (posts per service size, côté cour/jardin) and
  the alb-washing rotation are still the Garde Suisse's. Next: per-group module switches
  (planning, aubes) and editable post names.
- [x] A member's status (actif, congé, suspendu…) is per group (2026-10-23).
- [ ] Tell the partner when an access request arrives (today: count in the back-office menu; the
  partner has no app). E-mail once an e-mail service is chosen.
- [ ] Back-office in English too (the app is bilingual; the back-office is French only for now).
- [x] Biometric unlock (fingerprint or face, Mon compte; 2026-10-23).
- [ ] Notifications (push).
- [ ] Mandate-expiry reminder 30 days before the end (a scheduled job; see
  `RENDER_STAGING.md` §3 for how jobs are added).
- [ ] Audit log export (CSV/PDF) and filters by author/module.

## Recently shipped

### 2026-10-20 — Foundation (v0.1)
Backend skeleton, phone + PIN login with lockout, roles and permission matrix with fixed rules,
audit log, back-office (2FA login, dashboard, users, roles matrix editor, audit log), Flutter
shell (login, role-based tabs), CI, Render Blueprint. See `BETA_CHANGES.md` §1–§5.
