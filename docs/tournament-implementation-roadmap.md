# Matchday — Tournament System Implementation Roadmap & Phase-by-Phase Tracking Specification

> **Document Version:** 1.0.0  
> **Source Design:** `Matchday mobile app design (1)` — [Tournaments.dc.html](file:///Users/redapple/Developer/personal/matchday/Matchday%20mobile%20app%20design%20(1)/Tournaments.dc.html) (34 Artboards, Sections A–H)  
> **Target Platform:** Flutter (iOS & Android 390×844) · Supabase Backend · Drift Local Storage · Riverpod 3.x  
> **Verification Device:** Android Emulator (`emulator-5554` · Pixel 7 API 36) + User Verification  

---

## 1. Master Phase Progress Tracker

| Phase | Title | Artboards | Core Scope | Unit / Widget Tests | Emulator Test Status | User Sign-off |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Phase 1** | **Foundations, Tokens & Component Catalog** | 01 | CkTournamentCard, FixtureRow, BracketNode, StandingsTable, Status Pills & Chips | ✅ 14 Tests Passing | ✅ Verified on Emulator | ✅ Completed |
| **Phase 2** | **My Tournaments Hub & Discovery** | 02–08, 23 | `/my/tournaments` (Organizing, Playing, Following tabs), Draft resume banner, Explore discovery & grouped search | ✅ 17 Tests Passing | ✅ Verified on Emulator | ✅ Completed |
| **Phase 3** | **Tournament Detail — Read Surface** | 09–15 | Collapsible header, Overview tab (Reg/Live/Done), Fixtures tab, Bracket tab, Standings tab, Teams & Stats tabs | ✅ 19 Tests Passing | ✅ Verified on Emulator | ✅ Completed |
| **Phase 4** | **Team Manager Registration Flow** | 29–33 | Registration entry gate, 4-step wizard (Select Team, Squad Picker + Captain/WK/Guests, Fee & Proof, Live Status Tracker) | ✅ 22 Tests Passing | ✅ Verified on Emulator | ✅ Completed |
| **Phase 5** | **Organizer Create Wizard** | 16–23 | 6-step progressive wizard (Identity, Structure, Format, Schedule, Fees & Prizes, Review & Publish), Drift local draft autosave | ✅ 25 Tests Passing | ✅ Verified on Emulator | ⏳ Ready for User Sign-off |
| **Phase 6** | **Organizer Console & Live Operations** | 24–28, 24b, 27b–g | Multi-ground Live Ops board, the three ground-ops sheets (abandon / walkover / override), per-match Actions + console ⋮ menus, Settings / Announce / Co-organisers, Cancel dialog, cancelled + pre-matchday console states | ✅ 19 Tests Passing | ⏳ Pending | ⏳ Pending |
| **Phase 7** | **The Finale, Champion Moment & Awards** | 34, 27b | Wrap Up tab, Champion Moment (canvas palette), awards sheet + share wired in from the checklist | ✅ Covered by Phase 6 suite | ⏳ Pending | ⏳ Pending |

---

## 2. Design System Tokens & Axioms (Section A · Artboard 01)

### 2.1 Color Palette & Contrast Standards
- **Canvas / Outer Ground:** `#E5E0D6` (Warm Paper)
- **Primary Card Ground:** `#FBFAF6`
- **Tinted Warning / Pending Ground:** `#F4ECDD` (Borders: `#DED0AC`)
- **Pill / Chip Recessed Ground:** `#F3F0E9` / `#EBE7DE`
- **Separators & Borders:** `#E6E2D9` (Hairline), `#B9B1A2` (Structural line)
- **Primary Ink:** `#29251E` (Headings, primary buttons, high-emphasis text)
- **Secondary Ink:** `#4A4339` (Body text, secondary labels)
- **Muted Ink:** `#8A8170` (Metadata, tabular labels, hints)
- **Earned Red:** `#DC4D32` — **Strict Rule:** Maximum 3 instances per artboard (LIVE pill + score, active tab line, pulse dot).
- **Status Inks (AA Compliant for 9–12px Mono Text):**
  - Green Ink: `#276B34` (Approved, Confirmed, Live, Completed, Won)
  - Red Ink: `#B23A22` (Cancelled, Abandoned, Rejected)
  - Amber Ink: `#8A6E2E` (Closes in 2 days, Pending Payment, Waitlist)
- **Champion Dark Exception (Artboard 34):** `#151311` with `#F5C842` Gold only.

### 2.2 Typography
- **Display & Headings:** `Inter Tight` (Weights: 600, 700)
- **Body & Captions:** `Inter` (Weights: 400, 500, 600)
- **Scores, Dates, Tabular Nums & Status Pills:** `JetBrains Mono` (Weights: 500, 600, 700) with `font-variant-numeric: tabular-nums`

---

## 3. Detailed Phase Specifications

```
  ┌────────────────────────────────────────────────────────────────────────┐
  │                           PHASE 1: FOUNDATIONS                         │
  │                  Design System, Tokens & Component Catalog             │
  └────────────────────────────────────────────────────────────────────────┘
```
### Phase 1: Foundations, Tokens & Component Catalog
**Target Artboards:** `01`  
**Files:**
- [lib/core/theme/circk_theme.dart](file:///Users/redapple/Developer/personal/matchday/lib/core/theme/circk_theme.dart)
- [lib/features/tournaments/presentation/widgets/ck_tournament_card.dart](file:///Users/redapple/Developer/personal/matchday/lib/features/tournaments/presentation/widgets/ck_tournament_card.dart)
- [lib/features/tournaments/presentation/widgets/tournament_fixture_row.dart](file:///Users/redapple/Developer/personal/matchday/lib/features/tournaments/presentation/widgets/tournament_fixture_row.dart)
- [lib/features/tournaments/presentation/widgets/ck_bracket_node.dart](file:///Users/redapple/Developer/personal/matchday/lib/features/tournaments/presentation/widgets/ck_bracket_node.dart)
- [lib/features/tournaments/presentation/widgets/ck_standings_table.dart](file:///Users/redapple/Developer/personal/matchday/lib/features/tournaments/presentation/widgets/ck_standings_table.dart)
- [lib/features/tournaments/presentation/widgets/tournament_shimmers.dart](file:///Users/redapple/Developer/personal/matchday/lib/features/tournaments/presentation/widgets/tournament_shimmers.dart)

#### Components & Specifications:
1. **`CkTournamentCard`**:
   - Standard card variant: 16:9 banner with status pill top-left, dates top-right, title, city/venue with pin icon, format pill (T20, Tape Ball), prize pool tag, slot progress bar (`"6/8 confirmed"`), contextual CTA (`"Manage"`, `"Register"`, `"View"`).
   - Compact card variant: 80pt height with thumbnail avatar, title, status pill, and next match / date.
2. **`TournamentFixtureRow`**:
   - Status states: Live (pulsing red dot + current over/runs), Scheduled (time + venue), Completed (score comparison + winner badge), Abandoned/Rain (`#B23A22` pill), Bye (`#8A8170` muted).
   - Team avatars with score rows (`178/6 (20.0)` vs `154/9 (20.0)`).
3. **`CkBracketNode`**:
   - Matchup box with Seed badges (`#1`, `#4`), Team name (ellipsised at 120pt), score/overs, winner highlight line, connector anchor points (top/bottom/right).
4. **`CkStandingsTable`**:
   - Fixed header (`POS`, `TEAM`, `P`, `W`, `L`, `NR`, `PTS`, `NRR`).
   - Qualification cut line (`Top 2 advance` with subtle green dashed border).
   - Tap-to-expand row showing recent match form (`W`, `W`, `L`, `W`).
5. **Status Pills & Chips**:
   - Live Pill: Red background `#DC4D32`, white text, pulsing dot.
   - Pending / Warning Chip: `#F4ECDD` ground, `#6B5414` text, `#DED0AC` border.
   - Verified / Approved Chip: `#EAF4EC` ground, `#276B34` text, `#C4E2C9` border.

#### Testing & Verification Plan:
- **Unit/Widget Tests:** Ensure all variants render without overflow at 390px width and text scales up to 1.2x.
- **Android Emulator Verification:** Run preview catalog screen on `emulator-5554`, verify all pixel measurements, colors, and tap interactions.
- **Sign-off Criteria:** Component visual fidelity matches Artboard 01 exactly.

---

```
  ┌────────────────────────────────────────────────────────────────────────┐
  │                           PHASE 2: HUB & DISCOVERY                     │
  │            /my/tournaments, Explore Discovery & Unified Search         │
  └────────────────────────────────────────────────────────────────────────┘
```
### Phase 2: My Tournaments Hub & Discovery
**Target Artboards:** `02`, `03`, `04`, `05`, `06`, `07`, `08`, `23`  
**Files:**
- [lib/features/tournaments/presentation/screens/my_tournaments_screen.dart](file:///Users/redapple/Developer/personal/matchday/lib/features/tournaments/presentation/screens/my_tournaments_screen.dart)
- [lib/features/tournaments/presentation/providers/tournaments_providers.dart](file:///Users/redapple/Developer/personal/matchday/lib/features/tournaments/presentation/providers/tournaments_providers.dart)
- [lib/features/tournaments/presentation/controllers/tournaments_controller.dart](file:///Users/redapple/Developer/personal/matchday/lib/features/tournaments/presentation/controllers/tournaments_controller.dart)
- [supabase/functions/search-all/index.ts](file:///Users/redapple/Developer/personal/matchday/supabase/functions/search-all/index.ts)

#### Features & State Flows:
1. **Draft Resume Banner (Artboard 23)**:
   - Watches local Drift DB table `tournament_drafts`. If an uncompleted wizard draft exists, display sticky amber banner at top of Hub: `"Unfinished tournament draft • Step X of 6 • Resume / Discard"`.
2. **Three Hub Tabs**:
   - **Organizing Tab (Artboard 02)**: Tournaments where `created_by == currentUser.id` or user is in `organizers` list. Displays pending applications badge (`"2 applications waiting"`) and primary `"Manage"` CTA pointing to `/tournaments/:id/console`.
   - **Playing Tab (Artboard 03)**: Tournaments where user is on the approved roster of a registered team. Shows registered team name and upcoming match countdown.
   - **Following Tab (Artboard 04)**: Bookmarked tournaments with live score pills and follow toggles.
3. **Empty States & Cold Start (Artboards 05, 08)**:
   - Warm paper illustration with contextual CTA (`"Create Tournament"` or `"Find Tournaments in Your City"`).
4. **Explore Discovery & Grouped Search (Artboards 06, 07)**:
   - Filter chips by status (`All`, `Registration Open`, `Live`, `Upcoming`, `Completed`), ball type (`Tape`, `Leather`), overs (`T20`, `T10`), and City.
   - Grouped search results categorizing Tournaments, Matches, Teams, and Players with exact result count badges.

#### Testing & Verification Plan:
- **Unit/Widget Tests:** Test Riverpod tab switching, draft resume stream, empty state rendering, search filtering.
- **Android Emulator Verification:** Test navigating between tabs, switching cities, clicking draft banner, launching search.
- **Sign-off Criteria:** Instant tab transitions, responsive search with debouncing, zero layout jumps.

---

```
  ┌────────────────────────────────────────────────────────────────────────┐
  │                      PHASE 3: READ SURFACE (DETAIL)                    │
  │           Tournament Detail Header, Overview, Fixtures, Brackets       │
  └────────────────────────────────────────────────────────────────────────┘
```
### Phase 3: Tournament Detail — Read Surface
**Target Artboards:** `09`, `10`, `11`, `12`, `13`, `14`, `15`  
**Files:**
- [lib/features/tournaments/presentation/screens/tournament_detail_screen.dart](file:///Users/redapple/Developer/personal/matchday/lib/features/tournaments/presentation/screens/tournament_detail_screen.dart)
- [lib/features/tournaments/presentation/widgets/tournament_overview_tab.dart](file:///Users/redapple/Developer/personal/matchday/lib/features/tournaments/presentation/widgets/tournament_overview_tab.dart)
- [lib/features/tournaments/presentation/widgets/tournament_fixtures_tab.dart](file:///Users/redapple/Developer/personal/matchday/lib/features/tournaments/presentation/widgets/tournament_fixtures_tab.dart)
- [lib/features/tournaments/presentation/widgets/tournament_bracket_view.dart](file:///Users/redapple/Developer/personal/matchday/lib/features/tournaments/presentation/widgets/tournament_bracket_view.dart)
- [lib/features/tournaments/presentation/widgets/tournament_teams_tab.dart](file:///Users/redapple/Developer/personal/matchday/lib/features/tournaments/presentation/widgets/tournament_teams_tab.dart)
- [lib/features/tournaments/presentation/widgets/tournament_stats_tab.dart](file:///Users/redapple/Developer/personal/matchday/lib/features/tournaments/presentation/widgets/tournament_stats_tab.dart)

#### Features & State Flows:
1. **Collapsible Header Architecture (Artboard 10)**:
   - 168pt expanded banner with 48pt floating monogram/logo (-24pt overlap).
   - On scroll: smoothly collapses into a 56pt sticky app bar with 28pt monogram, title, follow button, and share action.
2. **Overview Tab Lifecycle States**:
   - **Registration State (Artboard 09)**: Countdown timer (`"Closes in 2 days"`), confirmed team slots progress (`"6 / 8 confirmed"`), prize pool cards, ground map link, organizer info, sticky bottom registration CTA (`"Register Team • PKR 15,000"`).
   - **Live State (Artboard 10)**: Featured live match marquee with live scoring pulse, today's schedule, quick top-4 standings snapshot, stats leaders.
   - **Completed State (Artboard 11)**: Trophy champion card, runner-up, MVP presentation.
3. **Fixtures Tab (Artboard 12)**:
   - Filter by Round (`Group Stage`, `Quarter-Finals`, `Semi-Finals`, `Final`) or Date picker.
   - Tap fixture to open Match Scoring/Summary screen.
4. **Bracket Tab (Artboard 13)**:
   - Knockout visualization supporting 4, 8, 16 teams with bye resolution and line connectors.
5. **Standings Tab (Artboard 14)**:
   - Multi-group segmented selector (`Group A`, `Group B`) or single league table with qualification cut lines and NRR.
6. **Teams Tab & Stats Tab (Artboard 15)**:
   - Confirmed teams roster view + Stats leaderboards (Most Runs / Most Wickets / MVP).

#### Testing & Verification Plan:
- **Unit/Widget Tests:** Verify sliver scroll collapse, dynamic tab switching based on tournament type (Knockout vs League vs Groups+Knockout), NRR rendering.
- **Android Emulator Verification:** Test scrolling performance, tab gestures, fixture tap routing, bracket horizontal scroll.
- **Sign-off Criteria:** Smooth 60fps sliver collapse, dynamic tabs rendering correctly according to tournament format.

---

```
  ┌────────────────────────────────────────────────────────────────────────┐
  │                   PHASE 4: TEAM MANAGER REGISTRATION                   │
  │                     4-Step Team Application Wizard                     │
  └────────────────────────────────────────────────────────────────────────┘
```
### Phase 4: Team Manager Registration Flow
**Target Artboards:** `29`, `30`, `31`, `32`, `33`  
**Files:**
- [lib/features/tournaments/presentation/screens/team_registration_sheet.dart](file:///Users/redapple/Developer/personal/matchday/lib/features/tournaments/presentation/screens/team_registration_sheet.dart)
- [lib/features/tournaments/domain/entities/tournament_registration.dart](file:///Users/redapple/Developer/personal/matchday/lib/features/tournaments/domain/entities/tournament_registration.dart)
- [lib/features/tournaments/data/datasources/tournaments_remote_datasource.dart](file:///Users/redapple/Developer/personal/matchday/lib/features/tournaments/data/datasources/tournaments_remote_datasource.dart)

#### 4-Step Registration Flow:
1. **Entry Gate (Artboard 29)**:
   - Modal bottom sheet with tournament recap, fee amount, slots remaining (`"6 / 8"`), prize pool, rules acknowledgment, `"Register My Team"` CTA.
2. **Step 1 of 4: Select Team (Artboard 30)**:
   - Select from user's managed club teams or option to `"Create new team"`.
   - Prevent registering if team is already registered or tournament is locked.
3. **Step 2 of 4: Squad Picker (Artboard 31)**:
   - Multi-select 11–16 players from club roster.
   - Mandatory assignment of Captain `(CAPT)` and Wicketkeeper `(WK)`.
   - Add guest players (unregistered/guest profiles marked with `*`), enforcing tournament's max guest player limit.
4. **Step 3 of 4: Rules & Fee Instructions (Artboard 32)**:
   - Organizer's payment details (Bank IBAN / JazzCash / EasyPaisa / Cash on ground).
   - Transaction ID input, payment reference note, optional receipt screenshot upload.
5. **Step 4 of 4: Live Status Tracker & Outcomes (Artboard 33)**:
   - **Pending Review:** `"Application submitted • Organizer will verify within 24h"`.
   - **Approved / Confirmed:** `"Application Accepted! Seed #4 • Match 1 scheduled for Saturday"`.
   - **Waitlisted:** `"Position #2 on waitlist • You will be bumped if a team drops out"`.
   - **Rejected:** `"Application not approved • Reason: Squad size under minimum • Contact organizer"`.

#### Testing & Verification Plan:
- **Unit/Widget Tests:** Squad validation (min 11, max 16, exactly 1 captain, 1 WK, guest player cap), Supabase submission mapper.
- **Android Emulator Verification:** Complete full 4-step registration on `emulator-5554`, verify image upload for payment slip, check live status tracker.
- **Sign-off Criteria:** Validation prevents invalid squad submission, status updates reflect immediately.

---

```
  ┌────────────────────────────────────────────────────────────────────────┐
  │                   PHASE 5: ORGANIZER CREATE WIZARD                     │
  │                  6-Step Wizard & Local Draft Storage                   │
  └────────────────────────────────────────────────────────────────────────┘
```
### Phase 5: Organizer Create Wizard
**Target Artboards:** `16`, `17`, `18`, `19`, `20`, `21`, `21b`, `22`, `23`  
**Files:**
- [lib/features/tournaments/presentation/screens/tournament_create_wizard_screen.dart](file:///Users/redapple/Developer/personal/matchday/lib/features/tournaments/presentation/screens/tournament_create_wizard_screen.dart)
- [lib/core/database/tables.dart](file:///Users/redapple/Developer/personal/matchday/lib/core/database/tables.dart) (Drift `tournament_drafts` table)
- [lib/features/tournaments/presentation/widgets/tournament_share_card_generator.dart](file:///Users/redapple/Developer/personal/matchday/lib/features/tournaments/presentation/widgets/tournament_share_card_generator.dart)

#### 6-Step Wizard Architecture:
- Top 4pt progress bar with `"Step N of 6"` label and top-right `"Save & exit"` button (writes immediately to Drift local DB).
1. **Step 1: Identity & Privacy (Artboard 16)**:
   - Tournament Name, Banner/Logo upload, City, Primary ground/venue, Privacy mode (`Public` vs `Private / Invite Only`).
2. **Step 2: Type & Structure (Artboard 17)**:
   - Structure selector: `Knockout`, `Round Robin / League`, `Groups + Knockout`.
   - Number of teams (4, 6, 8, 12, 16, 24, 32), Group count, Qualifying teams per group, 3rd place playoff toggle.
3. **Step 3: Match Format (Artboard 18)**:
   - Ball type (`Tape Ball`, `Leather Ball`, `Tennis Ball`), Overs per innings (5, 8, 10, 15, 20), Max overs per bowler, Powerplay overs, Wide/No-ball penalty rules, Super over tie-breaker rule.
4. **Step 4: Schedule & Venues (Artboard 19)**:
   - Start date, End date, Daily match slots (Morning, Afternoon, Night under lights), Multiple grounds mapping.
5. **Step 5: Fees, Prizes & Squad Limits (Artboard 20)**:
   - Entry fee amount (or Free), payment instructions (Bank / Wallet details), Prize breakdown (Winner, Runner up, MVP, Best Bowler/Batter), Min/Max squad size, Guest player limit.
6. **Step 6: Review & Publish (Artboards 21, 21b, 22)**:
   - Verification review checklist with edit shortcuts.
   - Irreversible Publish confirmation dialog (Artboard 21b).
   - Post-publish viral share sheet with WhatsApp preview card and deep link (Artboard 22).

#### Testing & Verification Plan:
- **Unit/Widget Tests:** Draft serialization & deserialization in Drift DB, step validation gates, publish RPC payload.
- **Android Emulator Verification:** Create a tournament from scratch on `emulator-5554`, save draft on Step 3, kill app, resume draft from Hub, complete and publish.
- **Sign-off Criteria:** Zero data loss on app kill/resume, smooth publish transition to detail view and share sheet.

---

```
  ┌────────────────────────────────────────────────────────────────────────┐
  │                  PHASE 6: ORGANIZER CONSOLE & LIVE OPS                 │
  │         Registrations, Auto-Fixtures, Irreversible Lock & Ground Ops   │
  └────────────────────────────────────────────────────────────────────────┘
```
### Phase 6: Organizer Console & Live Operations
**Target Artboards:** `24`, `24b`, `25`, `25b`, `26`, `27`, `27b`, `27c–g`, `28`
> Note: the canvas draws `24b · 27h · 27i` — empty queue, pre-matchday, cancelled — as one
> three-up panel at the foot of artboard 28, not as standalone boards.  
**Files:**
- [lib/features/tournaments/presentation/screens/organizer_console_screen.dart](file:///Users/redapple/Developer/personal/matchday/lib/features/tournaments/presentation/screens/organizer_console_screen.dart)
- [supabase/migrations/20260825000000_tournament_advancement_and_standings.sql](file:///Users/redapple/Developer/personal/matchday/supabase/migrations/20260825000000_tournament_advancement_and_standings.sql)

#### Console Architecture:
- Dedicated pushed screen `/tournaments/:id/console` with 3 tabs:
1. **Console Tab 1: Registrations (Artboards 24, 24b)**:
   - Pending applications inbox with badge count (`"2 waiting"`).
   - Applicant review sheet: Roster inspection, verified vs guest player flags, payment proof image viewer, Approve with Seed / Reject with reason / Waitlist actions.
   - Confirmed teams list with manual payment received toggle (`"Mark Paid"`).
   - Empty state (Artboard 24b): `"No pending applications • Share tournament link"`.
2. **Console Tab 2: Seeding & Fixtures (Artboards 25, 25b, 26)**:
   - Manual seed drag-and-drop or Auto-seed button.
   - Group draw generator (for Groups + Knockout).
   - Deterministic Fixture Scheduler: Circle method for round robin, binary tree for knockouts with bye allocations (e.g. 6 teams -> Seeds 1 & 2 get byes).
   - Match reordering (Artboard 25b): Drag & drop time slots and assign pitches.
   - **Lock & Publish (Artboard 26)**: Irreversible lock action with modal confirmation. Once locked, fixtures are immutable and teams receive notifications.
3. **Console Tab 3: Live Ops & Match Management (Artboards 27, 27b, 28, 27c–g, 27h, 27i)**:
   - Live tournament status dashboard: Active matches, next up, completed.
   - Ground Ops Action Sheet (Artboard 28):
     * Start Scoring / Assign Scorer (assign scorer phone number or direct scoring link)
     * Reschedule match (date, time, pitch)
     * Weather / Rain Abandonment (split points or reschedule)
     * Forfeit / Walkover (award match to Team A/B with score penalty)
     * Score Override & Audit Log
   - Completed Console State (Artboard 27b): Finalize tournament, trigger Champion ceremony, lock all stats.
   - Edge states (27h, 27i): Rainout / washout resolution, emergency tournament cancellation with refund notice.

#### Delivery note (2026-08-31) — two phantom references repaired

`20260825000000_tournament_advancement_and_standings.sql` shipped against two objects that no
migration ever created. Both are plpgsql, so they fail at **runtime**, not at create time — which is
why nothing complained:

1. **`matches.winner_id`** — read by `recalculate_tournament_standings()` and
   `trg_advance_tournament_bracket()`. Until now, standings never recomputed and knockout brackets
   never advanced. The winner has always lived at `result->>'winner_team_id'`, written by the
   `record-ball` edge function. `20260830000000_tournament_live_ops.sql` promotes it to a real
   column kept in sync by a BEFORE trigger, so `result` stays the single source of truth and **no
   cricket arithmetic moves into SQL** (per the CLAUDE.md banner).
2. **`match_officials`** — referenced by `list_my_matches()` and by a comment in `0300_tournaments`,
   but never created. It is where per-match scorer assignment lives, which is what artboard 27's
   "No scorer assigned → Assign" row writes to. Created idempotently.

The same migration also makes a **walkover** count in the table: 2 points to the winner, counted as
played, with NRR untouched by construction (the NRR aggregates read `completed` matches only) —
matching the canvas ruling that "a walkover cannot help or hurt run rate". Previously `walkover`
was invisible to the standings entirely.

> ⚠️ **Not yet applied.** The migration is written but has not been run against Supabase.

#### Testing & Verification Plan:
- **Unit/Widget Tests:** Seed generation algorithms, bye assignment, fixture conflict detection, lock status state machine.
- **Android Emulator Verification:** Test approving applications, generating fixtures, locking schedule, performing rain abandonment, and scoring matches on `emulator-5554`.
- **Sign-off Criteria:** Fixtures generate deterministically without conflicts, live ops actions update standings in realtime.

---

```
  ┌────────────────────────────────────────────────────────────────────────┐
  │                    PHASE 7: THE FINALE & CHAMPION MOMENT               │
  │                  Dark Celebration, Awards & Social Graphics            │
  └────────────────────────────────────────────────────────────────────────┘
```
### Phase 7: Finale, Champion Moment & Awards Ceremony
**Target Artboard:** `34`  
**Files:**
- [lib/features/tournaments/presentation/widgets/champion_moment_view.dart](file:///Users/redapple/Developer/personal/matchday/lib/features/tournaments/presentation/widgets/champion_moment_view.dart)
- [lib/features/tournaments/presentation/widgets/tournament_awards_sheet.dart](file:///Users/redapple/Developer/personal/matchday/lib/features/tournaments/presentation/widgets/tournament_awards_sheet.dart)
- [lib/features/tournaments/presentation/widgets/tournament_share_card_generator.dart](file:///Users/redapple/Developer/personal/matchday/lib/features/tournaments/presentation/widgets/tournament_share_card_generator.dart)

#### Features & State Flows:
1. **The Champion Moment (Artboard 34)**:
   - **Deliberate Dark Theme Exception**: Pitch-dark ground (`#151311`), ambient gold glow (`#F5C842`), celebration trophy crest, champion team captain photo, and final victory margin (`"Won by 24 runs"`).
2. **Automated Awards Engine**:
   - Auto-calculated awards with organizer manual override option:
     * **Player of the Tournament (MVP):** Derived from MVP points formula.
     * **Best Batter (Golden Bat):** Highest runs with strike rate tie-breaker.
     * **Best Bowler (Golden Ball):** Highest wickets with economy rate tie-breaker.
     * **Best Wicketkeeper / Emerging Player:** Catches/stumpings and under-21 stats.
3. **Social Sharing Graphic Generator**:
   - Render dynamic 1080×1920 (Story) and 1200×630 (Post) graphics with matchday branding, team logo, stats, and winner badge ready for WhatsApp/Instagram sharing.

#### Testing & Verification Plan:
- **Unit/Widget Tests:** Awards calculation accuracy from tournament match stats, image rasterizer for social graphic.
- **Android Emulator Verification:** Finalize tournament on `emulator-5554`, trigger Champion Moment, review awards, generate and share graphic.
- **Sign-off Criteria:** Stunning dark celebration screen, exact awards calculation, flawless graphic card rendering.

---

## 4. Edge Cases & Invariants Matrix

| Category | Edge Case Scenario | Architectural Solution / Safeguard |
| :--- | :--- | :--- |
| **Knockouts** | Odd number of teams (e.g. 6 teams) | Deterministic bye engine: Top 2 seeds automatically receive byes to Semi-Finals. |
| **Standings / NRR** | Team bowled out before full overs (e.g. all-out in 14.2 of 20 ov) | Standard Cricket NRR Rule: Divide runs by full allocated quota (`20.0`), not overs batted (`14.2`). Handled in SQL RPC `recalculate_tournament_standings`. |
| **Standings Tie-Break**| Teams tied on Points & NRR | Tie-break hierarchy: 1. Points, 2. NRR, 3. Head-to-Head result, 4. Most Wins, 5. Coin toss/Draw. |
| **Ground Ops** | Match abandoned due to rain after start | If innings 2 reaches minimum overs (e.g. 5 ov in T20), compute DLS/par score; otherwise split points (1 pt each, NRR unchanged). |
| **Live Ops** | Team forfeits / walkover occurs | Award 2 points to non-offending team; offending team receives loss with 0 runs in max overs penalty. |
| **Registration** | Team manager adds guest players exceeding limit | Wizard enforces `guest_players <= tournament.max_guest_players` before submission button enables. |
| **Lock Fixtures** | Attempt to add/remove team after fixtures locked | System enforces immutability. Re-opening schedule requires explicit organizer override with team warning alerts. |
| **Offline / Draft** | User closes app mid-creation on Step 4 | Local Drift DB auto-saves every form change. App shows pinned resume banner on Hub upon re-opening. |

---

## 5. Verification Protocol on Android Emulator (`emulator-5554`)

For every phase:
1. **Automated Test Run:** Run `flutter test test/features/tournaments/...` ensuring 100% pass rate.
2. **Build & Deploy:** Deploy to running Android Emulator (`emulator-5554` · Pixel 7 API 36).
3. **Interactive Visual & Flow Check:**
   - Verify layout against corresponding Artboard at 390px width.
   - Verify 120% OS text scaling without render overflows.
   - Test all user interactions, tab switching, and error states.
4. **Capture Proof:** Record or capture screenshot evidence of the working feature on the emulator.
5. **User Handover & Sign-Off:** Provide instructions for user to test on their end before advancing to the next phase.
