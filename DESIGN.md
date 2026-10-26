# Design

Source: Claude Design project "MSG Gestion" (`design/MSG Gestion.html`, `design/MSG Back-office.html`).
Those pages are the reference for every screen. The code's token values are the source of truth
if this file and the code disagree; fix this file in the same change.

## Tokens

Spekooh design-system components, with its variables redefined on the movement's green
(`design/msg-theme.css`). No gradients: the primary gradient token is a flat green. One alert
colour.

| Role | Token | Light | Dark |
|---|---|---|---|
| Primary | `--msg-green-500` | `#2E7D46` | `#2E7D46` |
| Primary text | `--msg-green-600` | `#256A3A` | `#7CC795` |
| Primary tint | `--msg-green-100` | `#DCEBE0` | `#1E3426` |
| Background | `--surface-bg` | `#F6F3EE` | `#151412` |
| Surface | `--surface-card` | `#FFFFFF` | `#1F1D1A` |
| Sunken surface | `--surface-sunken` | `#F1EDE6` | `#282521` |
| Hairline | `--border-subtle` | `#E3DDD2` | `#35322D` |
| Text | `--text-primary` | `#262420` | `#F1EDE6` |
| Secondary text | `--text-secondary` | `#5F5A52` | `#BDB6AA` |
| Tertiary text | `--text-tertiary` | `#736C61` | `#A39C90` |
| Alert | `--red-500` | `#B3502B` | `#E5845F` |
| Attention | `--amber-600` | `#7A5A12` | `#E0BE73` |

Type: Plus Jakarta Sans. Display 28/800, Title 1 22/800, Title 2 19/800, Title 3 17/800,
Body 16/400 (forms), List title 15/700, Small 13/400, Label 12/700 caps +0.06em. Tabular figures
for every amount, time and counter.

Spacing on an 8-pt grid; touch targets ≥ 48 dp (tabs 56, attendance buttons 44 with 4 gap).
Radii: sm 8, md 12 (fields, chips), lg 18 (cards), xl 22 (dialogs), pill (buttons, filters).

Where they live in code: `app/lib/theme/tokens.dart` + `app_theme.dart` (Flutter);
`backend/static/backoffice/tokens.css`, `msg-theme.css`, `bo.css` copied from the design, plus
`ds.css`, the server-rendered equivalents of the design-system React components.

## Decision log

| Date | Decision | Why |
|---|---|---|
| 2026-10-20 | Back-office is server-rendered Django templates reusing the design's own CSS files unchanged; DS React components re-expressed as CSS classes in `ds.css` | One deployable service, no frontend build; the design's CSS stays diffable against `design/` |
| 2026-10-20 | Back-office pages fill the window; the design's mock browser chrome (`.bo-chrome`) isn't rendered | It's presentation for the design document, not part of the product |
| 2026-10-20 | Bureau mandate default end = start + 24 months − 1 day (e.g. 01/10/2025 → 30/09/2027) | The user table in the design uses 2 years; the AssignDialog example (01/10/2026 → 30/09/2027) contradicts its own "2 ans" label and was treated as a typo |
| 2026-10-20 | App tab bar uses Material `NavigationBar` themed to the tokens, not the DS `BottomNav` | Native accessibility and TalkBack labels; same tabs, icons and colours |
| 2026-10-20 | App icons: Material Icons equivalents of the design's Lucide icons | Avoids a third-party icon font for v0.1; revisit if the shapes matter to the owner |
| 2026-10-20 | Fingerprint key on the PIN pad shown but disabled | Matches the design layout; biometric unlock not built yet (TODOS.md) |
| 2026-10-20 | App defaults to French; English only when the phone is set to English | The movement works in French; the playbook requires every string in both locale files |
| 2026-10-20 | Logo = the letters "MSG" in white on the primary green, rounded square (`app/lib/widgets/msg_logo.dart`, `.msg-logo` in `ds.css`); replaces the design's dashed placeholders | Owner's choice. One widget/class, so a drawn logo later is a one-file swap |
| 2026-10-23 | Added roles Vice-président (président's rights minus validating the quarterly report) and Secrétaire général adjoint (same as the SG), bureau, 2-year mandate | Owner request; the design mentions the SG adjoint but had no vice-president. Editable in the back-office |
| 2026-10-23 | Lineup made only by the formateur / formateur adjoint; président and vice-président exceptionally (audited, formateurs notified) | Owner rule. Enforced as a locked cell per role, not per person, so holding "membre" too never removes it |
| 2026-10-23 | Chef de groupe designated per service among its guards; standing role archived | Owner: "everyone can be chef de groupe", decided when the lineup is made |
| 2026-10-23 | Roles of the day: any role except super admin, for one day, assigned by the super admin | Owner: more inclusive; censeur du jour and bureau roles rotate per activity |
| 2026-10-23 | Back-office usable on phones: drawer menu under 820px | Owner: primarily desktop but accessible on every device. The design hid the sidebar with no replacement |
| 2026-10-23 | Commissaire aux comptes: every finance right, own entries validated on entry; trésorier read + download only | Owner rule, replacing the design's "le trésorier saisit, le commissaire valide". With one person entering, a second validation step would block every line |
| 2026-10-23 | Members' balance statement (bilan général / individuel), PDF in the app, PDF + CSV in the back-office | Owner: commissaire and trésorier download it for all members or one. "Versé" counts validated payments only |
| 2026-10-23 | Back-office opens to finance roles, showing only "Bilan financier" | Owner: "add it on back office". The menu follows the permissions; the super admin still sees no amounts |
| 2026-10-23 | Super admin: every right and every figure (finances on the dashboard) | Owner: "should be able to do everything and see everything". Replaces the design's masked amounts |
| 2026-10-23 | Super admin accounts work only in the back-office, never in the mobile app | Owner rule. Refused after a correct PIN so the refusal doesn't reveal who is super admin |
| 2026-10-23 | Finances in two hands: commissaire aux comptes enters, trésorier validates (and signs off the quarter) | Owner: the trésorier holds the money, so he confirms the figures match it. Replaces the commissaire-validates rule of the same day |
| 2026-10-23 | Back-office for super admins only; group officers work in the app | Owner: the platform will serve other groups; the back-office administers the platform, not one group |
| 2026-10-23 | Group-neutral wording in login help, errors and the back-office | Same reasoning. Group facts come from Paramètres |
| 2026-10-23 | MSG is the platform's name; one platform for several groups (option B) | Owner. One account per phone number, memberships per group, roles per group |
| 2026-10-23 | Group scoping in default managers (current group from X-Group / back-office session) | Safer than filtering by hand in every query: a forgotten filter can't leak another group's data |
| 2026-10-23 | Access process: leader requests in the app → partner (super admin) creates in the back-office → temporary PIN shown once to the leader → member signs in and sees their role | Owner. Replaces direct registration in the app |
| 2026-10-23 | Welcome message per group, on Accueil | Owner |
| 2026-10-23 | Activity types and dress codes per group, edited in Paramètres; defaults translated, the group's own wording shown as written | Owner ("move it to editable settings") |
| 2026-10-23 | Member status per group (Membership.status); suspending in the back-office acts on the current group only | Owner: on leave in one group, active in another |
| 2026-10-23 | Accueil header: dark band in a deep shade of the app colour, greeting by time of day, FR/EN, Apparence, bell, role as a gold chip, diamond row | Owner's reference screenshot |
| 2026-10-23 | App colour per group (back-office), overridable per phone in the app; every green token derived from one seed (`MsgColors.fromSeed`) | Owner: "the in-app color should be modifiable" |
| 2026-10-23 | Screen header actions pinned right, round tonal buttons | Owner: top buttons drawn mid-screen |
| 2026-10-23 | Group edit in a dialog on Groupes; deletion by two super admins (ask + confirm by another, name typed back, 3-day window); the group is hidden with its data kept and can be restored | Owner: "double validation by the 2 admin", then "hide the group and keep its data" |
| 2026-10-23 | Every member sets or removes their own profile picture (Mon compte), shown on Accueil; officers keep setting others' | Owner |
| 2026-10-23 | Roles of the day requested in the app for an active member with no role (président, censeur, secrétaire, formateur, commissaire, trésorier du jour), approved by the partner; per-role switch `daily` | Owner |
| 2026-10-23 | App lock: PIN on every reopening and after 2 min in the background, checked offline against a salted hash; fingerprint/face optional (Mon compte); 5 wrong → signed out | Owner |
| 2026-10-26 | Every bureau role posts announcements and acts on the calendar; the author’s role is saved with the post and shown | Owner |
| 2026-10-26 | Back-office staff: support, IT helpdesk, integration ops × agent/responsable, platform roles with per-area back-office permissions and fixed limits; Équipe and Intégrations pages | Owner |
| 2026-10-26 | Mon compte → Aide / À propos (FAQ in app; partner contacts and legal texts from back-office → Plateforme); red Log out | Owner’s reference screenshot |

