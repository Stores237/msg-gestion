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
| 2026-10-26 | Authors edit and delete their own announcements and events (managers still can for any); Modifier · Supprimer under the item, delete confirmed | Owner |
| 2026-10-26 | Mon compte → Aide / À propos (FAQ in app; partner contacts and legal texts from back-office → Plateforme); red Log out | Owner’s reference screenshot |
| 2026-10-26 | Conditions of use accepted at login: checkbox on the phone-number screen with a link to the text; enforced by the server per version; a new text is accepted again at the next login | Owner. Unticked Continue explains itself in words rather than greying the button |
| 2026-10-26 | Security check: real client address for rate limits, offline copy erased on sign-out / account change, Android backup off, API docs for the back-office only | SECURITY.md "Security check — 2026-10-26" |
| 2026-10-27 | "Autre" named by the author; Messe intérieure / extérieure (Service extérieur retired), Extérieur in amber; per-type switches in Paramètres | Owner. Amber = the existing warn tone, so the difference reads at a glance without a new colour |
| 2026-10-27 | Chef de groupe designated with the event (not meetings), moved from the service lineup to the event; report within 24 h of the end, in the app or as PDF, to the formateur with formateur adjoint, secrétaire général, censeur général, vice-censeur in copy | Owner. No design existed: the screens reuse the event form, detail cards, badges, member picker and the announcement composer. Late reports are accepted but marked and locked rather than refused, so the formateur still gets them |
| 2026-10-27 | A report is locked the first time a bureau reader opens it (not the chef); the chef is told | Owner: "don't allow modify after a board member has opened it" |
| 2026-10-27 | Roll call of an event with a lineup lists only the lined-up guards and the chef, each with a post chip; others see "pas de service" | Owner. Chips reuse Badge2 (green for chef de groupe, neutral for the post) |
| 2026-10-27 | Planning drag and drop: free cell = move, filled cell of the same service = swap, other service = checked like a new assignment; target lit in the app colour ("Déposer ici") | Design ("Maintenir pour glisser ; la case cible s’éclaire") |
| 2026-10-27 | Leave per group with an optional end date (back-office), shown wherever leave shows; automatic return after it | Design ("En congé jusqu’au 15 novembre"); per group because status is per group |
| 2026-10-27 | Swaps and absences validated by the event's chef de groupe (own events) as well as the lineup makers | Design ("Validation : …, chef de groupe"; "le chef de groupe ou le censeur valide") |
| 2026-10-27 | Dress "Détail" and place detail written by each group, no default text | Design shows one group's wording ("Aube blanche, cordon…"); the platform serves several groups |
| 2026-10-28 | "Propulsé par STORES" with an "S" mark in the text colour (inverted in dark mode), small, at the foot of login, Mon compte and the back-office sidebar, with the version | Owner. Kept out of the group's colour so it never reads as a group's identity |
| 2026-10-28 | Mon compte → Stockage et données (storage, network usage, data saver, photo quality, auto-download per network), only what applies to MSG | Owner's reference: the phone's Storage and data screen. Proxy and roaming left out |
| 2026-10-28 | Back-office sidebar: menu scrolls, account + signature pinned at the bottom | Rendered check: the footer (and log-out) was cut off under ~900 px |
| 2026-10-28 | Announcement photos: one landscape 4:3 frame (framed by the author), ≤ 2 MB, 4 per announcement, checked by the server; files are PDFs | Owner: "respect a particular frame and MB". One frame keeps the feed even; 4:3 matches phone photos |
| 2026-10-28 | Grey "Expiré" chip on events that are over and on convocations whose date has passed | Owner. Neutral tone: past, not an error |
| 2026-10-28 | Back-office shell: sectioned sidebar with hover/active bar, foldable icon rail, "Aller à…" palette (Ctrl/⌘ K), toasts, busy buttons, sticky top bar, page fades; reduced motion honoured | Owner: "more modern and smooth". Built on the design's tokens in a stylesheet loaded last (bo-modern.css), so the design files stay untouched |
| 2026-10-28 | Back-office account menu at the foot of the sidebar: theme (light/dark/device), site, change password, account security, log out in red | Owner's reference screenshot. Theme kept per browser; password change ends the other sessions |
| 2026-10-28 | Back-office user page: "Modifier" on the Identité panel (dialog), phone changed apart with a reason (✎ next to the number) | Owner asked why details couldn't be edited; the design showed the panel read-only. The number is the login, so it gets its own confirmation, warning and sign-out |
| 2026-10-29 | Announcements/convocations: "Notifier" picks tagged members (multi-select sheet, chips); only they are notified, everyone still sees it; "POUR VOUS" badge (amber), "@ Pour :" line, "Pour moi" filter | Owner. Replaces the fixed "Tous les membres" row of the design's composer, in the same row style; amber so "for you" stands out without reading as an error |
| 2026-10-29 | Photo viewer: an announcement's photos stacked vertically (opened at the tapped one, tap to zoom); notifications for tagged members keep the announcement's title with a small "@ Pour vous" mark; Accueil "Dernières annonces": 3 newest as compact rows | Owner screenshots. Compact rows so three fit on Accueil; the mark is text, not a badge, so it never pushes the title onto two lines |
| 2026-10-29 | Announcement photos: one 4:3 carousel (swipe, auto-advance every 4 s, loops, "n/N" chip and dots, paused by touch, off with reduced motion); full screen side by side with zoom. Accueil: pinned first (pin icon), then 3 newest others | Owner, reversing build 22's vertical stack. Auto-advance respects the accessibility setting; a jump (not a slide back) after the last photo |
| 2026-10-29 | Role duration: chip "Durée N mois" / "Sans fin" by the role name, "Durée" ghost button (clock) opening a dialog (months + reason); duration required on "Nouveau rôle" | Owner: only the 2 super admins hold a role with no end; Membre kept open-ended as it is the membership, not a post |
| 2026-10-29 | Downloads: download icon in the full-screen photo viewer; PDFs download, copy to Download/MSG and open in the phone's viewer; Mon compte → Téléchargements (list, ⋮ save to phone / delete); photos seen kept on the phone (150 MB) for offline | Owner: download a photo or a PDF report, and view offline what was downloaded or seen. Copies keyed by the file's address without its signature so a new signed link finds them |
| 2026-10-29 | App colour: back-office picker as one partial (swatches + Autre… write one hidden field per colour, Dégradé checkbox with a second row, live Aperçu); app Apparence gets Autre couleur… (hue + shade, lightness kept 20–45 %) and a Dégradé switch; Accueil header is a 135° gradient | Owner: palette had to be changeable, and gradients. Lightness clamp keeps white text readable; a gradient header is darkened less (60 % colour) so both colours show |
| 2026-10-30 | One phone at a time: the newest sign-in wins; the old phone returns to the login screen with a warning notice saying the account was opened on another phone | Owner chose "new phone wins" over refusing the second phone: a lost phone must never lock the member out |
| 2026-10-30 | Planning week: drafts on top ("Brouillons à publier"), published lineups below ("Publiés") with a Réutiliser button (sheet of upcoming events without a lineup); past drafts show "Date passée" in the warn colour, a warn notice, and the publish bar reads "Date passée" | Owner: published lineups go down and can be reused; the date matters, a past lineup can't be published and the planner is told why |
| 2026-10-30 | Finances: the validate dialog gets a "Modifier" button; edited lines carry a neutral "Modifié" badge and "modifié par …" in the trail; "À finaliser" amber badge and a Finaliser / Renvoyer dialog (reason box) for the commissaire; Membres opens a check-box list with a bold "Tout cocher" row on top and an "OK (n)" footer; "N membres × montant = total" notice; Autre's description label reads "Description (obligatoire)" | Owner: edit before validation with the two steps kept, members required and ticked with check-all, Autre described. Edit sits in the trésorier's validate right because the two-hands lock forbids him "change" |
| 2026-10-30 | Cash book card: member (or description) + amount on line one, category (+ description only if different) below, trail, badges, then compact Modifier (outlined) / Valider / Finaliser (filled) buttons; "Grouper par" chips (Jour, Type, Statut, Membre) on one scrolling line; group header = title, "N opérations", net total, fold chevron | Owner's screenshot: the category was repeated as the title and the edit was hidden behind a tap. Buttons make the trésorier's actions visible; grouping by day answers "who paid on that date" |
| 2026-10-30 | Finances mutual: trésorier and commissaire both enter and approve; a line needs the one who didn't enter or last change it. The line shows "En attente de l'autre" (neutral) to its author, Valider to the other; long press picks lines (check circles replace the icon), a bottom bar "N sélectionnées · Tout sélectionner · Valider (N)" replaces the + Opération button; a hint "Appui long…" above the list | Owner: the trésorier keeps the money, the commissaire audits; they align on every operation. The trésorier records what he collects; whichever enters, the other agrees. Replaces the 2026-10-23 split (commissaire enters, trésorier validates) and the same morning's "À finaliser" step for new lines |
