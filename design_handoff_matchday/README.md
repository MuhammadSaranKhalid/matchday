# Handoff: matchday — cricket community app (mobile)

## Overview
**matchday** is a mobile-first social + utility app for amateur/club cricket in Pakistan & India
("gully", tape-ball, and club cricket). It combines a social feed, live scores you can follow,
player & team profiles, team management, match scheduling/challenges, and full tournament
organisation (create → register teams → seed → schedule → run → awards).

The design language is warm, calm, and editorial — paper-tone backgrounds, a single red accent,
restrained type, and lots of whitespace. It deliberately avoids loud "sports app" tropes.

---

## About the design files
The files in `prototype/` are a **design reference built as an HTML + React (Babel-in-browser)
prototype**. They show the intended **look, copy, layout, states, and interaction behaviour** —
they are **not** production code to ship as-is.

Your task is to **recreate these screens in the target codebase's environment** using its
established patterns, component library, navigation, and data layer. If there is **no existing
app yet**, pick an appropriate stack (e.g. React Native / Expo for mobile, or React + a router
for web) and implement the designs there. Treat the prototype as the source of truth for *what it
should look like and do*, and your codebase as the source of truth for *how to build it*.

> The prototype runs entirely client-side with hard-coded seed data and no backend. Everywhere it
> mutates local React state (follow toggles, likes, RSVPs, creating a team/tournament), the real
> app needs an API call + optimistic update. See **State & data** below.

### How to run the prototype locally
It uses in-browser Babel and relative `<script>` imports, so it must be served over HTTP (not
opened as a `file://`). From `prototype/`:
```
npx serve .          # or: python3 -m http.server
```
then open **`matchday Prototype.html`**. It renders inside a simulated iOS frame at a fixed
mobile width.

---

## Fidelity
**High-fidelity.** Final colours, typography, spacing, copy, and interaction states are all
intentional. Recreate the UI faithfully (within the constraints of the target platform's
components). The design tokens are defined once in `prototype/styles.css` — port them verbatim.

---

## Architecture at a glance

The app is a single shell with **3 bottom-nav tabs**, a **persistent top header**, and a stack of
**full-screen overlays** opened from the header avatar (a "Menu" drawer) and from cards/rows.

```
Shell  (matchday Prototype.html → function Shell)
├── GlobalHeader        avatar(→Menu) · Search pill(→Search) · Messages(→DMs)   [on every tab]
├── Bottom nav          Home · Matches · Alerts
│   ├── Home            window.HomeFeed              home-messages.jsx
│   ├── Matches         window.PublicMatches         public-matches.jsx   (browse/watch everyone)
│   └── Alerts          NotificationsTab             (inline in the HTML)
└── Overlays (absolute, inset:0, stacked by z-index)
    ├── Search          embed/search.html (iframe)   self-contained
    ├── Messages        window.MessagesScreen        home-messages.jsx
    ├── Menu drawer     MenuOverlay (inline)         → routes below
    │   ├── Profile     window.ProfileYou            profile-you.jsx     (+ Edit profile, Share)
    │   ├── My matches  MatchesTab (inline)          → Send Challenge (challenge-send.jsx)
    │   ├── My teams    SubPage + team cards         → Team create (team-create.jsx)
    │   ├── My tournaments                           → Tournament create (tournament-create.jsx)
    │   ├── Following / Saved / Rankings / Notifications / App theme / Language / Account
    │   └── Log out
    ├── Team page       window.CkTeamPage            screens/TeamPage.jsx (+ tp-*.jsx)
    ├── Tournament hub  window.TournamentHub         tournament-hub.jsx
    └── Match detail    window.MatchDetail / WatchMatch  (in pavilion-matches-v2 / public-matches)
```

### Module map (`prototype/`)
Each `.jsx` is a `<script type="text/babel">` that attaches its exports to `window` (no bundler /
imports). **Load order matters** — it's defined in the `<head>` of `matchday Prototype.html`.

| File | Exposes (`window.*`) | What it is |
|---|---|---|
| `styles.css` | — | **All design tokens** + base component classes (`.ck-*`). Port first. |
| `tweaks-panel.jsx` | tweaks UI | Prototype-only "Tweaks" panel. **Not part of the product — ignore for production.** |
| `ios-frame.jsx` | device frame | Prototype-only iPhone bezel/scaler. **Ignore for production.** |
| `challenge-shared.jsx` | shared atoms | Shared icons/util used by challenge + pavilion modules. |
| `challenge-data.jsx` / `challenge-send.jsx` | `SendChallenge` | **Schedule / challenge-a-team flow.** |
| `pavilion-data.jsx` | `PavData` | **Seed data**: CRESTS (teams), seedMatches, seedTeams, seedTournaments, ACCOUNT. |
| `pavilion-parts.jsx` | `PavParts` | Shared lanes/cards (teams lane, tournaments lane, account). |
| `pavilion-matches-v2.jsx` | match lane + `MatchDetail` | "My games" lane + match detail/watch screen. |
| `pavilion-app-v2.jsx` | pavilion glue | Older pavilion composition (mostly superseded by the new nav). |
| `home-messages.jsx` | `HomeFeed`, `MessagesScreen` | **Home feed** (posts) + **Messages** (threads). |
| `public-matches.jsx` | `PublicMatches`, `WatchMatch` | **Matches tab** (browse/watch) + **match detail** (tabbed). |
| `followers-screen.jsx` | `FollowersScreen` | **Followers / Following** list. |
| `profile-you.jsx` | `ProfileYou`, `EditProfile` | **User profile** (self/stranger) + **Edit profile** + Share sheet. |
| `team-create.jsx` | `TeamCreate` | **Create-a-team** wizard (4 steps + success). |
| `team-invite.jsx` | `TeamInvite` | **Invite players** flow (join code, WhatsApp/Copy, nearby/unclaimed). |
| `screens/tp-atoms.jsx`, `tp-tabs.jsx`, `tp-data.jsx`, `TeamPage.jsx` | `CkTeamPage` | **Team page** (all viewer states + tabs). |
| `tournament-create.jsx` | `TournamentCreate` | **Create-a-tournament** wizard (8 steps + created splash). |
| `tournament-hub.jsx` | `TournamentHub` | **Tournament hub** (all lifecycle states + Manage + Awards). |
| `embed/search.html` | — | **Search** overlay (self-contained; talks to shell via `postMessage`). |

---

## Navigation & global chrome

### Top header (Threads/IG-DM style) — on every main tab
- **Left:** round avatar (your initials, e.g. "MS") → opens the **Menu** drawer.
- **Center:** full-width **Search pill** ("Search") → opens the **Search** overlay.
- **Right:** **Messages** bubble icon, with a small red unread badge → opens **Messages**.
- Height 44px safe-area spacer above; row padding `4px 12px 12px`; bottom hairline.

### Bottom nav — 3 tabs
`Home · Matches · Alerts`. Active tab uses the red accent (icon + a filled "bat" tile treatment);
**Alerts** carries a numeric red badge. Tabs are kept mounted and toggled with `display` (state is
preserved when switching). Icons live in the `PATHS` object inside the HTML (`home`, `bat`,
`bell`, plus `search`, `msg`, `user`, `trophy`, `shield`, `pin`, etc. — 1.9px stroke line icons).

### Overlay pattern
Every full-screen surface (Menu, Search, Messages, Profile, Team page, Tournament hub, Match
detail, all wizards) is an absolutely-positioned `inset:0` layer with its own z-index, opened on
top of the tabs and dismissed with a **back arrow** in its header. **All overlay headers share one
structure: back arrow + left-aligned title + bottom hairline.** The back glyph is an arrow
(chevron + horizontal shaft: `M19 12H5  M12 19l-7-7 7-7`), borderless, ~20px, no box.

---

## Screens & flows (detailed)

### 1. Home feed — `home-messages.jsx` → `HomeFeed`
Vertical feed of posts under the global header. **No separate page title and no floating compose
button** (compose is a cue at the top of the feed).

**Post card:**
- Header row: author avatar (round for people, rounded-square crest for teams) · name · `@handle`
  · `· 12m` timestamp · **inline Follow pill** (only for accounts you don't follow; toggles
  Follow ⇄ Following) · `···` overflow.
- Body: text (with emoji), or a **match-result scoreboard card** (winner row emphasised), or a
  **milestone** badge, or a **recruitment** ("Looking for players") block.
- **Action bar:** 👍 **Thumbs-up** (count; fills red when active) · 💬 **Comment** ·
  ↗ **Share** (recognisable 3-node share glyph, right-aligned). **No save/bookmark, no repost.**
- **Inline top comment** preview + "View all N comments". Posts with zero comments show no preview.
- **`···` overflow** = a small **dropdown popover anchored under the button** (NOT a bottom
  sheet): `Mute · Copy link · Report`. (Follow is **not** in this menu — it's the inline pill.)
- **Share** opens a **WhatsApp-led share sheet** (WhatsApp first, then Copy link, etc.).
- Tapping the author opens the **user profile** (person) or **team page** (team).

### 2. Matches tab — `public-matches.jsx` → `PublicMatches`
Browse & watch **anyone's** matches. **No scheduling here.**
- Segmented pills: **Live · Following · Upcoming · Results** (live count badge + pulse dot).
- Matches **grouped by tournament/series** (collapsible group header: crest, name, `Following`
  tag, stage · city).
- **Live card:** LIVE chip + watcher count, both teams + scores, and a **chase-equation line**
  ("LL need 38 off 22"), with a **WATCH** affordance. Upcoming/Results render as compact rows.
- "View all fixtures" → opens that tournament's hub.
- Tapping a match → **match detail / watch screen**.

### 3. Match detail (watch) — `public-matches.jsx` → `WatchMatch`
- Header: back · "TSK vs WF" · **tournament breadcrumb** (name · stage) · watcher count.
- **Tabs:** Live · Scorecard · Commentary · Info (set varies by state: live vs result vs upcoming).
- **Hero scoreline** (dark `--ink` panel, soft red glow): LIVE chip; the **batting team's** score
  large; the **chase-equation hero** when chasing ("LAHORE LIONS NEED / 38 off 22 / REQ 10.4 · 6
  WKTS IN HAND") with both team mini-cards below (names truncate with ellipsis, `minWidth:0` so
  they never overflow). This-over **ball log** (per-ball pills: dot/4/6/W/extra — see `.ck-ball`).
- **Info tab**: venue, toss, officials, squads (XI), etc.

### 4. Alerts / Notifications — `NotificationsTab` (inline in HTML)
Notification feed (follows, requests, results, milestones). Red badge on the nav tab.

### 5. Search — `embed/search.html` (iframe overlay)
Loaded in an `<iframe>`; communicates with the shell via `postMessage`
(`mdProfile` → open menu, `mdCloseSearch` → close). **One unified search field** (no Teams/Players
toggle): typing returns results in labelled **TEAMS** and **PLAYERS** sections. Browse state shows
**Near me**, **Browse by city**, recent teams, suggested players. Per-row **Follow** toggles.
Round avatars for people, rounded-square crests for teams, verified ticks. Header = back arrow +
the search field only (back closes the overlay).

### 6. Messages — `home-messages.jsx` → `MessagesScreen`
Threads list with **All / Teams / DMs** tabs (counts), team crests vs person avatars, unread
badges, italic system lines ("Faisal joined"). Tapping a thread opens it. Back arrow returns.

### 7. Menu drawer — `MenuOverlay` (inline in HTML)
CREX-style account drawer opened from the header avatar. Structure:
- **Profile** header row (avatar, name, `@handle`, "View profile") → opens Profile.
- **My stuff:** My matches · My teams (count) · My tournaments (count).
- **Activity:** Following · Saved · Rankings.
- **App settings:** Notifications · App theme (Light) · Language (English) · Account & privacy.
- **Log out.**
Sub-pages (My teams, My tournaments, etc.) use the shared `SubPage` chrome (back + title + border)
and each carries its **creation FAB** (e.g. My teams → **+ New team** circular-plus FAB).

### 8. Profile — `profile-you.jsx` → `ProfileYou`
Header matches every other page (back arrow + "Profile" + border; gear/settings on the right for
your own profile). Lean, captain-led layout, **rendered from `profile` state** so edits persist:
- name → `@handle` → location → **role line** (e.g. "ALL-ROUNDER", single-line pill) →
  **bio/tagline** → quiet **"284 followers · 92 following"** line → action buttons → **Captains /
  Plays for** team chips → posts.
- **Bio** has 3 modes: **written** (free text the player writes), **empty** (self sees "+ Add a
  bio" pill), **fallback** (stranger sees a structured line auto-composed from data).
- **Viewer states:** *self* → Edit profile / Share + gear + compose FAB; *stranger* → Follow ⇄
  Following + Message.
- **Edit profile** (`EditProfile`): avatar colour (8 swatches) + camera affordance, name,
  username, location, bio, role; Save writes back to state. **Share** opens a share sheet.
- Tapping **followers/following** counts → **Followers screen**. Team chips → that team's page.

### 9. Followers / Following — `followers-screen.jsx` → `FollowersScreen`
Header: back + centered name/handle. **Big-count segmented tabs** (number stacked over label:
`284 / FOLLOWERS · 92 / FOLLOWING`, active underlined). Per-tab **search**. Rows: avatar, name,
`@handle`, **"FOLLOWS YOU"** tag (single line), and a **Follow / Following** toggle (Followers tab
shows "Follow back").

### 10. My matches — `MatchesTab` (inline in HTML)
Your **own** games + scheduling (distinct from the browse-everyone Matches tab; intentionally
re-skinned to match it). Header "My matches". **Upcoming / Completed** pills (live dot when a game
is live). Grouped into **Friendlies** and **Tournament & League** sections. Cards mirror the
Matches-tab aesthetic: status chip (LIVE / STARTS SOON / SCHEDULED / AWAITING REPLY / WON / LOST),
both team crests + scores, venue (pin) + date footer. **+ Schedule match** FAB → Send Challenge.

### 11. Send Challenge — `challenge-send.jsx` → `SendChallenge`
Schedule a friendly or open challenge: pick opponent (or open challenge), date/time, venue,
squad/lineup. On send, a new match is prepended to "My matches" (scheduled/awaiting).

### 12. My teams + Team creation
- **My teams** sub-page: team cards (role tag captain/owner/player, record, "needs" items),
  **+ New team** FAB.
- **Team creation** — `team-create.jsx` → `TeamCreate`: 4 steps + success —
  ① Name (live crest preview, auto-monogram, 40-char limit) → ② Colour → ③ Home ground/city →
  ④ Invite (join code) → **Success** ("Go to team page").

### 13. Team page — `screens/TeamPage.jsx` → `CkTeamPage` (+ `tp-atoms`, `tp-tabs`, `tp-data`)
The standalone team profile. **Viewer states:** owner · captain · player · stranger · following.
- Hero: crest, name, city/area, record, verified.
- **Tabs:** Squad · Matches · Stats · About.
- **Action buttons by state:**
  - *Stranger* → **Follow** + Request to join + Message.
  - *Following* → **Notify** toggle appears (notify on/off for this team's updates) + Following.
  - *Owner/Captain* → **Post as team**, **Invite players** (→ Team invite), Captain inbox, Lineup.
    (No separate "Manage" button — actions are inline.)
- All hero buttons are wired to real handlers (follow/notify/message/invite/post).

### 14. Team invite — `team-invite.jsx` → `TeamInvite`
Join code + **WhatsApp / Copy** share, **Add nearby**, **Add unclaimed** player.

### 15. My tournaments + Tournament creation
- **My tournaments** sub-page: tournament cards (organising vs playing; status), **+ New
  tournament** FAB.
- **Tournament creation** — `tournament-create.jsx` → `TournamentCreate`: **8-step wizard** —
  structure → name → format → settings → entry/fee → when & where → visibility → review →
  **Create** → **CREATED · DRAFT** splash → "Go to tournament" lands in the hub.

### 16. Tournament hub — `tournament-hub.jsx` → `TournamentHub`
The organiser/participant home for one tournament. **Lifecycle states** drive the UI:
`draft → registration → ready → seed → schedule → in-progress → completed`.
- **Tabs:** Overview · Matches · Bracket · Teams · Standings · **Awards** (completed only) ·
  **Manage** (organiser only).
- **Overview** is the default landing: featured matches + **Key stats** (Most runs / Most wickets /
  Best economy) + leaders.
- **Draft desk** has a clear path forward: **Add teams** + **"Seed, schedule & go live"** which
  launches the chain *Generate draw → Preview bracket → Schedule fixtures → Go live*. Before
  go-live the in-progress-only tabs/actions are hidden to avoid confusion.
- **Manage** (organiser) is a navigable hub → sub-screens: **Requests** (approve/decline join
  requests), **Teams** (roster, mark paid), **Fee** (track-only — organiser marks cash paid; **no
  payment processing**), **Result** (enter match results).
- **Bracket**: knockout/league/hybrid; QF/SF/FINAL columns with proper vertical spacing; clear
  empty state when no teams have joined yet.
- **Awards** (completed): champions hero, final standings 1/2/3, three player awards.
- See **`reference/Tournament Lifecycle.html`** for the full 5-phase storyboard (Draft →
  Registration → Seed the draw → Schedule fixtures → Live) and the money/status vocabulary.

---

## State & data (what needs a backend)
The prototype holds everything in React `useState`, seeded from `pavilion-data.jsx` (`PavData`).
For production, replace each local mutation with an API call + optimistic UI:

- **Identity / profile**: `ACCOUNT`, editable profile fields (name, handle, location, bio, role,
  avatar colour). Bio mode (written/empty/fallback) is derived from whether bio text exists +
  viewer.
- **Social graph**: follow/unfollow (players & teams), "follows you", notify-on-team toggle,
  followers/following lists & counts.
- **Feed**: posts (types: text / result / milestone / recruitment), like (thumbs-up) count + my
  state, comments (top comment + list), mute, report, share.
- **Teams** (`CRESTS`, `seedTeams`): create, colour, home ground, squad/roster, roles
  (owner/captain/player), join requests, invites (join code), "post as team", record/stats.
- **Matches** (`seedMatches`): phases `live | startsSoon | scheduled | awaitingReply | completed`;
  fields `team, opp, when, venue, sub, scoreA, scoreB, result, lineupSet`. Schedule/challenge,
  RSVP, set lineup, start, withdraw/cancel, live ball-by-ball, result.
- **Tournaments** (`seedTournaments`): lifecycle state machine (above), format (knockout/league/
  hybrid), entry fee (track-only paid flag), team registration & approval, seeding, fixtures,
  standings, awards.
- **Messages**: threads (team/DM), unread counts, system messages.
- **Notifications**: typed alerts + unread badge.

---

## Design tokens (port verbatim from `prototype/styles.css`)

**Colours** (OKLCH — keep OKLCH if your platform supports it; otherwise convert to the nearest hex):
- Ink/text: `--ink oklch(0.18 0.02 80)`, `--ink-2 0.30`, `--muted 0.52`, `--soft 0.72`
- Surfaces: `--paper 0.985 0.008 85`, `--paper-2 0.965`, `--surface 0.99`, `--line 0.90`,
  `--hairline 0.93`
- Accent red: `--red oklch(0.62 0.19 28)`, `--red-soft 0.92 0.05 28`
- Green: `--green 0.56 0.13 148`, `--green-soft 0.92`, `--green-ink 0.34`
- Amber: `--amber 0.78 0.14 80`, `--amber-ink 0.46 0.11 75`, `--cream 0.94 0.05 90`

**Radii:** `--r-sm 8 · --r-md 14 · --r-lg 20 · --r-xl 28`. (Crests use rounded-square ≈ `size*0.26`;
avatars are full circles `999px`.)

**Shadows:** `--shadow-1` (subtle card), `--shadow-2` (raised/sheet).

**Type families:** display **Inter Tight** (700/800, `letter-spacing -0.02em`), body **Inter**
(400–700), mono **JetBrains Mono** (tabular numbers for scores). Loaded from Google Fonts.

**Type scale (calm hierarchy — hierarchy comes from weight + whitespace, not size):**
screen title **20 / 700** · section header **15** · card title **14** · body **13** ·
meta **11** · eyebrow **10 mono** · large scores use mono tabular. See
**`reference/Design System.html`** for the live ladder and component specimens.

**Motion:** `ck-pulse` (1.4s live dot), spring/pop on toasts & button press (`transform: scale`).
Keep transitions short (~80–150ms). Respect `prefers-reduced-motion`.

**Iconography:** inline SVG line icons, 1.8–2px stroke, round caps/joins, 24-box. Crests show a
2-letter monogram on the team colour.

---

## Assets
- **No raster image assets** — everything is CSS, inline SVG icons, and monogram crests. Real app
  should support uploaded team crests/logos and user avatars (the prototype uses coloured
  monograms as placeholders; `image-slot`-style upload targets in the real app).
- **Fonts**: Inter Tight, Inter, JetBrains Mono (Google Fonts). Bundle or self-host for production.
- **Reference sheets** (`reference/`): `Design System.html` (tokens/type/components),
  `Tournament Lifecycle.html` (organiser flow storyboard). These are documentation, not app code.

## Prototype-only — do NOT port
`tweaks-panel.jsx`, `ios-frame.jsx`, the in-browser Babel/React CDN scripts, the `<deck>`/scaler
chrome, and the iframe-embed mechanism for Search are **prototype scaffolding**. In a real app,
Search is just another screen/route, not an iframe; and there's no device frame.

## Files
- `prototype/matchday Prototype.html` — the shell (nav, header, overlays, routing) + the inline
  components (`MenuOverlay`, `NotificationsTab`, `MatchesTab`, `SubPage`, `Shell`). **Start here.**
- `prototype/*.jsx` + `prototype/screens/*.jsx` — feature modules (see Module map).
- `prototype/styles.css` — design tokens. **Port first.**
- `prototype/embed/search.html` — Search overlay.
- `reference/Design System.html`, `reference/Tournament Lifecycle.html` — documentation.
