# Match Scoring Engine — Design Doc

> **Status:** Proposed · **Author:** engineering · **Date:** 2026-05-30
> **Decision context:** see memory `match-engine-architecture`, and `CLAUDE.md` (online-only, no use-case layer).
> **Supersedes:** the current fat `record_ball` plpgsql RPC for the scoring hot path.
>
> **Update 2026-05-30:** the atomic write was changed from a thin `apply_ball` SQL function to
> an **in-edge direct-connection Postgres transaction** (all-TypeScript write path, per the
> user's decision). Wherever this doc still says "`apply_ball` RPC" or "service-role-only
> writer," read it as "a `sql.begin` transaction over a direct connection inside the edge
> function." The engine, concurrency model (FOR UPDATE + version guard), realtime, and Flutter
> contract are unchanged. Slice A therefore ships **no migration**.

This document specifies how the cricket scoring backend is rebuilt as a **split**: a pure
TypeScript rules engine (the brains), a thin atomic Postgres writer, and Supabase Edge
Functions that orchestrate. It is delivered in three independently-shippable slices (A, B, C).

---

## 1. Goals & non-goals

### Goals
- Support **matches of all kinds** — limited-overs presets (T10/T20/ODI), non-XI team sizes
  (6/8-a-side, box), multi-innings/Test, and super-overs/DLS/tie-breaks.
- **Enforce** each format's rules server-side: auto-end an innings at the over limit, auto
  all-out at `playersPerTeam − 1` wickets, bowler over-caps, target/chase detection, completion.
- Make the rules logic **unit-testable in isolation** (no database, no Flutter binding).
- Keep one authoritative place for rules so a **Dart client never re-implements cricket law**.

### Non-goals
- Client-side optimistic rules computation (would duplicate the engine in Dart). The client
  stays "dumb" and trusts the server; the realtime stream is the source of truth for UI state.
- Changing the Flutter Clean-Architecture contract. Domain/repository/controller layers are
  untouched except DTO field additions in Slice C. Writes remain `Future<Either<Failure, T>>`.
- Reworking realtime. The existing `broadcast_*` **table triggers** already fan out every
  write regardless of who performed it; we do not move broadcasting into application code.

---

## 2. Background — verified current state (2026-05-30)

The facts below were verified against the codebase and the **live** Supabase project
(`lczsonnnnanfhsvbdomd`), not inferred.

- **Scoring is a single-innings manual ledger.** `scoring_screen.dart:60` hardcodes
  `final int _inningsNumber = 1;` (used in 14 places). Every `startInnings`/`recordBall` call
  is innings 1. There is **no** innings-break, scorecard, result, or second-innings path.
- **Completion is unreachable.** `completeMatch` and `submit_match_result` have **zero** callers
  in `lib/`. A live match never transitions to `completed` through the app.
- **No server-side termination.** The only triggers on `balls`/`match_innings_state` are
  `broadcast_*` and `assign_seq`. Nothing auto-sets `is_all_out` or ends an innings. The
  `is_all_out` flag exists but is never set.
- **The live DB has scored exactly one innings, ever** (`matches`=1, `match_innings_state`=1,
  `balls`=44, `tournaments`=0). The "working T20" has never run a second innings.
- **Format is opaque.** `matches.format` is `jsonb` (`{overs_per_innings, players_per_team,
  ball_type, max_overs_per_bowler}`). No SQL reads or validates it. There is **no overs-limit
  constraint anywhere**, and `total_wickets CHECK (0..10)`, `innings_number CHECK (1..4)`,
  `ball_in_over CHECK (0..6)` are the live, format-blind guards.
- **`record_ball` is "fat"** — auth + validate + derive over/ball + free-hit lookup + insert
  ball + update state (totals + strike rotation + version bump), all in one transaction. Its
  exact rotation logic is reproduced verbatim in Appendix A.

### Current write path (what we are replacing)
```
Flutter scoring_screen
  → matchesRepository.recordBall(BallDraft)
  → matches_remote_datasource: supabase.rpc('record_ball', {...})
  → [PG] record_ball: lock + version-check + derive + insert balls + update innings_state
  → [PG triggers] broadcast_new_ball / broadcast_innings_state
  → Flutter realtime streams (liveBalls / liveInningsState) update the UI
```

---

## 3. Target architecture — the split

### 3.1 Three components

1. **Pure rules engine (TypeScript).** `supabase/functions/_shared/scoring/`. Input: current
   innings state + format + the raw ball + minimal context. Output: the computed ball row, the
   new innings state, and a set of `events` (overEnded, allOut, inningsEnded, …). **No I/O.**
   Fully unit-tested with `deno test`.

2. **Atomic writer (in-edge transaction).** The edge function opens a DIRECT Postgres connection
   (`postgres.js` over `SUPABASE_DB_URL`) and runs one transaction: `sql.begin` →
   `SELECT … FOR UPDATE` the innings row → reject on `expected_version` mismatch (`40001`) →
   `INSERT` the ball → `UPDATE match_innings_state` with the engine's computed **absolute**
   values → bump `version` → commit. No SQL function; PostgREST/supabase-js cannot do this (no
   transactions), which is exactly why a direct connection is used.

3. **Edge orchestrator (TypeScript).** `supabase/functions/record-ball/` (and siblings). Reads
   authoritative state, runs the engine, calls the writer with optimistic concurrency, returns a
   structured result.

### 3.2 New write path
```
Flutter scoring_screen
  → matchesRepository.recordBall(BallDraft)
  → matches_remote_datasource: supabase.functions.invoke('record-ball', body:{...})
  → [EDGE] record-ball:
        verify caller JWT → actor
        read authoritative innings_state (+ format + prev-non-wide kind)
        result = applyBall(state, format, ball, ctx)        // pure TS, authoritative
        if !result.ok → 422 validation
        sql.begin (direct connection): FOR UPDATE innings row → version-check
            → INSERT ball → UPDATE match_innings_state → commit
        on 40001 → 409 conflict
  → [PG triggers] broadcast_new_ball / broadcast_innings_state   (UNCHANGED)
  → Flutter realtime streams update the UI                       (UNCHANGED)
```

Key property: **everything below the triggers is unchanged**, so the live scorecard keeps
working exactly as today — only *who computes the numbers* moves from plpgsql to TS.

### 3.3 Concurrency & consistency

We use **optimistic concurrency**, the same mechanism `record_ball` already uses (`version`).

- The edge reads `match_innings_state` (version `V`) and computes against it.
- `apply_ball(p_expected_version => V)` takes `FOR UPDATE`, and if the row's version is no
  longer `V` (another scorer wrote in between), raises `40001`.
- The edge returns `409 conflict`. The client already receives fresh state from the realtime
  stream, so it simply retries with the new state. Conflicts are rare (≈one scorer per match).

Cost: **two PostgREST round-trips per ball** (read state, then `apply_ball`) versus the current
one. This is the inherent price of "brains outside the DB." It is acceptable in-region (indexed
PK lookups, tens of ms). If contention/latency ever demands it, the writer can be upgraded to a
**direct-connection single transaction** that holds `FOR UPDATE` across the TS compute — noted
as a future option, not built now.

### 3.4 Authorization

The edge function authorizes BEFORE writing by calling the existing `_can_score_match(p_match_id)`
through a **user-scoped** supabase-js client (the caller's JWT is forwarded), so `auth.uid()` and
RLS resolve to the real user and all three branches (organiser / scorer / friendly-creator) apply
unchanged. This is a read; no authorization logic is duplicated in TypeScript or SQL.

The write then runs over the direct Postgres connection (a privileged role) and stamps
`balls.created_by` with the JWT-verified actor id. It does not re-run `_can_score_match`
(`auth.uid()` is null on that connection) — authorization having already been established by the
user-scoped check above, and the connection string never being exposed to clients.

This pattern (user-scoped authz read + direct-connection transactional write) is reused by every
match edge function (`record-ball`, `undo-ball`, `start-innings`, `end-innings`, `complete-match`).

### 3.5 Error model & Flutter mapping

Edge responses are structured JSON:
```jsonc
// success
{ "ok": true, "ball": { /* balls row */ } }
// validation failure (engine rejected the ball)
{ "ok": false, "error": { "code": "wicket_type_required", "message": "…" } }   // HTTP 422
// version conflict (another scorer wrote first)
{ "ok": false, "conflict": true }                                              // HTTP 409
// auth
{ "ok": false, "error": { "code": "unauthorized" } }                           // HTTP 401/403
```
Flutter:
- `core/error/exceptions.dart` gains `ConflictException`.
- `core/error/failures.dart` gains `ConflictFailure` (sealed `Failure`).
- `matches_remote_datasource.recordBall` calls `functions.invoke`, inspects status/body, throws
  `ConflictException` / `ServerException` / `UnauthorizedException`.
- `matches_repository_impl.recordBall` translates to `ConflictFailure` / `ServerFailure` /
  `AuthFailure`. A `ConflictFailure` is benign: the realtime stream already delivers fresh
  state, so the controller can refresh silently (no scary error).

### 3.6 Directory layout
```
supabase/functions/
  _shared/
    scoring/
      types.ts          # InningsState, MatchFormat, BallInput, BallResult, events
      engine.ts         # applyBall(); Slice B: + termination; Slice C: + format rules
      result.ts         # Slice B: computeResult(allInnings, format) → winner/margin/tie
      engine.test.ts    # deno test — golden vectors per format
      result.test.ts
    db.ts               # service-role + user-scoped client factories, JWT verify helper
    http.ts             # json() helpers, error envelope
  record-ball/index.ts  # Slice A
  undo-ball/index.ts    # Slice A (thin; may stay a pure PG primitive — see §4)
  end-innings/index.ts  # Slice B
  complete-match/index.ts # Slice B
supabase/migrations/
  (Slice A adds NO migration — the atomic write is an in-edge transaction)
  20260531xxxxxx_innings_transition_helpers.sql    # Slice B (only if helpers are needed)
  2026....._format_authoritative_relax_constraints.sql  # Slice C
```

### 3.7 Testing strategy (applies to all slices)
- **Engine (bulk of confidence):** `deno test`, pure, exhaustive. Golden vectors per scenario
  and per format. No DB. This is the payoff of the split.
- **Parity oracle (Slice A, optional but recommended):** run the same vectors through the live
  `record_ball` on a throwaway/test project and assert identical `balls` + `match_innings_state`.
  Proves the TS rewrite is behaviour-preserving before cutover.
- **Writer:** pgTAP or a small integration test — applies values, rejects on version mismatch,
  rejects unauthorized actor, service-role-only grant holds.
- **Flutter:** datasource test mapping `invoke` status → exceptions; repository test
  exception→Failure; existing controller tests unchanged.

---

## 4. Slice A — Parity vertical slice

**Goal:** re-implement `record_ball` in the split shape, **behaviourally identical to today's
T20**, to validate the architecture end-to-end on the one path that already works. **No new
rules. No schema changes** (T20 = 11 players, 10 wickets, 6-ball overs, ≤2 innings — within
every current CHECK constraint).

### 4.1 Engine contract
```ts
// _shared/scoring/types.ts
export type BallKind = 'legal'|'wide'|'no_ball'|'bye'|'leg_bye';
export type WicketKind = 'bowled'|'caught'|'lbw'|'run_out'|'stumped'
  |'hit_wicket'|'retired_hurt'|'obstructing'|'timed_out'|'handled_ball';

export interface InningsState {
  strikerId: string|null; nonStrikerId: string|null; bowlerId: string|null;
  legalBallCount: number; totalRuns: number; totalWickets: number; totalExtras: number;
  isAllOut: boolean; isDeclared: boolean; target: number|null; version: number;
}
export interface MatchFormat {
  oversPerInnings: number;   // 0 = unlimited (used in B/C; A does not enforce)
  playersPerTeam: number;
  ballsPerOver: number;      // A: always 6
  maxOversPerBowler: number; // 0 = unlimited
  inningsPerSide: number;    // A/B: 1
  ballType: 'leather'|'tape'|'tennis';
}
export interface BallInput {
  isLegalDelivery: boolean; ballKind: BallKind;
  runsScored: number; extras: number;
  isWicket: boolean; wicketType: WicketKind|null;
  batsmanId: string|null; nonStrikerId: string|null; bowlerId: string|null;
  fielderId: string|null; commentary: string|null;
}
export interface EngineContext { prevNonWideKind: BallKind|null; } // free-hit derivation
export interface BallResult {
  ok: boolean;
  error?: { code: string; message: string };
  ball?: { overNumber: number; ballInOver: number; isFreeHit: boolean };
  newState?: Pick<InningsState,'strikerId'|'nonStrikerId'|'bowlerId'
    |'legalBallCount'|'totalRuns'|'totalWickets'|'totalExtras'>;
  events?: { overEnded: boolean; allOut: boolean; inningsEnded: boolean };
}
export function applyBall(s: InningsState, f: MatchFormat, b: BallInput, c: EngineContext): BallResult;
```
The Slice-A `applyBall` is a **verbatim TS port of `record_ball`** (Appendix A): same validation,
same over/ball derivation, same `v_swap` parity, same end-of-over toggle, same null-on-wicket /
null-on-over-end. `events.allOut`/`events.inningsEnded` are always `false` in A (activated in B).

### 4.2 Atomic writer — in-edge transaction (no SQL function)
- The edge opens a direct Postgres connection (`db()` in `_shared/db.ts`, `postgres.js`), created
  once per warm instance. Connection config (researched against current Supabase docs, 2026):
  use the Supavisor **transaction pooler (port 6543)** — Supabase's recommended mode for edge/
  serverless and IPv4-reachable (the direct endpoint is IPv6-only without the paid add-on);
  `prepare:false` is **required** there (transaction mode can't honor prepared statements — this
  matches Supabase's own `drizzle` edge example); SSL is pre-configured for deployed edge
  functions, so no `ssl` option. The URL defaults to the auto-injected `SUPABASE_DB_URL` (which
  Supabase's edge examples pass straight to postgres.js), with a `MATCH_DB_URL` override secret to
  force the pooler string if `SUPABASE_DB_URL` ever resolves to the direct `:5432`; the function
  logs the resolved host:port at startup so the deploy logs prove which connection it got. A small
  bounded pool (`max:3`, `idle_timeout:20`, `max_lifetime:1800`, `connect_timeout:10`) plus a
  `beforeunload` `sql.end()` avoid the "Max client connections reached" exhaustion that
  postgres.js's bare defaults invite across many warm instances.
- One `sql.begin` transaction: `SELECT … FOR UPDATE` the innings row → if
  `version <> expectedVersion` throw → `409` conflict → `INSERT INTO balls (…)` →
  `UPDATE match_innings_state SET <engine's absolute values>, version = version + 1` → commit.
- Authorization is the user-scoped `_can_score_match` read done before the transaction (§3.4);
  the write stamps `balls.created_by` with the verified actor. No SQL writer function, no new
  `_can_score_match` overload.

### 4.3 Edge `record-ball`
- Verify JWT → `actor`. Read `match_innings_state` (version `V`), `matches.format`, and the
  previous non-wide ball kind. Run `applyBall`. On `!ok` → 422. Else `service.rpc('apply_ball',
  { actor, expected_version: V, ball, new_state })`. On `40001` → 409 conflict; else 200.

### 4.4 Flutter changes
- `matches_remote_datasource.recordBall`: `supabase.rpc('record_ball', …)` →
  `supabase.functions.invoke('record-ball', body: {...})`; map status → exceptions.
- Add `ConflictException` / `ConflictFailure`; translate in `matches_repository_impl`.
- **No** entity, DTO, controller, screen, or realtime changes. `BallDraft` is unchanged.

### 4.5 Rollout
- Deploy engine + `apply_ball` + `record-ball`. Keep `record_ball` RPC as a fallback.
- Flip the datasource. Run the parity oracle + a manual over. Then delete `record_ball`.
- **Decision for A:** leave `undo_last_ball` and `start_innings` as their existing PG RPCs
  (no TS brains needed — they reverse / set the trio). Re-shape only `record_ball`. Minimal
  blast radius.

### 4.6 Exit criteria
A full T20 *first innings* scores identically through the new path; parity oracle green; conflict
path verified (two concurrent calls → one 409 → client retry succeeds).

---

## 5. Slice B — Innings 2 → innings-break → chase → completion

**Goal:** build the missing half of the one working format. Still T20, still **no schema column
changes** (the `target`, `is_all_out`, `is_declared` fields and the `innings_break`/`completed`
statuses already exist; `innings_number` already allows up to 4).

### 5.1 Engine — termination becomes real
`applyBall` now reads `format` to emit termination events on the **new** state:
- `allOut = newTotalWickets >= (format.playersPerTeam - 1)`  *(Slice C generalises to
  `format.wicketsToAllOut`)*
- `oversComplete = format.oversPerInnings > 0 && newLegalBallCount >= format.oversPerInnings * format.ballsPerOver`
- `targetReached = state.target != null && newTotalRuns >= state.target`
- `inningsEnded = allOut || oversComplete || targetReached || state.isDeclared`

The engine still does **not** perform I/O; it only reports `inningsEnded`. Orchestration decides
what to do next.

### 5.2 Result computation (new pure module)
`_shared/scoring/result.ts`: `computeResult(innings: InningsState[], format) → { outcome:
'team_a'|'team_b'|'tie'|'no_result', margin?: { runs?: number; wickets?: number }, … }`.
Pure, exhaustively tested (win by runs / by wickets, tie, chase succeeds with N balls/wickets to
spare). The margin/winner jsonb is what `complete_match` persists into `matches.result`.

### 5.3 New PG primitives (thin writers)
- `end_innings(p_match_id, p_innings_number, p_actor, p_expected_version, p_is_all_out,
  p_is_declared)` → sets terminal flags on the innings, sets `matches.status='innings_break'`.
- `complete_match(p_match_id, p_actor, p_result jsonb)` → sets `status='completed'`, writes
  `result`, sets `end_time`. The existing `matches_after_complete → _after_match_complete()`
  trigger then updates standings / advances the bracket — **already built**, now finally reached.
- For innings 2 the **target** is `innings1.totalRuns + 1`, written when the next innings is
  created (extend the existing `start_innings` to accept/derive `target`, or compute in the
  edge and pass it).

### 5.4 Orchestration
When `record-ball` sees `events.inningsEnded` (after the ball is written):
- If another innings remains (`currentInnings < format.inningsPerSide * 2`): call `end_innings`
  → match goes to `innings_break`. The next innings is started from a new **innings-break
  screen** (openers + opening bowler) via `start_innings`, which sets the chase `target`.
- If this was the final innings: compute `computeResult(...)` → `complete_match(...)`.

(Target-reached and final-ball-of-final-over completion are detected by the engine and routed
the same way.)

### 5.5 Flutter changes
- `scoring_screen`: `_inningsNumber` becomes **derived state** (from `matches.status` +
  which `match_innings_state` rows exist), not a constant. Chase UI: "needs N off M",
  required run-rate, target banner for innings 2+.
- **New screens & routes:** `innings_break_screen` (`/matches/:id/innings-break`),
  `scorecard_screen` (`/matches/:id/scorecard`), `result_screen` (`/matches/:id/result`).
- Wire the previously-unreachable completion: the controller calls `complete-match` (edge) — the
  orphaned Flutter `completeMatch` repo method is either deleted or repointed at the edge fn.
- Fix the **toss→batting attribution bug** while here: `listInningsForMatches`
  (`matches_repository_impl.dart:75-76`) assumes innings 1 = team A; derive the batting side from
  the toss/decision instead (the scoring screen's `_battingTeamId` already does this correctly —
  unify on it).

### 5.6 Exit criteria
A complete two-innings T20 runs end-to-end: innings 1 ends (all-out **or** overs complete) →
innings break → innings 2 with a live chase + target → completion with a correct result on a
scorecard/result screen → standings/bracket update fires for tournament matches.

---

## 6. Slice C — Format generalization (all kinds, enforced)

**Goal:** make `format` authoritative and let the engine enforce every format. This slice is
itself multi-step; ship in sub-phases C1 → C3.

### 6.0 The format catalogue (target formats with real numbers)

Sourced from official rule bodies — see **CRICKET_FORMATS.md** for citations (MCC Laws, ICC
playing conditions, ECB/The Hundred, WICF indoor, Last Man Stands). Each row is the `format`
settings the engine reads; the **Phase** column says when it lands.

| Format | Players | Innings/side | Length | Balls/over | Max per bowler | Wkts → all-out | Special engine logic | Phase |
|---|---|---|---|---|---|---|---|---|
| **T20 / T20I** | 11 | 1 | 20 overs | 6 | 4 overs | 10 | — (this is the A/B baseline) | A/B done; presets C1 |
| **T10** | 11 | 1 | 10 overs | 6 | 2 overs | 10 | — | C1 |
| **ODI / List A** | 11 | 1 | 50 overs | 6 | 10 overs | 10 | powerplay phases | C1 |
| **The Hundred** | 11 | 1 | **100 balls** | **5** | 20 balls | 10 | balls-based innings; ends change every 10 balls; 5- or 10-ball spells | C1\* |
| **Sixes** | 6 | 1 | 5–6 overs | 5 / 6 | 1 over each | 5 | every fielder bowls; last-pair rule; retire@N | C1 |
| **8-a-side** | 8 | 1 | ~20 overs | 6 | 4 overs | 7 | — | C1 |
| **Test / First-class** | 11 | **2** | unlimited (timed) | 6 | none | 10 | declarations, follow-on, draw; innings 3–4 | C2 |
| **Super Over** | 11 | +1 (inns 3) | 1 over | 6 | — | **2** | triggered on a tie; repeat-until-winner | C3 |
| **DLS (rain)** | — | — | — | — | — | — | revised-target recompute on interruption | C3 |
| **Indoor (WICF)** | 8 | 1 | 16 overs | 8 | 2 overs each | n/a | **bat in pairs; a dismissal is −5 runs, NOT all-out; net-zone scoring** | bespoke |
| **Last Man Stands** | 8 | 1 | 20 overs | 5 | 4 overs | 8 | **last man bats alone at 7 down; lone batter scores even runs only; last-ball six = 12** | bespoke |
| **Box / gully / tape-ball** | varies | 1 | varies | varies | varies | varies | no official rules — house-rules, or use post-match scorecard mode | scorecard |

Notes:
- **C1\*** — The Hundred fits C1's parameterised loop once `ballsPerInnings` and the 5-/10-ball
  spell concept exist; it just isn't "overs of 6," so it's a small extension, not a rewrite.
- **bespoke** — Indoor and Last Man Stands change what a *wicket* means (pairs / −5 / last-man-
  alone), so they need their own dismissal model, not just a config number. They are deliberately
  *after* C3 (or scored via post-match scorecard) — don't let them block the mainstream formats.
- **`wicketsToAllOut` = `playersPerTeam − 1`** for every standard format (10/7/5 above); the two
  bespoke rows are the only exceptions.

### 6.1 Make `MatchFormat` authoritative
- Extend the domain `MatchFormat` + `MatchDto`/`MatchRequestDto` with: `ballsPerOver`,
  `inningsPerSide`, and (optional, else derived) `wicketsToAllOut`. Persist new keys in the
  `matches.format` / `proposed_format` jsonb (`balls_per_over`, `innings_per_side`, …). The
  `send_match_request`/`accept_match_request` RPCs already pass `format` jsonb — just include the
  new keys.
- Turn `MatchFormat` into a **value object** with `static Either<ValidationFailure, MatchFormat>
  create(...)` enforcing invariants (overs ≥ 1 or unlimited, `2 ≤ playersPerTeam`,
  `1 ≤ maxOversPerBowler ≤ oversPerInnings`, `ballsPerOver ∈ {5,6,8}`, …). Replaces the scattered
  literals catalogued in the review.
- Wire the **format setup UI** that exists but is dead: the `MatchSetupState` wizard / the
  `players_per_side` control in `challenge_send_screen` (currently plumbed but no widget mutates
  it). Add format presets (T10/T20/ODI/Test/Custom) that expand to parameter sets.

### 6.2 Relax the format-blind CHECK constraints
Because the engine now owns correctness, the DB CHECKs only need to be **permissive guards**:
- `match_innings_state.total_wickets`: `0..10` → `0..14` (matches `batting_order` max 15 ⇒ ≤14
  wickets). Real all-out (`playersPerTeam − 1`) is enforced in the engine.
- `balls.ball_in_over`: `0..6` → `0..10` (covers 8-ball overs and Hundred-style "overs"). The
  **split already makes this trivial** — over/ball derivation lives in TS and reads
  `format.ballsPerOver`; the CHECK is just a sanity bound.
- `balls.innings_number` / `match_innings_state.innings_number`: keep `1..4` (covers super-over =
  3 and Test = 4).
- Migration drops+recreates the two CHECKs. RLS/triggers unchanged.

> **Property worth noting:** the split makes format generalization *cheaper*, because every
> format-specific number (`ballsPerOver`, `oversPerInnings`, `wicketsToAllOut`, `inningsPerSide`)
> is read in one testable TS place, and Postgres constraints recede to permissive bounds.

### 6.3 Sub-phases
- **C1 — Limited-overs presets + non-XI sizes.** T10/ODI = `oversPerInnings` change only.
  6/8-a-side = `playersPerTeam` drives `wicketsToAllOut`; relaxed wicket CHECK. Enforce
  `maxOversPerBowler`: the engine needs each bowler's legal balls this innings — add a
  `bowlerLegalBalls` map to `EngineContext` (orchestrator supplies it via a cheap aggregate or a
  denormalized counter) and reject a delivery / bowler selection that would exceed the cap.
- **C2 — Multi-innings / Test.** `inningsPerSide = 2`, `oversPerInnings = 0` (unlimited → no
  over-limit termination), **declarations** (`is_declared` already exists; UI action →
  `end_innings(is_declared=true)`), follow-on logic, draw-vs-result in `computeResult`. For
  live multi-day UX heaviness, `scoring_mode = 'post_match_scorecard'` (a real live enum value)
  is the acceptable fallback entry path.
- **C3 — Super-overs / DLS / tie-breaks.** On `computeResult → 'tie'` with super-over enabled,
  orchestration starts innings 3 (`super_over` status already exists) with super-over rules
  (1 over, 2 wickets all-out). DLS = a dedicated module/table (resource-% tables) that recomputes
  `target`; isolated behind its own function, not in the per-ball hot path.

### 6.4 Exit criteria (per sub-phase)
A match of each in-scope format scores, terminates, and completes with correct results; the
engine's golden-vector suite covers each format's termination and result rules.

---

## 7. Cross-slice rollout & coexistence

- **Branch + tests per slice.** Each slice is independently shippable and reversible.
- **Coexistence:** Slice A keeps `record_ball` as a fallback until the edge path is proven, then
  deletes it. B/C add new primitives without removing A's.
- **Migrations** are applied to the live project via `supabase db push` (needs
  `SUPABASE_DB_PASSWORD` / CI). Continue the verified-reconciliation discipline: every
  production schema change lands as a committed migration file (see the 2026-05-29 hotfix
  reconciliation that this engine work sits on top of).
- **Flutter codegen** (`build_runner`) runs only when freezed/riverpod/json change — i.e.
  Slice C's DTO/format additions, not A/B.

---

## 8. Risks & open questions

1. **Hot-path latency.** Edge adds ~125 ms (hot) to ~400 ms (cold) per ball, plus a second
   PostgREST round-trip. Mitigation: keep the client trusting the realtime echo (as today); do
   **not** add a Dart optimistic mirror (would duplicate the engine). *Open:* is the added
   latency acceptable to scorers, or do we want edge function `keep-warm`/pinning?
2. **`apply_ball` forgery surface.** Mitigated by service-role-only + explicit actor + PG authz.
   The `REVOKE`/`GRANT` must be correct and tested, or a client could forge state.
3. **Free-hit context read.** The engine needs the previous non-wide ball kind. Slice A reads it
   per ball; if that extra query is hot, denormalize `last_non_wide_kind` onto
   `match_innings_state` later.
4. **Result/margin correctness.** Ties, reduced-overs, D/L, declarations are subtle. Isolated in
   `result.ts` with heavy tests; treat as its own review surface.
5. **Two writers of truth during transition.** While `record_ball` and `record-ball` coexist
   (Slice A), only one may be live in the datasource at a time. No dual-write.
6. **Toss→batting attribution bug** (`listInningsForMatches`) is latent today; it must be fixed
   in Slice B before innings 2 makes it visible.
7. **Open scope question for C3:** is DLS in the first delivery of "all kinds," or explicitly
   deferred? It is the single most complex rule set and the only one needing external resource
   tables.

---

## Appendix A — Exact `record_ball` logic the Slice-A engine must reproduce

From the live, reconciled `record_ball` (migration `20260529144952`):
```text
runs   = coalesce(runs_scored, 0)
extras = coalesce(extras, 0)
isLegal = is_legal_delivery

# validation
is_wicket && wicket_type IS NULL          -> error 23514 'wicket_type required'
!is_wicket && wicket_type IS NOT NULL      -> error 23514 'wicket_type must be null'

over_number  = legalBallCount / 6                      # integer division, BEFORE this ball
ball_in_over = isLegal ? (legalBallCount % 6) + 1 : 0
prevNonWide  = ball_type of most recent ball where ball_type <> 'wide' (seq desc)
is_free_hit  = coalesce(prevNonWide = 'no_ball', false)

swap       = (runs % 2 = 1)  XOR  (isLegal AND extras % 2 = 1)
over_ended = isLegal AND (legalBallCount + 1) % 6 = 0
if over_ended: swap = NOT swap

legal_ball_count += isLegal ? 1 : 0
total_runs       += runs + extras
total_wickets    += is_wicket ? 1 : 0      # via ::int::smallint (the reconciled cast fix)
total_extras     += extras
striker_id     = is_wicket ? NULL : (swap ? non_striker_id : striker_id)
non_striker_id = (swap AND !is_wicket) ? striker_id : non_striker_id
bowler_id      = over_ended ? NULL : bowler_id
version        += 1
```
Slice A ports this exactly; the only generalization (Slice B/C) is replacing the literal `6` with
`format.ballsPerOver`, `10` with `format.wicketsToAllOut`, and adding termination on top.

## Appendix B — Data dictionary (live columns the writer touches)

`match_innings_state` (PK `match_id, innings_number`): `striker_id, non_striker_id, bowler_id`
(→ `match_players`), `legal_ball_count int≥0`, `total_runs int≥0`, `total_wickets smallint 0..10`,
`total_extras int≥0`, `is_all_out bool`, `is_declared bool`, `target int>0`, `version bigint`.

`balls` (PK `ball_id`; ordered by `seq≥1`, auto via `_balls_assign_seq`): `innings_number 1..4`,
`over_number≥0`, `ball_in_over 0..6`, `is_legal_delivery`, `ball_type ball_kind`,
`runs_scored 0..7`, `extras 0..10`, `is_wicket`, `wicket_type wicket_kind`, `is_free_hit`,
`batsman_id/non_striker_id/bowler_id/fielder_id` (→ `match_players`), `commentary`, `created_by`.

Realtime: `broadcast_new_ball`/`broadcast_ball_deleted` on `balls`,
`broadcast_innings_state` on `match_innings_state`, `broadcast_match_state` on `matches` — all
fire automatically on any write and are **not** changed by this design.
