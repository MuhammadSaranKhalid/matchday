# Cricket Formats — Lengths, Team Sizes & Rules (official-source reference)

> Researched 2026-05-30 from official sources: **MCC Laws of Cricket** (lords.org — the universal
> baseline), **ICC Playing Conditions** (format overrides for international cricket), and each
> format's own governing body (ECB/The Hundred, T10 League, WICF for indoor, Last Man Stands).
> The informal street formats have **no governing body** — those rows are commonly-accepted
> conventions, flagged as such.
>
> **The one big idea:** the MCC Laws fix the *baseline* (an over = 6 balls, what an "extra" is,
> when an innings ends). Almost every *difference* between formats — overs, bowler limits,
> powerplays, free hits, super overs, rain rules — lives in **playing conditions**, not the Laws.
> So a format is best modelled as "the Laws + a set of overrides."

---

## 1. Professional / recognised formats

| Format | Players/side | Innings/side | Length | Balls/over | Max per bowler | "All out" | Signature rules |
|---|---|---|---|---|---|---|---|
| **Test** | 11 | **2** | Unlimited — time-limited (5 days, ~90 overs/day) | 6 | none | 10 wickets | Declarations, follow-on (200-run lead), **draw** possible, no powerplay, no free hit |
| **First-class** | 11 | **2** | Unlimited — 3+ days | 6 | none | 10 wickets | Domestic equivalent of Test (same engine) |
| **ODI** | 11 | 1 | **50 overs** | 6 | **10** (⅕) | 10 wickets | Powerplays (overs 1-10: 2 out / 11-40: 4 / 41-50: 5), free hit, Super Over, **DLS** rain rule |
| **List A** | 11 | 1 | 50 (min 40) | 6 | 10 | 10 wickets | Domestic ODI-equivalent |
| **T20 / T20I** | 11 | 1 | **20 overs** | 6 | **4** (⅕) | 10 wickets | 6-over powerplay (2 out, then 5), free hit, Super Over, DLS (min 5 overs for a result) |
| **T10** | 11 | 1 | **10 overs** | 6 | **2** (⅕) | 10 wickets | 3 powerplay overs (2 fixed + 1 floating), Super Over (2 wickets) |
| **The Hundred** | 11 | 1 | **100 balls** | **5-ball "sets"** | **20 balls** | 10 wickets | Ends change every 10 balls; bowler bowls 5 or 10 in a row; 25-ball powerplay; 90-sec strategic timeout |

**Super Over (tie-breaker for the white-ball formats):** 1 over (6 balls) per side, **2 wickets =
all out**, each side picks 3 batters, team that batted 2nd bats first. Boundary-count was
**abolished in Oct 2019** — a tied Super Over now **repeats until a winner** (knockouts) or is left
a **tie** (group stage).

---

## 2. Small-side & social formats (have rulebooks, but vary by league)

| Format | Players/side | Length | Balls/over | Max per bowler | "All out" / dismissal | Signature rules |
|---|---|---|---|---|---|---|
| **Sixes (International)** | 6 | 5 overs | **5** | 1 over each (not keeper) | Last-pair: last batter bats on, scores alone | **Retire at 30**, wide = 4 runs |
| **Sixes (Hong Kong)** | 6 | 6 overs | 6 | 1 each (one bowls 2) | Last batter + a runner; out at 6th wicket | **Retire at 50** |
| **8-a-side (Super 8)** | 8 | ~20 overs | 6 | ⅕ (= 4) | 7 wickets (players − 1) | Mostly standard limited-overs |
| **Indoor (WICF)** | 8 (min 6) | 16 overs | **8** (often 6 in domestic leagues) | exactly 2 each | **No all-out — bat in PAIRS; a dismissal is −5 runs, batter continues** | Zone scoring off the nets (0/1/2/4/6); team total can go negative |
| **Last Man Stands** | 8 (min 5) | 20 overs | **5** | 4 | **At 7 wickets the last batter bats ALONE** (out at 8) | Lone batter scores even runs only; retire at 50; six off the last ball = 12 |

> **Retirement score is not standard** across small-side cricket — documented thresholds are
> 25, 30, 31, and 50. Treat it as a configurable number.

---

## 3. Informal / street formats (⚠️ NO governing body — conventions only)

| Format | Players | Length | Typical "rules decided before the game" |
|---|---|---|---|
| **Gully / street** | varies | varies | "One tip one hand" (one-bounce one-handed catch = out), auto-out zones (over a wall), **no LBW**, often one batter at a time |
| **Box cricket** | 6–8 | 6–12 overs | Bowl from a fixed crease (no run-up), wall scoring (straight wall on the full = 6, side-wall rebound = 4), 3 missed balls = out, no LBW |
| **Tape-ball** | varies | follows whatever limited-overs shape is chosen | A tennis ball wrapped in tape (heavier, swings) — popular in Pakistan; usually adopts the gully auto-out conventions |
| **French cricket** | 1 batter vs everyone | n/a | Kids' game: legs are the wicket; out only by a catch or a thrown ball hitting the legs |
| **Single-wicket** | 1 vs 1 (+ shared fielders) | 2–3 overs each | One batter vs one bowler; most runs wins; some variants deduct runs for an out |

---

## 4. The rules that change between formats (the "knobs")

These are the variables a format is built from:

1. **Balls per over** — 6 in the Laws (MCC Law 17), but **5** in The Hundred & Last Man Stands, **8** in WICF indoor (and historically in Australia pre-1980).
2. **Innings per side** — 1 for limited-overs; **2** for Test/first-class (which unlock declarations, follow-on, and the draw).
3. **What ends an innings** — five Law triggers: all-out, no batter left, declaration, forfeiture, or overs/time done — **plus** target reached (chase). All-out = **players − 1** wickets (10 for eleven, 7 for eight, 5 for six). Two formats break this: **indoor** (pairs, a dismissal is −5 not an end) and **LMS** (last man bats alone).
4. **Bowler limit** — ~⅕ of the innings: ODI 10, T20 4, T10 2, The Hundred 20 balls; **none** in Test.
5. **Powerplay / fielding restrictions** — how many fielders may stand outside the circle, by phase. ODI 3-phase, T20 6 overs, Hundred 25 balls; none in Test/social.
6. **Free hit** — limited-overs only: the ball after any no-ball; the batter can only be run out / obstruct / hit-twice (can't be bowled, caught, LBW, stumped).
7. **Extras** — wide & no-ball each = **1 run + an extra ball** under the Laws (some leagues use 2 for a no-ball; Sixes use 4 for a wide); byes & leg-byes count as a ball of the over, wides/no-balls don't.
8. **Tie-breaker** — Super Over (white-ball); Test/FC just record a **tie** or **draw**. (Bowl-out and boundary-count are retired.)
9. **Rain / interruption** — **DLS** (Duckworth-Lewis-Stern) revises the chase target in ODI/T20 (min 20 overs ODI / 5 overs T20 for a result); India's domestic uses **VJD**; Tests just trend toward a draw.
10. **Toss & batting decision**; and (two-innings only) **declaration / follow-on**.

---

## 5. Recent changes worth noting (2023–2026)

- **Stop clock** — 60 sec between overs (2 warnings, then 5 penalty runs): permanent in ODI/T20I from Jun 2024, extended to **Tests** Jun 2025.
- **ODI two new balls** revised (Jul 2025) — two new balls only for overs 1–34, then one ball chosen.
- **Boundary count abolished** (Oct 2019) — tied Super Overs now repeat.
- **MCC Laws 4th Edition, effective 1 October 2026** — 73 changes, incl. a big overthrows rewrite. (The 2022 code is current until then.)

---

## 6. How this maps to the app's format settings

Every professional/small-side format above can be expressed as these fields (the basis for the
`format` settings in MATCH_ENGINE_DESIGN.md §6 / Slice C):

`playersPerTeam` · `inningsPerSide` · `oversPerInnings` (or `ballsPerInnings` for The Hundred, or
"unlimited" for Test) · `ballsPerOver` · `maxOversPerBowler` (or `maxBallsPerBowler`) ·
`wicketsToAllOut` (= playersPerTeam − 1) · `dismissalEndsBatterStay` (false for indoor/LMS) ·
`powerplay` phases · `freeHit` on/off · `tieBreaker` · `rainMethod` · `retirementScore`.

A few need rule logic beyond a number: **indoor** (bat-in-pairs, −5, zone scoring), **LMS**
(last-man-alone, even-runs-only), and **DLS** (target recompute).

---

## Sources (official first)

- MCC Laws of Cricket — https://www.lords.org/mcc/the-laws (Law 13 innings, 14 follow-on, 15 declaration, 16 result, 17 the over, 21 no-ball, 22 wide, 23 byes/leg-byes)
- ICC Test Playing Conditions — https://images.icc-cricket.com/image/upload/prd/lm8owaz03i86m1eneb7m.pdf
- ICC ODI Playing Conditions (Jul 2025) — https://images.icc-cricket.com/image/upload/prd/d25dbgishkx0kijb4jeu.pdf
- ICC Classification of Official Cricket (Mar 2024, defines Test/FC/List A) — https://images.icc-cricket.com/image/upload/prd/ilr4nwhuw3yt0a0vt0by.pdf
- ICC T20I Playing Conditions — https://documents.bcci.tv/bcci/documents/Mens_Twenty20_International_Playing_Conditions-Effective_December_2023.pdf
- The Hundred competition rules — https://www.thehundred.com/info/competition-rules
- T10 League official rules — https://t10league.com/how-the-t10-game-is-played/
- Super Over / boundary-count abolition — https://www.cricket.com.au/news/icc-super-over-rule-change-world-cup-final-england-new-zealand-lords-controversy/2019-10-15
- WICF indoor rulebook — https://worldindoorcricketfederation.com/download/rulebook.pdf
- Last Man Stands rules — https://www.lastmanstands.com/lms-cricket-rules
- International Sixes — http://cricketphilippines.com/international-6s-rules/ ; Hong Kong Sixes — https://en.wikipedia.org/wiki/Hong_Kong_Cricket_Sixes
- DLS — https://en.wikipedia.org/wiki/Duckworth%E2%80%93Lewis%E2%80%93Stern_method ; ECB DLS regs — https://resources.ecb.co.uk/ecb/document/2023/03/31/e382094c-98ab-4809-a4c6-18596a3a9c23/14-Duckworth-Lewis-Stern-Regulations-2023.pdf
- MCC 2026 Laws edition — https://www.lords.org/lords/news-stories/mcc-announces-new-edition-of-laws-from-1-october-2026
- Informal (no governing body) — gully: https://cricjosh.in/blog/gully-cricket-rules-street-cricket-india ; box: https://turftown.in/blog/box-cricket-rules ; French: https://en.wikipedia.org/wiki/French_cricket
