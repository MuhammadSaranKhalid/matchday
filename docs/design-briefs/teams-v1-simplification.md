# Design brief — MatchDay Teams flow, v1 simplification

**Paste everything below the line into Claude Design.**

---

## 1 · What you're designing for

**MatchDay** is a mobile app (Flutter, portrait phone only, ~390×844) for amateur
and street cricket in Pakistan. Users are captains and players of *mohalla*
sides — neighbourhood teams. They create a team, add a squad, challenge other
teams, and score matches ball by ball.

The visual language is already fixed and shipping. It is **light-only** — there
is no dark mode, do not design one. The mood is *paper*: a warm off-white
ground, ink-brown text, hairline borders, and a monospace face used only for
small uppercase eyebrow labels and figures. It should read like a scorebook,
not like a SaaS dashboard. No drop shadows except one deliberate crest lift, no
gradients, no glassmorphism, no rounded-pill everything.

I am asking you to redesign **three things** in the Teams flow. This is v1 —
the guiding instruction is **cut, don't add**. Every screen below is currently
over-built relative to the data that actually exists behind it.

---

## 2 · The design system — use these exact values

### Colour

```
INK (text / primary)
  ink        #29251E   primary text, primary buttons, dark fills
  ink2       #4A4339   secondary text
  muted      #8A8170   tertiary text, eyebrow labels
  soft       #B9B1A2   disabled

GROUND
  paper      #FBFAF6   app background
  paper2     #F3F0E9   recessed / shimmer highlight
  surface    #FFFFFF   raised cards
  canvas     #E5E0D6   deep recess

LINE
  line       #E6E2D9   borders, shimmer base
  hairline   #EEEBE3   the default 1px divider

STATUS (status only — never decorative)
  red        #DC4D32   Cricket Red — alerts, live
  redSoft    #F7E6E1     redInk #B23A22
  green      #338946   success
  greenSoft  #CFEED2     greenInk #276B34
  amber      #E6AC3D   pending / needs-you
  amberInk   #8A6E2E
  cream      #F4ECDD   Seam Cream — warm chip ground
  creamBorder #DED0AC
```

### Type

Three families, each with one job. Never mix them up.

| Role | Family | Used for |
|---|---|---|
| `display` | **Inter Tight**, w700, letter-spacing −2% of size | Headlines, team names, big figures |
| `body` | **Inter**, w400/w600/w700 | All sentences, buttons, labels |
| `mono` | **JetBrains Mono**, w600, letter-spacing +10–14% of size, UPPERCASE | Eyebrow labels ("STATUS · WHAT NEEDS YOU"), meta lines, scores |

Mono labels are small — 9 to 10.5px — always uppercase, usually `muted`.
Display headlines run 19–28px. Body runs 13–14px.

### Radii

`sm 8 · md 14 · lg 20 · xl 28`. Cards are 14. Buttons are 10. Chips are 4–6.

### Existing components you should reuse rather than reinvent

- **Push nav** — a back chevron, a centred/left title, and an optional right-hand
  "pill" action (small, ink-filled, ~28px tall).
- **Crest** — a team's identity mark. Either a rounded square/circle in the
  team's own colour carrying a 2-letter monogram in paper-white, or an uploaded
  logo image. Sizes in use: 36, 40, 44, 56 (list rows) and ~96–120 (hero).
- **Role pill** — a tiny uppercase mono chip: OWNER, CAPTAIN, MANAGER, PLAYER.
- **Team row** — crest + team name (display) + a mono meta line + optional role
  pill + a right chevron. This is the workhorse of the Teams flow.
- **Subhead** — a small mono uppercase section label above a group of rows.

---

## 3 · The hard constraint: what actually has a backend in v1

This is the most important section. The current My Teams screen was ported from
a design that showed **every** possible state. Most of those states have no
backend and render as permanently empty or permanently inert. Designing around
them is what made the screen bloated.

**Real — has data, must be designed:**

- The user's teams, split into two buckets: teams they **lead** (they own or
  manage it) and teams they **play for**.
- A subtitle string: `"1 team · onboarding"` or `"3 teams"`.
- One **upcoming match** hero card — the next accepted or pending match. (Live
  matches are deliberately *not* shown here; this surface is about what's
  coming, not what's in progress.)
- Exactly **one** "needs you" card, and only in one situation: the user has
  exactly one team, they own it, and it has no matches yet. It reads *"Add
  players to your roster."*
- A **resume-draft** card when the user abandoned the create wizard partway.

**Not real — never populates, delete from the design:**

- Invites from other teams (the Accept / Decline buttons are wired to nothing)
- Following / followed teams
- Suggested teams near you
- The "Play, don't just watch." nudge
- Vice-captain, scorer, draft, pending-approval and archived team buckets
- The five filter chips (All · Playing · Managing · Following · Archived).
  Three of the five would filter to a blank screen. They are not even rendered
  today — the filter machinery exists but nothing calls it.

So: **My Teams in v1 has at most two team sections, one optional match card,
one optional needs-you card, and one optional draft card.** That's the whole
screen.

---

## 4 · Deliverable A — My Teams, simplified

### What's there today, and what's wrong with it

A long scroll that can render nine different sections, seven of which are dead.
The empty state is a dashed-border card containing three faded decorative team
crests followed by an empty crest slot, a headline, a two-line subhead, and two
side-by-side buttons.

### What I want

**A1 · Empty.** Strip it right down. The decorative crest row goes. The dashed
border goes. The second CTA goes — it currently points at a route that doesn't
exist. What's left should be roughly: a short line of text and a single Create
button, sitting calmly in the upper-middle of the screen. It should feel like a
clean slate, not a marketing card. Copy: **"No teams yet."** and a button
reading **"Create a team"**. If you think one supporting sentence earns its
place, propose it — but one is the maximum.

**A2 · First team, just created.** The most important state in the app, because
every new user passes through it. One team row, plus the amber "needs you" card
telling them to add players. Show me how those two relate — the needs-you card
is the whole point of the screen at this moment, and today it's buried under a
section header. Consider whether the team row and the prompt should be one
object rather than two.

**A3 · Several teams.** Two sections — teams you lead, teams you play for —
plus the upcoming-match card at the top. Show 2 teams in one section and 1 in
the other so I can see the section rhythm.

**A4 · Loading.** See Deliverable C.

**A5 · Error.** A single line and a retry. Currently it says "Could not load
teams" with a "Go back" link. Keep it to that scale.

### Notes

- The nav is: back chevron, title "My Teams", and a "Create" pill on the right.
  Today that pill is hidden whenever the list is empty (because the empty card
  owns the CTA). If your empty state keeps its own button, keep that rule.
- Pull-to-refresh exists on this screen.

---

## 5 · Deliverable B — "Team created", simplified

### What's there today

A full celebration screen: animated confetti behind a shadow-lifted crest, a
28px headline "<Team> is live.", a subhead, the team's tagline in italics, a
four-row **receipt** (Team profile created · Located in · Crest set · Squad
pending), a "WHAT NEXT" list of four tappable rows (Add players / Open team
page / Schedule a friendly / Register for a tournament), and a "← CREATE
ANOTHER TEAM" link at the bottom.

Two of those four next-steps are effectively dead ends in v1, the receipt
restates information the user just typed, and the whole thing sits between the
user and the one thing they actually need to do next.

### What I want

**B1 · One artboard.** Cut it to: the crest, the headline **"<Team> is live."**,
and a **single primary button — "Add players"**. Everything else goes: the
confetti, the receipt, the three other next-steps, the tagline echo, the create-
another link.

Keep it a real moment, not a toast — this is the payoff for a five-step wizard,
so the crest should have presence and the page should breathe. But it should be
a page the user leaves in one tap.

**One thing I need your opinion on:** with a single button, there's no way to
leave the screen without going to the roster. I don't want a second competing
CTA. Propose how you'd handle the escape — a quiet "Done" in the top bar, a
low-contrast text link under the button, or something else. Show it in the
artboard.

---

## 6 · Deliverable C — Shimmer loading

### The problem

Every full-page load in the Teams flow shows a bare centred spinner on an empty
paper ground. The app already has a shimmer system, and other features
(feed, inbox, profile, matches) use it — Teams just never adopted it.

### The existing shimmer, which you must match

Grey placeholder blocks in `line #E6E2D9`, with a highlight sweep in
`paper2 #F3F0E9` travelling left to right over ~1400ms on a loop. Blocks are
rounded rects (radius 4–6 for text lines, matching the real radius for cards and
crests) or circles for round avatars.

### The rule

**Shape-matched, not generic.** Each skeleton must trace the real layout closely
enough that when data lands, nothing jumps. Same paddings, same block heights,
same number of rows. Don't design a stack of identical grey bars.

### Four artboards

**C1 · My Teams skeleton.** Real layout: push nav (keep the nav real, not
shimmered), then a section subhead, then 2–3 team rows. A team row is: a ~44px
crest, a team name line, a shorter mono meta line beneath it, and a chevron.
Show 3 rows.

**C2 · Team Page skeleton.** Real layout: a large hero block filled with the
team's own colour — but at load time you don't know the colour yet, so decide
what the hero does while loading. Inside the hero: a large circular crest,
the team name in 28px display, a small uppercase city eyebrow, and a four-cell
record strip (PLAYED · WON · LOST · WIN %). Below the hero: a tab bar
(Squad · Matches · Posts) and the first tab's content.

**C3 · Team Manage skeleton.** Real layout: a header row of back chevron + 36px
crest + team name + subtitle, then a four-tab bar (Roster · Posts · Requests ·
Settings), then a roster list of player rows.

**C4 · Team Search skeleton.** Real layout: a search field and a "Near me" pill
at the top (both stay real and interactive — never shimmer a control the user
can already use), then a row of filter chips, then a list of team result rows.
Only the chips and results shimmer.

---

## 7 · How to deliver

- **Portrait phone artboards**, ~390×844, on one canvas.
- Group them: **A — My Teams** (5), **B — Team created** (1), **C — Skeletons** (4).
- Label each artboard with its ID and state name.
- Light mode only.
- Use real Pakistani cricket copy in the mockups — team names like *Lyari
  Lions*, *Model Colony Kings*, *Gulshan Gladiators*; cities like *Karachi*,
  *Korangi*, *Lahore*. Not "Team A" / "Lorem ipsum".
- Where you cut something, it's fine to leave a one-line margin note saying what
  you removed and why. I'd rather see the reasoning than guess.
- If a state reads better merged with another, say so rather than drawing both.

The bar for this brief: **a user who has just installed the app should be able
to create their first team and get to a roster without passing a single screen
that shows them something they can't use.**
