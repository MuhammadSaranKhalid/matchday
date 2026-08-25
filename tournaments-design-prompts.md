# MatchDay Tournaments — Design Prompt Pack

Ten prompts, meant to be pasted **in order, into one continuous design conversation**.

- **Prompt 0** is the master context. Paste it first and never again — everything after
  it says "per the master context."
- **Prompts 1–9** are one design pass each. Do them in order; each builds on the last.
- If your design tool loses context between sessions, re-paste Prompt 0 at the top of the
  new session before continuing.

| # | Pass | Produces |
|---|---|---|
| 0 | Master context | (no artboards — the foundation everything else references) |
| 1 | IA + component sheet | Where tournaments live; the reusable parts |
| 2 | Hub + discovery | My Tournaments, browse//filter, tournament cards in situ |
| 3 | Tournament detail | Overview · Fixtures · Standings · Bracket · Teams · Stats |
| 4 | Bracket + standings deep dive | The hard problem: a knockout tree on a 390px phone |
| 5 | Create wizard | Organizer authoring, draft → published |
| 6 | Organizer console | Registrations, seeding, fixtures, live-day ops |
| 7 | Team registration | Manager registers a team, picks a squad, tracks status |
| 8 | Completion + awards | Champion moment, awards, shareable card |
| 9 | States + system | Empty, loading, error, notifications, edge cases |

---
---

# PROMPT 0 — Master context (paste this first)

You are designing the **Tournaments** feature for **MatchDay**, a mobile cricket app
(Flutter, iOS + Android, **light theme only**). This is a large feature and we will design
it over several passes. This first message is context only — **do not produce any design
yet.** Read it, confirm you have it, and wait for the first design pass.

## 1. The product

MatchDay is where amateur and grassroots cricketers organise and play: you create a team,
add players (including "unclaimed" players who have no app account), challenge another team
or post into an open pool of fixtures, then score the match ball-by-ball on the phone.

**Tournaments are the next feature.** Today a local organiser runs a weekend cup on
WhatsApp and a paper bracket. We want the whole thing in the app: create the tournament,
take team registrations, seed and generate fixtures, run match days, keep a live points
table and bracket, and crown a champion.

The tournament backend already exists (tables, registration approval, standings storage,
live standings broadcast). What we do not have is a single screen.

## 2. Brand & design tokens (authoritative — use these exact values)

The brand line: **"One ink · one earned red · warm paper."** Warm off-white surfaces, warm
near-black text, and exactly **one** accent — Cricket Red — spent only on live, destructive
or active moments. Green and amber are functional status colours only, never decoration.

### Colours

| Token | Hex | Use |
|---|---|---|
| `ink` | `#29251E` | Primary text, primary icons |
| `ink2` | `#4A4339` | Secondary text |
| `muted` | `#8A8170` | Tertiary text, meta, chevrons, disabled labels |
| `soft` | `#B9B1A2` | Inactive glyphs, placeholder text |
| `paper` | `#FBFAF6` | Page background |
| `paper2` | `#F3F0E9` | Recessed fills: chips, buttons, avatar fallbacks |
| `surface` | `#FFFFFF` | Elevated surfaces |
| `line` | `#E6E2D9` | Input borders, stronger separators |
| `hairline` | `#EEEBE3` | 1px dividers and card borders (the default) |
| `red` | `#DC4D32` | **Cricket Red** — LIVE, destructive, active |
| `redSoft` | `#F7E6E1` | Tint behind red text |
| `green` | `#338946` | Status only — won, confirmed, approved |
| `greenSoft` | `#CFEED2` | Status tint |
| `amber` | `#E6AC3D` | Status only — pending, awaiting |
| `cream` | `#F4ECDD` | Seam Cream — amber-tinted chip background |
| `creamBorder` | `#DED0AC` | Border for cream chips |

Text **on** the tints: on `redSoft` → `#8C2218`; on `greenSoft` → `#1E5A2C`; on `cream` → `#6B5414`.

Shadows — only these two exist, do not invent more:
`shadow-1: 0 1px 2px rgba(40,30,15,.04), 0 1px 1px rgba(40,30,15,.03)`
`shadow-2: 0 8px 28px rgba(40,30,15,.07), 0 2px 6px rgba(40,30,15,.04)`

Radii: `sm 8` · `md 14` · `lg 20` · `xl 28` (px/dp). Scrim over content: flat `ink` at 32%, no blur.

### Typography — three bundled families, three roles

| Role | Family | Rules |
|---|---|---|
| **Display** | `Inter Tight` | Names, titles, row labels, scores. Default weight 700. Letter-spacing **-0.02em × font-size**. |
| **Body** | `Inter` | Sentences, buttons, subtitles. Default weight 400. |
| **Mono** | `JetBrains Mono` | UPPERCASE eyebrows, stat lines, tabular numbers, status pills. Weight 600, letter-spacing **+0.14em × font-size** (≈ +0.10em for uppercase labels). |

Sizes already established in the app: screen title `display 26` · card title `display 17/700`
· row label `display 14.5/600` · dialog title `display 18/700` · body `body 13.5` ·
subtitle `body 11.5 muted` · mono eyebrow `mono 10/700 +0.10em muted UPPERCASE` ·
status pill `mono 9/700` · footer legal `mono 9`. **Scores and any column of numbers use
tabular figures.**

### Existing components you must reuse rather than reinvent

- **Status pill** — padding `7×3`, radius 4, `mono 9/700` uppercase. Tones: red (solid red
  bg / white text), red-soft, green-soft, cream/amber, ink (solid ink / paper text),
  neutral (`paper2` bg / `muted` text).
- **Team crest** — rounded square, radius = size × 0.28, team's colour as fill, two-letter
  monogram in `Inter Tight 700` at size × 0.4, white. Falls back to monogram when there's
  no uploaded logo. Standard sizes 22 / 28 / 36 / 48.
- **Player avatar** — circle, network image or `paper2` fill + `hairline` border + two-letter
  monogram in `display` at size × 0.36, colour `ink2`.
- **Card** — `paper` fill, radius 14, 1px `hairline` border, no shadow by default.
- **Row** — 56dp tall, 20px horizontal padding, `[icon 22] 14px [label display 14.5/600]
  [trailing state] 6px [chevron 18 muted]`.
- **Screen header** — title in `display 26` on the left, 36×36 circular buttons on the
  right (`paper` fill, `hairline` border, 17–18px glyph). Pushed screens get a 36×36
  circular back button in the same style on the left.
- **Icons** — inline SVG, 24 viewBox, **stroked**, `stroke-width 1.8`, round caps and
  joins, geometric, no fills. If you need a new glyph, draw it in this language and give
  me the raw path data.
- **Loading** — shimmer skeletons shaped like the real content. **Never spinners.**

## 3. The app's information architecture (this constrains where tournaments go)

- **Bottom nav has four tabs: Home · Explore · Matches · Pool.** This is a settled
  decision; there is no fifth slot and tournaments will not get one.
- The organising rule is: **"Bottom nav is the world. Side panel is you."** A left side
  panel (drawer) holds *your* things — your matches, your teams, your pool requests — and
  already contains a **disabled "My Tournaments — Soon" row that this feature activates.**
- A second rule governs the side panel: **it is nouns only, no verbs.** You go to a place;
  the place owns its own create button.
- **Explore** is unified search + discovery (teams, players, matches). It has a Tournaments
  group that is currently switched off because the table is empty.
- **Matches** tab shows everyone's matches — live, upcoming, recent.

So a tournament is reachable three ways, and you should design for all three: from the side
panel (mine), from Explore (discover), and from a match that belongs to one.

## 4. Roles — every screen must be designed per role

| Role | Who | Can |
|---|---|---|
| **Organizer** | Creator + an `organizers` list | Everything: create, edit, approve/reject registrations, seed, generate and publish fixtures, assign scorers, reschedule, declare walkovers, abandon, submit awards |
| **Team manager / captain** | Manages a registered team | Register the team, pick the squad, withdraw, see their fixtures |
| **Player** | In a registered squad | Read; sees their own fixtures and stats |
| **Follower / spectator** | Anyone | Read public tournaments; follow for updates |

The same screen (say, Tournament Detail) must be drawn at least twice — as an organizer and
as a spectator — because the organizer sees management affordances no one else does.

## 5. The lifecycle — every state needs a design

`draft` → `registration` → `upcoming` → `live` → `completed`
with `cancelled` (pulled before it started) and `abandoned` (started, couldn't finish) as
exits. A tournament in `draft` is visible only to its organizers.

## 6. What the data model actually supports (design only against this)

**Tournament:** name (3–100 chars) · type · banner image · logo · description (≤1000) ·
match-format defaults · rules · start date · end date · registration deadline · location
(city + coordinates) · a list of venues (name + city) · prize details (≤500) · entry fee
(a number, may be null) · min teams (≥2) · max teams (2–256) · organizer list · status ·
privacy (public | private).

**Types available now:** `knockout`, `round_robin`, `league`.
**Reserved for later, design around their absence:** `group_knockout`, `double_elimination`.

**Registration (one per team per tournament):** team · who registered it · when · status
(`pending` | `approved` | `rejected` | `withdrawn`) · the squad they submitted · seed
number · group id · a free-text payment status · who decided and when · an optional message
(≤500) from the manager. Organizers approve or reject.

**Standings (per team, optionally per group):** matches played · wins · losses · ties ·
no-results · points · runs scored · overs faced · runs conceded · overs bowled · net run
rate. Read-only to clients, computed server-side, and **pushed live** — a points table can
update while you watch it.

**Matches inside a tournament** carry: stage (`group` | `quarter_final` | `semi_final` |
`final` | `playoff`), format (`t20` | `odi` | `test` | `the_hundred` | `custom_limited` |
`pairs`), and status (`scheduled` | `toss` | `live` | `innings_break` | `super_over` |
`completed` | `abandoned` | `tied` | `no_result` | `walkover`).

**Per-match player stats already exist** (batting and bowling figures, wickets, per-innings
totals), so tournament leaderboards — most runs, most wickets, best figures, best strike
rate — are computable and in scope.

**Following** works on tournaments, so "follow this tournament" is a real affordance.
**Push notifications** exist and deep-link into the app.

### What does NOT exist and must not be designed as if it does

- **No payment processing.** There is an entry-fee field and a free-text payment status,
  nothing more. Design fees as **recorded, not collected** — the organizer marks a team
  paid after cash or a bank transfer. Do not design a checkout, card form, or wallet.
- **No group stage.** `group_knockout` is a later version. v1 is knockout, round robin, or
  league only.
- **No fixture-generation or standings-computation code yet.** It will be built alongside
  your design, so you may assume the app can generate a schedule and keep a table — but
  design the organizer's control over that generation, because it does not exist yet and
  your design defines it.
- No tournament-level chat, no sponsor/ad system, no ticketing, no live streaming, no
  umpire assignment (only per-match scorer assignment).

## 7. Prior art in this codebase (structure worth stealing, placement now obsolete)

An earlier design round produced tournament prototypes, drawn when tournaments still had
their own bottom-nav tab. That tab no longer exists, so treat the **structure** as prior
art and the **navigation** as void:

- A **Tournaments tab** explored three layouts — stacked sections (Following · Playing ·
  Organizing · Near you), a featured hero with segmented sub-tabs and format chips, and an
  editorial bracket-first hero over a dense list.
- A **Tournament detail** with Standings / Fixtures / Bracket tabs.
- A **Register** flow in 3 steps: summary + accept rules → pick squad → pay & submit.
- A **Seed** flow in 3 steps: order the teams → preview the bracket → lock & publish.
- An **organizer console** with tabs: Overview · Teams · Fixtures · Scorers · Comms · Settings.
- An **awards** pass: a dark champion "trophy moment" screen and an auto-suggested awards list.

You are free to keep, merge, or discard any of it — but if you discard something, say why.

## 8. Hard constraints

- **Light theme only.** No dark mode, no theme toggle. (One exception is on the table: the
  champion moment may go dark as a deliberate one-off — see Prompt 8.)
- **Flutter implementation.** No backdrop blur, glassmorphism, gradient meshes, gradient
  text, or multi-layer shadows. Flat fills, 1px hairlines, the two shadow tokens, the radii
  scale. If it needs a CSS-only trick, it can't ship.
- **One accent.** Red is earned. If everything is red, nothing is.
- **No new colours** unless you justify each and give me the hex.
- **Viewport 390 × 844.** Every screen must work at 390px wide. This is the whole
  challenge for brackets and points tables — solve it, don't shrink the type to 8px.
- **Touch targets ≥ 44dp.** Rows 52–60dp.
- **Design for the messy real case:** a 42-character tournament name, a team called
  "Gujranwala Giants Cricket Club", 24 teams, a 3-round bracket with byes, a match that was
  abandoned for rain, and 120% OS text scaling.

## 9. Deliverable format (applies to every pass unless I say otherwise)

Each pass returns **one self-contained HTML file** I can open in a browser, containing:

1. **Artboards at 390 × 844**, labelled, laid out side by side on a neutral canvas.
2. **A redline table** for every new element: size, weight, letter-spacing, colour token,
   padding, gap, radius, opacity. I type these into Flutter verbatim — give me numbers,
   not adjectives.
3. **Any new SVG glyphs** as raw path data on a 24 viewBox at 1.8 stroke.
4. **Motion notes** where anything moves.
5. **A rationale of at most one page** — what you decided and why.
6. **Open questions** for me, if anything was genuinely ambiguous.

Use CSS custom properties named exactly like the tokens above (`--ink`, `--paper-2`,
`--red`, `--hairline`, `--r-md`, `--font-display`, …) so the mapping to Flutter is
mechanical. Load Inter, Inter Tight and JetBrains Mono from Google Fonts.

**Confirm you have this context and list back, in one line each, the six things you think
will be hardest about this feature. Then stop and wait.**

---
---

# PROMPT 1 — Information architecture + component sheet

Per the master context. This pass produces no full screens — it produces the **map** and
the **parts** every later pass will assemble.

## Deliverable A — the IA map

A single diagram artboard (any width, it need not be 390) showing every tournament surface
and how you reach it, honouring the constraints in master §3: four bottom-nav tabs, the
side panel's "My Tournaments" row, Explore for discovery, and match detail for the
match→tournament link.

Answer these explicitly on the map:

1. Does "My Tournaments" in the side panel go to a **hub** (playing / organizing /
   following) or straight to a **list**? Recommend one.
2. Where does **"Create a tournament"** live? The side panel is nouns-only, so it cannot be
   there. Argue for a home.
3. How does a spectator find a public tournament — Explore only, or does the Matches tab
   surface tournament matches too?
4. When a match belongs to a tournament, how does its match-detail screen say so, and where
   does that link go?
5. What is the back-stack when an organizer taps a fixture inside their own tournament,
   scores it, and finishes? Where do they land?

## Deliverable B — the component sheet

Every reusable part, drawn at real size, in every state, with redlines:

1. **Tournament card** — the unit that appears in lists. Design one card that carries:
   logo/monogram, name, organiser name, city, type (Knockout / Round robin / League),
   match format (T20 etc.), team count, date range, and a status. Draw it in all of:
   `registration open` · `upcoming` · `live` (with a live match on right now) · `completed`
   (with the champion) · `draft` (organizer-only) · `cancelled`.
   Also draw a **compact variant** for dense lists and a **hero variant** for a featured slot.
2. **Status pills** — the full set for tournament status and registration status, using the
   existing pill component and tones.
3. **Fixture row** — one match inside a tournament: stage label, both crests, both names,
   time or score, venue, status. Draw it `scheduled` · `live` · `completed` ·
   `abandoned/no-result` · `walkover` · `bye`.
4. **Standings row** — one team's line in a points table. See Prompt 4 for the full table;
   here, just the row and its column set.
5. **Bracket node** — one match in a knockout tree: two teams, seeds, scores, winner
   emphasis. States: `not yet decided` · `in progress` · `decided` · `bye`.
6. **Team-in-tournament chip** — crest + name + seed, used in seeding and squad lists.
7. **Stat leaderboard row** — rank, player avatar, name, team crest, the number.
8. **Organizer-only affordance treatment** — how does the UI signal "you can act here"
   without shouting? Propose one consistent treatment used everywhere.
9. **Empty, loading (shimmer) and error** variants of the tournament card and fixture row.

Show each component on a light `paper` background **and** on `paper2`, since both occur.

---
---

# PROMPT 2 — My Tournaments hub + discovery

Per the master context, using the components from Prompt 1.

## Screens

1. **My Tournaments** (from the side panel). One person can simultaneously be organising
   one tournament, playing in another, and following a third. Design how those three
   relationships coexist without three separate tabs feeling like three separate apps.
   Draw it: populated (all three relationships), and with only one relationship present.
2. **Discover tournaments** — browse public tournaments. Needs filtering by city/distance,
   format, type, status, and date. We have coordinates for tournaments and for the user, so
   "near you" is real. Decide whether this is its own screen or a group inside Explore, and
   justify it.
3. **Search results** — tournaments appearing in the unified Explore search alongside
   teams, players and matches.
4. **First-run empty** — a user with no tournaments at all, in a city with no public
   tournaments. This is the most common state at launch and it must not read as broken.

## Decisions I need from you

- What is the single most useful thing on a tournament card at a glance, and does that
  change by status? (A live tournament probably wants "QF1 · LL vs MT · 132/4 (14.3)"; an
  upcoming one probably wants the registration deadline.)
- Does a live tournament get promoted to the top of the list, or pinned as a hero?
- How do you show "registration closes in 2 days" urgently without spending red on it?

Draw both a populated and an empty version of every screen.

---
---

# PROMPT 3 — Tournament detail (the main read surface)

Per the master context. This is the screen most people will spend the most time in, in both
the spectator and organizer roles.

## The screen

A pushed full-screen view with a banner image, logo, name, organiser, status, dates, venue,
and a follow button — over a set of sections. The prior art used Standings / Fixtures /
Bracket; propose the right set from: **Overview · Fixtures · Standings · Bracket · Teams ·
Stats**, and justify any you drop or merge. Note that **the right set changes by tournament
type** — a knockout has no points table, a round robin has no bracket.

## Artboards required

1. **Overview**, `registration` status — what a team manager needs to decide whether to
   enter: rules, format, fee, deadline, prize, venues, teams already in.
2. **Overview**, `live` status — what a follower wants on a match day: what's on right now,
   what's next, who's on top.
3. **Overview**, `completed` — the champion, the final's scoreline, the awards, the
   season-in-numbers.
4. **Fixtures** — grouped by round or by day, with a filter for "my team". Include a
   rain-abandoned match and a walkover.
5. **Teams** — the field of entrants; tapping one shows its squad and its fixtures.
6. **Stats** — leaderboards for most runs and most wickets (see the component sheet).
7. **The same Overview as an organizer** — the management affordances layered on: pending
   registrations needing a decision, fixtures needing a scorer, the "publish"/"start"
   action for the current lifecycle step.
8. **A private/draft tournament** as seen by its organizer.
9. **The banner treatment when no banner image was uploaded** — most grassroots organisers
   will not upload one. This fallback is the common case, not the edge case; make it good.

## Constraints specific to this pass

- The header must collapse gracefully on scroll; specify the collapsed state.
- "Follow" is a real action with a count. Design followed vs. not-followed.
- A tournament can be shared as a link. Show where the share affordance sits.

Standings and Bracket get their own pass — put placeholders in the tab bar here and design
them in Prompt 4.

---
---

# PROMPT 4 — Bracket and standings (the hard pass)

Per the master context. Two dense data displays on a 390px-wide phone. This is the pass
where the feature is won or lost — give it your full attention and show alternatives.

## Part A — the bracket

Design a **knockout bracket** for a phone. Required cases:

1. **8 teams** — quarter-finals → semi-finals → final. The canonical case.
2. **6 teams with byes** — an uneven draw is normal at this level; byes must read as
   intentional, not broken.
3. **16 teams** — a bracket that cannot fit on one screen in any orientation.
4. **In-progress** — some results in, one match live, the rest undecided.
5. **A completed bracket** with the champion resolved.

Explore **at least two structurally different approaches** and recommend one. Candidates:
a horizontally-scrolling classic tree; a round-by-round vertical list with a round selector;
a zoomable canvas with a minimap; a "path of a team" view that follows one team's route.
Consider that a spectator usually wants "how does *my* team get to the final", not the
whole tree at once.

Show the tap target and what tapping a bracket node does.

## Part B — the standings table

Design a **points table** that works at 390px with columns: team, played, won, lost, tied,
no-result, points, net run rate. That is eight columns of numbers plus a team name; you
cannot show them all at that width without something giving.

1. Decide what is always visible and what requires expansion or a horizontal scroll — and
   make whatever scrolls feel deliberate, with a pinned team column.
2. Design the **expanded row**: one team's full record, with runs scored/conceded and overs.
3. Show **qualification cut lines** — the visual break between "through to the semis" and
   "out", including the case where the cut runs through the middle of the table.
4. Show a **live update**: standings are pushed to the client during play. Design what a
   row does when it changes while you are looking at it.
5. Show it for **round robin** and for **league** (which may have a different points scheme).
6. Group-stage tables are out of scope for v1, but say in one line how your design would
   extend to them.

Show both parts with real-feeling data: eight Pakistani club team names, plausible NRRs to
three decimals, and a tie on points broken by NRR.

---
---

# PROMPT 5 — Create a tournament (organizer authoring)

Per the master context. An organiser — usually one person running a weekend cup for eight
local teams — sets up a tournament from their phone.

## What has to be collected

Name (3–100 chars) · type (knockout / round robin / league) · logo · banner · description
(≤1000) · match-format defaults (overs per innings, ball type, powerplay, any custom rules)
· tournament rules (tie-breaker order, eligibility restrictions) · start date · end date ·
registration deadline · city and location · one or more venues (name + city) · prize details
(≤500) · entry fee (optional; **recorded, never collected — there is no payment processing**)
· minimum teams (≥2) · maximum teams (2–256) · co-organisers · privacy (public / private).

That is far too much for one form. **Your central design problem is making this feel like
ten minutes of work, not an afternoon.**

## Artboards required

1. The **entry point** and the very first screen an organiser sees.
2. **Every step** of whatever structure you choose (wizard, sectioned form, progressive
   disclosure — argue for one).
3. **A step with a validation error** — the date logic is real and enforced: the end date
   cannot precede the start date, and the registration deadline cannot fall after the start
   date. Minimum teams cannot exceed maximum.
4. **The review step** before publishing.
5. **Draft state** — an organiser abandons setup halfway and comes back tomorrow. Drafts
   are visible only to organisers. Design both the "resume your draft" entry and what an
   incomplete tournament looks like in a list.
6. **Published confirmation** — what happens the instant a tournament goes live for
   registration, including "invite teams" and "share the link".
7. **Type selection** — knockout vs round robin vs league needs explaining to someone who
   has never thought about fixture maths. Design that explanation inline; do not send them
   to a help article. Show the two reserved-for-later types honestly, or omit them entirely.

## Constraints

- Sensible defaults everywhere. A T20 knockout for 8 teams in the organiser's own city
  should be reachable with the fewest taps you can manage.
- Image upload is optional and usually skipped — make the no-image path the smooth one.
- Everything except name and type should be editable later. Say which fields lock once
  registration opens, and why.

---
---

# PROMPT 6 — Organizer console (running the tournament)

Per the master context. Everything an organiser does **after** the tournament exists. This
is where a real cup gets run from, usually one-handed, standing on the boundary.

## Part A — registrations

1. The **registration inbox**: teams that applied, each with its crest, captain, squad size,
   the manager's message, when they applied, and their payment status. Approve or reject.
2. **Bulk handling** — twelve applications for eight slots.
3. **Rejecting** with a reason, and what the manager sees afterwards.
4. **Marking a fee paid** — a manual, organiser-side toggle with no payment processing behind it.
5. **Over-subscription**: max teams reached and applications still arriving. Design a
   waitlist or a hard close, and recommend one.
6. **Under-subscription**: the registration deadline is tomorrow and only five of the
   minimum eight have entered. What does the app say and what can the organiser do?

## Part B — seeding and fixture generation

7. **Seeding** — order the approved teams. Design the reorder interaction for a phone
   (drag, or up/down controls, or both), plus "seed randomly" and "seed by past record".
8. **Preview the generated fixtures** before committing — the bracket for a knockout, the
   full schedule for a round robin.
9. **Assign dates, times and venues** to generated fixtures, in bulk and individually.
10. **Lock and publish** — the irreversible moment. Design the confirmation properly; this
    is the single most destructive-if-wrong action in the feature.
11. **Regenerating** after a team withdraws post-publication. This will happen constantly at
    this level of cricket. Design the least-bad answer.

## Part C — match day

12. **Assign a scorer** to a fixture (per-match, not tournament-wide).
13. **Reschedule** a fixture; **abandon** one for rain; declare a **walkover**.
14. **Live day overview** — three grounds, three matches, one organiser, one phone.
15. **Advance the bracket** — what happens automatically when a match completes, and what
    the organiser must confirm.
16. **Override a result** — rare, sensitive, and needs an audit trail in the UI.

## Constraints

- Distinguish clearly between actions that are reversible and actions that are not.
- Destructive actions earn red; nothing else in this console does.
- The organiser is outdoors, in sunlight, in a hurry. Prioritise legibility and target size
  over density.

---
---

# PROMPT 7 — Team registration (the manager's flow)

Per the master context. A team manager or captain finds a tournament and enters their team.

## Artboards required

1. **The decision screen** — everything a manager needs before committing: format, rules,
   fee, dates, venues, who else has entered. (This may be the Overview from Prompt 3; if so,
   show what changes when the viewer is an eligible manager.)
2. **Which team?** — a manager may run more than one team. Design the picker, including the
   case where one of their teams is already registered.
3. **Accept the rules** — an explicit gate.
4. **Pick the squad** — from the team's roster, including "unclaimed" players who have no
   app account and appear as name-only entries. Show a squad size counter against any
   minimum and maximum, and make the unclaimed players visually distinct without making
   them look broken.
5. **Add a message to the organiser** (optional, ≤500 chars).
6. **Submit** — including how the entry fee is communicated when there is one, given there
   is no payment processing. The organiser will be paid in cash; the app records it.
7. **Pending** — what the manager sees while waiting for a decision, and how they withdraw.
8. **Approved** — the moment they're in. What now? Fixtures, group, seed.
9. **Rejected** — handled with grace, including the organiser's reason.
10. **Blocked cases:** registration deadline passed · tournament full · this team already
    registered · the roster is too small to field a legal squad.

## Constraints

- The squad picker is the heart of this flow. It already exists elsewhere in the app for
  match lineups — design it consistently with a roster list of avatars, roles and a counter.
- Never lose the manager's progress if they background the app mid-flow.

---
---

# PROMPT 8 — Completion, awards and sharing

Per the master context. The final whistle. This is the emotional payoff of the entire
feature and the moment most likely to be screenshotted and shared to WhatsApp — which is
how the next organiser will hear about the app.

## Artboards required

1. **The champion moment** — the screen shown when the final is decided. The prior art went
   **dark** here (ink background, cream/gold accents, a faint pitch oval), deliberately
   breaking the light-only rule for one screen. Either honour that as a considered
   exception or make a better proposal, but decide explicitly and argue it.
2. **The awards screen** — player of the tournament, most runs, most wickets, best
   bowling figures, best strike rate. The stats to populate these already exist per match,
   so awards can be **auto-suggested from real data** with the organiser confirming or
   overriding. Design the suggestion, the confirmation, and the override.
3. **The completed tournament page** — how Overview reads forever after: champion, runner-up,
   final scoreline, awards, full standings, every result.
4. **A shareable card** — a single image a participant can send to WhatsApp. Design the
   canvas (the aspect ratio is your call, argue for it), for two cases: "we won" and
   "tournament complete". This must carry the app's identity without an ad.
5. **A player's own moment** — "you scored 214 runs across 6 matches in Spring Cup '26."
   Personal, shareable, and drawn from data we have.
6. **The unhappy endings** — a `cancelled` tournament and an `abandoned` one. They need
   endings too, and they must not look like a bug.

## Constraints

- This is the one place where the design may be more expressive than the rest of the app.
  Say precisely how far you are departing from the system and why it is contained.
- The shared card is rendered by the app, not a screenshot, so it can be its own size — but
  it must render from data we actually have, with no photography.

---
---

# PROMPT 9 — States, systems and edges

Per the master context. The pass that decides whether this feature feels finished. Go back
across every screen from Prompts 2–8 and complete it.

## Deliverables

1. **A skeleton for every screen** — shimmer shaped like the real content, never spinners.
   Include the case where the banner image is still loading.
2. **Every empty state**: no tournaments anywhere · no fixtures generated yet · standings
   before a ball is bowled · no registrations yet · no stats yet · a bracket before seeding
   · search with no results.
3. **Every error state**: offline · the tournament was deleted · you lost organiser access
   mid-session · a fixture failed to generate · an image upload failed. The app is
   **online-only** for this feature — an offline user sees an honest failure, not a fake
   cached view.
4. **The notification set.** Push notifications exist and deep-link. Design the copy and
   destination for: registration approved · registration rejected · fixtures published ·
   your match is tomorrow · your match is starting · a result is in · standings changed
   position · the tournament is complete. Show them as notification rows in the app's
   inbox, not just as OS banners.
5. **The permission matrix**, drawn: for each of the four roles, which controls are visible,
   which are visible-but-disabled, and which are absent entirely. Disabled-with-a-reason
   beats invisible almost every time — but say where it doesn't.
6. **Text-scale and overflow proofs** at 120% OS text scale: the longest tournament name,
   the longest team name, a four-digit run total, a table with 24 teams.
7. **A final consistency audit** — one artboard placing every tournament surface side by
   side at small scale, so drift between passes is visible. List anything you would change
   now that you can see it all at once.

## Also answer

- What does the feature look like on **day one after launch**, when there is exactly one
  tournament in the entire app and it has two teams in it?
- Which single screen would you cut if we had to ship in half the time?
