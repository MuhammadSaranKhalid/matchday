# Navigation & IA — The Side Panel, the Bottom Nav, and the Retirement of Pavilion

> **Document Type:** Design & Decision Record
> **Status:** Proposed — three decisions pending sign-off (see [§10](#10-open-questions))
> **Snapshot Date:** 2026-08-23
> **Amended:** 2026-09-02 — **N3 is superseded by N12.** The side panel is now a
> full-screen page (`/menu`, `MenuScreen`), not a `Scaffold.drawer`. N5's four tabs and
> N2's trigger placement both stand. Risk **R1** is what decided it; see
> [§3](#3-decisions-log) and [§11](#11-risks).
> **Supersedes:** `match-pool-feature-design.md` **D10** (nav placement), `search-feature-design.md` **D9** (nav ordering, in part)
> **Touches:** `lib/features/shell/`, `lib/features/management/`, `lib/features/pavilion/`, `lib/core/widgets/v2/v2_kit.dart`, `lib/router/app_router.dart`

---

## Table of contents

1. [Problem statement](#1-problem-statement)
2. [The organising rule](#2-the-organising-rule)
3. [Decisions log](#3-decisions-log)
4. [Current state of the codebase](#4-current-state-of-the-codebase)
5. [The side panel — specification](#5-the-side-panel--specification)
6. [The bottom nav — specification](#6-the-bottom-nav--specification)
7. [Naming: one word for a pool request](#7-naming-one-word-for-a-pool-request)
8. [Migration map — what moves, what dies](#8-migration-map--what-moves-what-dies)
9. [Implementation plan](#9-implementation-plan)
10. [Open questions](#10-open-questions)
11. [Risks](#11-risks)
12. [Architecture compliance](#12-architecture-compliance)

---

## 1. Problem statement

Three surfaces currently compete to be "your stuff," and none of them wins.

| Surface | Where | What it holds |
|---|---|---|
| Bottom nav | Matches tab, Profile tab | your matches, your profile |
| Side panel | 4 cards | your matches, your teams |
| Pavilion | `/pavilion` | your matches, your teams, your tournaments, your account |

**"My Matches" is reachable three different ways.** Pavilion is a ~3,400-line screen
whose entire job is to list the same four things the side panel already lists. The panel
therefore reads as thin — it is a menu pointing at a menu.

Two concrete symptoms:

- **The panel opens from the wrong side.** Its trigger is the button on the *left* of the
  header (`v2_kit.dart:414`), but the sheet slides in from the *right*
  (`management_sheet.dart:28-36`). You tap left; something flies in from the right, past
  your thumb.
- **A dead link poses as a feature.** "Tournament Organizers Hub" routes to `/pavilion`
  — the same destination as the "Pavilion" card three sections above it.

Retiring Pavilion is therefore not a cleanup task. It is the fix. The panel *becomes*
Pavilion, minus a navigation hop.

---

## 2. The organising rule

> **Bottom nav is the world. Side panel is you.**

Everything below falls out of this one line.

- **Bottom nav** — Home, Explore, everyone's matches and live scores, browsing the pool.
- **Side panel** — my matches, my teams, my pool requests, my tournaments, my clubs, me.

This is exactly the split already asked for around the pool ("browse in the bottom nav,
post from the panel"), generalised to the rest of the app. It also settles the
Matches-tab-vs-My-Matches overlap that has been unresolved since Pavilion gave up its tab
on 2026-08-21.

A second rule follows from the first, and does most of the work in [§5](#5-the-side-panel--specification):

> **The panel is nouns only. No verbs.**

You go to a place; the place knows how to make one.

---

## 3. Decisions log

| # | Decision | Choice | Rationale |
|---|---|---|---|
| **N1** | The organising principle | **Bottom nav is the world; side panel is you** | One testable rule resolves every placement question below, and prevents the three-competing-homes failure from recurring. |
| **N2** | Panel slide direction | **From the left** | The trigger already sits at the header's left edge. Left-tap → right-slide is a mismatch the user reads as wrongness before they can name it. |
| **N3** | Panel implementation | **A real `Scaffold.drawer`**, replacing `showGeneralDialog` | Buys edge-swipe-to-open, correct back-button handling, correct scrim, and Material a11y semantics for free. The custom dialog has none of these. |
| **N4** | Own profile placement | **Leaves the bottom nav; becomes the identity block at the top of the panel** | "Me" is the panel's subject, so the panel's masthead is the honest place for it. Honours the intent already recorded in search doc **D9**. |
| **N5** ⚠️ **PENDING** | Bottom nav size | **Four tabs — Home · Explore · Matches · Pool** | With Profile gone the fifth slot is free. Five was already crowded; every remaining tab is genuinely "the world," so the set is coherent rather than padded. |
| **N6** | Pavilion | **Retired — the word and the screen.** My Matches and Match Detail are rehomed; the rest is deleted | Its only remaining job is duplicating the panel. See [§8](#8-migration-map--what-moves-what-dies). |
| **N7** | Panel contents | **Nouns only. No CREATE section** | Every destination already owns its create affordance (`teams_list_screen.dart:75`, `my_matches_screen.dart:254`, `my_pool_broadcasts_screen.dart:38`). A CREATE section would be a second door to buttons one tap deeper — precisely the duplication that made Pavilion pointless. |
| **N8** | Panel item form | **Rows, not cards.** Prose subtitles replaced by live state on the right | The panel is a place you pass *through*, not a dashboard you read. `"Upcoming fixtures, live scoreboards, match challenges & history"` conveys less at a glance than `2 upcoming`. |
| **N9** | My Pool Requests | **A first-class panel destination** — the existing `MyPoolBroadcastsScreen`, renamed | "Post a pool request" was never a CREATE item; it is the `+` button *inside* this screen, which already exists. Same shape as every other row. |
| **N10** | Naming | **One word: "pool request"**, across UI, routes, screens and providers | The codebase currently calls one object three things: `myPoolBroadcastsProvider` / "My Broadcasts", "Host an Open Fixture", and "pool request". Three names for one object is how a feature becomes unbuildable-on. |
| **N12** | Panel implementation, *revised* | **A full-screen route (`/menu`), pushed by the header's left-edge avatar.** Supersedes **N3** (drawer) only — **N2** and **N5** stand | **R1 came true.** The drawer's edge-drag and the tab `PageView` want the same pixels, and every mitigation cripples one of them: either the drawer is undiscoverable or the leftmost tab is hard to swipe out of. A pushed page defends no gesture, so the pager gets the whole edge back. **The trigger does not move** — `_ManagementButton` was already the user's avatar, and it now pushes instead of opening a drawer — so N2's "the trigger sits at the header's left edge" is untouched and the bottom nav stays at N5's four tabs. Contents unchanged: N1, N4, N7, N8, N9 and N11 all still hold. |
| **N11** ⚠️ **PENDING** | Tournaments & Clubs rows | **Shown as disabled "Soon" rows** | Neither is built, but Clubs is an *approved* 68KB spec (`club-feature-design.md`, pre-implementation) — this is signposting a committed roadmap, not an empty promise. Hiding them makes their later arrival a surprise. |
| **N12** | Sign out | **Becomes real, in the panel footer** | It is currently wired to nothing: `pv_v2_account.dart:119` fires a toast reading "Signed out" and does nothing. `authController.signOut()` has no UI caller anywhere. |
| **N13** | Route namespace | **`/my/...` for panel destinations**, with redirects from the old paths | Makes the rule legible in the URL bar and in the router file. Redirects follow the precedent already in `app_router.dart:312` (`/matches/pool` → `/pool`). |
| **N14** ⚠️ **PENDING** | The Pool tab's own affordances | **Keep the "post a pool request" banner; remove the "My broadcasts" row** | The row is "your stuff" leaking into a world tab — it moves to the panel under N1. The banner is different: after scrolling a pool with nothing suitable, "post your own" is the correct next step *right there*. That is a contextual escape hatch, not duplicated navigation. |

Decisions tagged **PENDING** are mirrored in [§10](#10-open-questions).

### Supersessions

Both of the following are cited from code comments and must be annotated by `docs-keeper`,
not silently left to rot:

- **`match-pool-feature-design.md` D10** (decided 2026-06-11) fixed the nav as
  *Home · Search · Matches · Messages · Pavilion*. That never shipped as written (what
  shipped was *Home · Explore · Matches · Pool · Profile*), and N5 supersedes it fully.
- **`search-feature-design.md` D9** (decided 2026-06-11) removed the Profile tab and gave
  the rightmost "me" slot to Pavilion. **N4 honours the first half** — Profile does leave
  the nav, and `/profile` is retained for deep links, exactly as D9 required. **N6
  supersedes the second half**: there is no Pavilion to take a slot.

`CLAUDE.md` §3's folder map, which lists `pavilion/` as a presentation-only feature, also
needs updating once [§9](#9-implementation-plan) Phase 4 lands.

---

## 4. Current state of the codebase

### The panel

`lib/features/management/presentation/widgets/management_sheet.dart` (387 LOC) — a
`showGeneralDialog` right-aligned at 86% width (clamped 320–420). Four sections, each a
card with a two-line description:

| Section | Card | Routes to |
|---|---|---|
| Workspace | Pavilion | `/pavilion` |
| Matches & Fixtures | My Matches | `/pavilion/my-matches` |
| Matches & Fixtures | Send Match Challenge | `/challenge` |
| Teams & Rosters | My Teams & Squads | `/teams` |
| Tournaments & Leagues | Tournament Organizers Hub | `/pavilion` ← duplicate |

It already computes a live badge for My Matches (`live > upcoming > pending`, with colour)
at `management_sheet.dart:46-62`. That logic is good and is reused verbatim under N8.

### The shell

`app_shell.dart` — `V2Header` (management button left; bell + messages right) over a
`StatefulShellRoute` of five branches, laid out in a `PageView` via
`SwipeableBranchView` so tabs can be swiped. Tabs: Home · Explore · Matches · Pool · Profile.

### Already-dead code

Nothing in `lib/` imports these; they reference only each other:

| File | LOC |
|---|---|
| `pavilion/presentation/widgets/pavilion_status_screens.dart` | 878 |
| `pavilion/presentation/widgets/pavilion_yours_screens.dart` | 622 |
| `pavilion/presentation/widgets/pavilion_settings_screens.dart` | 539 |
| `pavilion/presentation/widgets/pavilion_library_screens.dart` | 516 |
| `pavilion/presentation/widgets/pv_kit.dart` | 291 |
| `core/widgets/ck_bottom_nav.dart` (3-tab, superseded by `V2BottomNav`) | 118 |
| **Total** | **2,964** |

---

## 5. The side panel — specification

```
 ╔═══════════════════════════════════════╗
 ║  ●  Saran Khalid                   ✕  ║   ← tap anywhere = /profile
 ║     @saran · All-rounder · Lahore     ║
 ║     12 Posts · 340 Followers          ║
 ╠═══════════════════════════════════════╣
 ║  YOURS                                ║
 ║  ▸ My Matches            2 upcoming   ║
 ║  ▸ My Teams                       3   ║
 ║  ▸ My Pool Requests          2 open   ║
 ║  ▸ My Tournaments              Soon   ║
 ║  ▸ My Clubs                    Soon   ║
 ╠═══════════════════════════════════════╣
 ║  Saved · Settings · Help              ║
 ║  Sign out                             ║
 ╚═══════════════════════════════════════╝
```

Five rows, one identity block, one footer. Nothing else.

### 5.1 Identity block

| Element | Source | Style |
|---|---|---|
| Avatar (48dp) | `myProfileProvider` | `CkCrest` / cached network image |
| Display name | `profile.displayName ?? username` | `CkType.display(18, w700)` |
| `@username · role · city` | `myProfileProvider` + `playerRoleLabel` | `CkType.body(11.5, muted)` |
| `n Posts · n Followers` | `authorPostsProvider`, `followCountsProvider` | `CkType.mono(10, muted)` |

All four providers already exist and are already keyed by user id. The line-composition
logic can be lifted from `pv_v2_account.dart:26-33` as Pavilion is dismantled.

Tapping anywhere in the block closes the drawer and pushes `/profile`.

### 5.2 Rows

One 56dp row: leading icon (24) · label · trailing state · chevron. **No subtitle.**

| Row | Route | Badge provider | Example states |
|---|---|---|---|
| My Matches | `/my/matches` | `myMatchesViewProvider` | `LIVE NOW` (red) · `2 upcoming` (ink) · `3 pending` (amber) |
| My Teams | `/my/teams` | `myTeamsProvider` | `3` |
| My Pool Requests | `/my/pool-requests` | `myPoolRequestsProvider` | `2 open` |
| My Tournaments | — | — | `Soon`, disabled (N11) |
| My Clubs | — | — | `Soon`, disabled (N11) |

Badge precedence for My Matches is `live > upcoming > pending`, reusing
`management_sheet.dart:46-62` unchanged. Badges render nothing when the provider is
loading or the count is zero — an empty right edge, never a `0`.

### 5.3 Footer

Saved · Settings · Help as a compact row, then **Sign out**, which calls
`ref.read(authControllerProvider.notifier).signOut()` behind a confirmation dialog. This
is the first real caller of that method in the app (N12).

> Saved / Settings / Help have no screens today. Whether they ship as rows, as disabled
> "Soon" rows, or not at all is folded into the N11 question in [§10](#10-open-questions).

### 5.4 Mechanics

- Mounted as `drawer:` on the **AppShell `Scaffold`** (`app_shell.dart:47`) so all tabs
  share one instance.
- The header button calls `Scaffold.of(context).openDrawer()`. **`V2Header` sits inside
  `body:`, so it can reach the Scaffold — but `AppShell.build` itself cannot.** A `Builder`
  is required between the `Scaffold` and the header.
- Width 86%, clamped 320–420 (unchanged).
- The shadow offset flips from `(-4, 0)` to `(4, 0)`.
- `HapticFeedback.mediumImpact()` on open is retained.
- `drawerEdgeDragWidth` must be set explicitly and tested on device — see
  [§11](#11-risks) R1.

---

## 6. The bottom nav — specification

Under N5, four tabs:

| # | Tab | Route | Contents |
|---|---|---|---|
| 0 | Home | `/home` | Feed |
| 1 | Explore | `/explore` | Unified search + discovery |
| 2 | Matches | `/matches` | Live · Upcoming · Recent · Browse — **everyone's** matches |
| 3 | Pool | `/pool` | Browse open fixtures + the post-a-request banner (N14) |

`V2Tab` drops its `profile` member; `V2BottomNav._navItem` drops its Profile entry;
`AppShell._tabs` / `_tabTitles` drop index 4; the router drops the fifth
`StatefulShellBranch`.

`/profile` survives as a **root-level push route** over the shell — required by search doc
D9 for deep links, and now also the identity block's destination.

---

## 7. Naming: one word for a pool request

| Today | Becomes |
|---|---|
| `MyPoolBroadcastsScreen` | `MyPoolRequestsScreen` |
| `my_pool_broadcasts_screen.dart` | `my_pool_requests_screen.dart` |
| `myPoolBroadcastsProvider` | `myPoolRequestsProvider` |
| `/matches/my-broadcasts` | `/my/pool-requests` |
| "My Broadcasts" (app bar) | "My Pool Requests" |
| "+ Broadcast" (button) | "Post a pool request" |
| "Host an Open Fixture" (banner) | "Post a pool request" |

**Scope: client-side only.** The `match_requests` table, its columns, and the
`list-open-challenges` edge function keep their names. Renaming those would demand a
migration and an edge-function redeploy for zero user-visible gain; the wire format is
allowed to differ from the UI vocabulary, which is what DTOs are for (`CLAUDE.md` Rule 3).

---

## 8. Migration map — what moves, what dies

### Rehomed — genuinely good, must not die with the word

| File | New home | Note |
|---|---|---|
| `pavilion/…/my_matches_screen.dart` | `matches/presentation/screens/` | Route `/pavilion/my-matches` → `/my/matches` |
| `pavilion/…/pavilion_match_detail_screen.dart` | `matches/presentation/screens/match_detail_screen.dart` | Route `/pavilion/match/:id` → `/matches/:matchId` |
| `pv_v2_match_detail.dart` (661) | `matches/…/widgets/match_detail/` | Where every per-match action lives |
| `pv_v2_kit.dart` (209), `pv_v2_map.dart` (141) | ditto | Match Detail depends on both |
| `pv_v2_data.dart` (202) | ditto, **minus `seedTournaments()`** | Keep the `PvPhase` types; drop the mock seeds |
| `pavilion_match_detail_provider.dart`, `pavilion_controller.dart` | `matches/presentation/` | |

> ⚠️ `pv_v2_match_detail.dart` imports **`pvPhaseConf` from `pv_v2_lanes.dart`**, a file
> being deleted. `pvPhaseConf` must be relocated into `pv_v2_kit.dart` *before* the
> deletion, or the build breaks. See [§11](#11-risks) R2.

### Deleted

| File | LOC | Note |
|---|---|---|
| `pv_v2_lanes.dart` | 1,059 | minus `pvPhaseConf`, which moves |
| `pavilion_v2_screen.dart` | 485 | |
| `pv_v2_account.dart` | 198 | Its rows migrate into the panel footer |
| The six already-dead files in [§4](#4-current-state-of-the-codebase) | 2,964 | Nothing imports them today |
| **Total removed** | **~4,700** | |

`lib/features/pavilion/` ceases to exist. `lib/features/management/` also ceases to exist:
the drawer becomes `shell/presentation/widgets/app_drawer.dart`, alongside `app_shell.dart`
— it is shell furniture, exactly like the bottom nav.

### Redirects (old links stay alive)

```
/pavilion              → /my/matches
/pavilion/my-matches   → /my/matches
/pavilion/match/:id    → /matches/:id
/matches/my-broadcasts → /my/pool-requests
/teams                 → /my/teams
```

`challenge_detail_screen.dart:433` hard-codes `context.go('/pavilion/match/…')` and is
covered by the redirect above, but should be updated directly rather than left to it.

---

## 9. Implementation plan

Sequenced so each phase is independently shippable and reviewable.

| Phase | Scope | Why here |
|---|---|---|
| **0 · Dead code sweep** | Delete the 2,964 LOC in [§4](#4-current-state-of-the-codebase) | Zero behaviour change, zero risk, ships alone. Shrinks the diff every later phase is read against. |
| **1 · Drawer mechanics** | `showGeneralDialog` → `Scaffold.drawer`; opens from the left; shadow flips; `Builder` for `Scaffold.of`; edge-drag tuning | N2 + N3. Contents unchanged, so the visual diff is honestly reviewable. |
| **2 · Panel contents** | Identity block; nouns-only rows; badges; footer; **real sign-out** | N4, N7, N8, N9, N11, N12. The substance of the redesign. |
| **3 · Bottom nav → 4 tabs** | Drop `V2Tab.profile` and branch 4; `/profile` becomes a push route | N5. Requires Phase 2 — profile needs its new home first. |
| **4 · Pavilion retirement** | Rehome My Matches + Match Detail; move `pvPhaseConf`; delete the rest; add redirects; update `CLAUDE.md` §3 and the two superseded docs | N6, N13. Requires Phase 2 — the panel must reach My Matches before Pavilion dies. |
| **5 · Pool request rename** | The table in [§7](#7-naming-one-word-for-a-pool-request); regenerate providers | N10. Pure rename, no behaviour change — last, so it never obscures a functional diff. |

Every phase ends with the `pre-flight-qa` checklist (`build_runner`, `flutter analyze`,
`flutter test`). Phase 5 touches `@riverpod` provider names, so codegen is mandatory there.

---

## 10. Open questions

**Q1 — Bottom nav size (N5).** Drop to four tabs (Home · Explore · Matches · Pool), or
fill the freed fifth slot? Candidates if filled: Tournaments (unbuilt), or Messages
(currently a header icon). *Recommendation: four tabs.*

**Q2 — Tournaments, Clubs, and the footer rows (N11).** Show unbuilt destinations as
disabled "Soon" rows, or omit them until real? This also governs Saved / Settings / Help
in §5.3. *Recommendation: show Tournaments and Clubs as "Soon" (Clubs has an approved
spec); omit Saved / Help until they exist; Settings only if it gets a real screen.*

**Q3 — The Pool tab's affordances (N14).** Banner stays in the Pool tab while
"My broadcasts" moves to the panel — or is the Pool tab purely for browsing, with posting
only from the panel? *Recommendation: keep the banner as a contextual escape hatch.*

---

## 11. Risks

**R1 — Drawer edge-drag vs. page swipe.** ✅ **RESOLVED 2026-09-02 — by removing the
drawer (N12), not by tuning it.** Tabs are laid out in a `PageView`
(`swipeable_branch_view.dart`) for swipe navigation. Flutter's `DrawerController` claims a
~20dp left-edge gesture, and both want the same pixels on tab 0. The mitigation on the
table — set `drawerEdgeDragWidth` explicitly, and stop the `PageView` consuming horizontal
drags in that strip — works, but only by making one of the two gestures worse: either the
drawer is undiscoverable or the leftmost tab is hard to swipe out of. Making the surface a
pushed page dissolves the contest instead of arbitrating it: a route has no edge gesture to
claim. See **N12**.

**R2 — `pvPhaseConf` lives in a file being deleted.** Relocate it into `pv_v2_kit.dart`
in the same commit that deletes `pv_v2_lanes.dart`, or Phase 4 fails to compile.

**R3 — Provider renames cascade through generated code.** Phase 5 renames `@riverpod`
providers; `.g.dart` files are gitignored and regenerated, so a missed `build_runner` run
surfaces as confusing analyzer noise rather than a clean error.

**R4 — "Soon" rows set expectations.** If N11 is accepted, two rows advertise features
with no delivery date. Clubs in particular is an 11-module spec — a long runway behind a
one-word badge.

**R5 — Deleting Pavilion is irreversible in review terms.** ~4,700 LOC across Phases 0
and 4. Phase 0's portion is provably dead; Phase 4's is not, and deserves the closer read.

---

## 12. Architecture compliance

Checked against `CLAUDE.md` so `architecture-reviewer` has no surprises:

- **The menu is presentation-only**, living in `shell` — a presentation-only feature per
  §6.6. It gains no domain or data layer. As a route it sits in `presentation/screens/`,
  one file per route, per §5.3.
- **It reads other features through their `presentation/providers`** (`myProfileProvider`,
  `myTeamsProvider`, `myMatchesViewProvider`, `myPoolRequestsProvider`) — the sanctioned
  Presentation → Presentation seam in §6.6. It touches no other feature's `data/` layer.
- **Sign out** goes `menu → authControllerProvider → authRepository`, matching the
  no-use-case-layer amendment of 2026-05-29.
- **No new drift tables, no offline anything.** This work is entirely online-only and does
  not approach either banner exemption.
- **§7 rename is client-side only** — no migration, no edge-function redeploy (see [§7](#7-naming-one-word-for-a-pool-request)).
