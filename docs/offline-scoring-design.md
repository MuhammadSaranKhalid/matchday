# Offline-Capable Live Scoring — Design Document

> **Status:** Draft for review · **Date:** 2026-08-20 · **Scope:** make ball-by-ball scoring instant on the scorer's device and survive a total loss of connectivity on the ground.
> **Owner:** @MuhammadSaranKhalid
>
> This document is the single source of truth for the offline-scoring work. It is
> written to be reviewed end-to-end and have gaps surfaced. Each major decision
> carries its rationale so reviewers can challenge the *reasoning*, not just the
> conclusion. Nothing in §9–§13 has been built yet.
>
> 🟥 **This proposal requires an amendment to CLAUDE.md's ONLINE-ONLY constraint**
> ([§16](#16-proposed-claudemd-amendment)). That rule names `matches` explicitly as
> staying online-only. Approving this document means deliberately creating a second
> exemption — and a much larger one than the `messages` read-through cache, because
> this is an offline **write** path. Do not start §10 before that amendment is agreed.
>
> ✅ **All decisions accepted 2026-08-20.** The owner delegated the open forks; §4 and
> §19 now record the answers and the reasoning behind each. The plan below is the
> agreed plan, not a set of options.

---

## Table of contents

1. [Problem statement](#1-problem-statement)
2. [Goals & non-goals](#2-goals--non-goals)
3. [The core insight: this is the easy case of local-first](#3-the-core-insight-this-is-the-easy-case-of-local-first)
4. [Decisions log](#4-decisions-log)
5. [Current state of the codebase](#5-current-state-of-the-codebase)
6. [The engine duplication that already exists](#6-the-engine-duplication-that-already-exists)
7. [Architecture overview](#7-architecture-overview)
8. [Engine parity: the golden-vector contract](#8-engine-parity-the-golden-vector-contract)
9. [Stage 1 — local engine, instant apply, still online](#9-stage-1--local-engine-instant-apply-still-online)
10. [Stage 2 — the local write-ahead log and outbox](#10-stage-2--the-local-write-ahead-log-and-outbox)
11. [Sync, idempotency and reconciliation](#11-sync-idempotency-and-reconciliation)
12. [Undo across the offline boundary](#12-undo-across-the-offline-boundary)
13. [Conflict, multi-scorer and the version guard](#13-conflict-multi-scorer-and-the-version-guard)
14. [What spectators see](#14-what-spectators-see)
15. [Edge cases catalogue](#15-edge-cases-catalogue)
16. [Proposed CLAUDE.md amendment](#16-proposed-claudemd-amendment)
17. [Build plan](#17-build-plan)
18. [Risks](#18-risks)
19. [Decisions taken](#19-decisions-taken)
20. [Tooling: running the vector suite](#20-tooling-running-the-vector-suite)
21. [Progress](#21-progress)

---

## 1. Problem statement

Two failures, one root cause.

**A tap does not feel instant.** Recording a delivery blocks on a network round
trip. Measured from Lahore against the production project: PostgREST replies in
300–470 ms, and the `record-ball` edge function in **438–810 ms** for a CORS
preflight alone — before it authenticates or touches the database. Supabase's own
published figures are a 400 ms cold-start median and 125 ms hot median. On top of
that the client discards the server's reply and waits for the realtime broadcast to
carry the same information back on a *second* trip. The run pad is disabled for the
whole window. A scorer tapping once a ball reads that as a broken app.

**Connectivity on a cricket ground is not reliable.** Grounds are frequently on the
edge of coverage. Today a dropped connection means scoring simply stops: the pad
locks, the write fails, and there is no local record of the delivery that was about
to be entered. The match is the product; losing the ability to score it is the worst
failure this app has.

The root cause of both is the same: **the server is the only place a delivery can be
computed or stored.**

---

## 2. Goals & non-goals

### Goals

- **G1.** A tap updates the scoreboard in **0 ms of network time**. No spinner, no
  disabled pad, in the normal case.
- **G2.** A full innings can be scored with **no connectivity at all**, and syncs
  intact when the network returns.
- **G3.** The server remains the **authority** on the scorecard. Local computation is
  provisional until confirmed.
- **G4.** Any divergence between the client's and the server's arithmetic is
  **detected and surfaced**, never silently absorbed.
- **G5.** No regression in scorecard correctness. This is the bar everything else is
  subordinate to.

### Non-goals

- **N1.** Concurrent multi-scorer editing. One authorised scorer per innings, as
  `_can_score_innings` already enforces. Explicitly **not** solving collaborative
  editing — see §3 for why this removes most of the difficulty.
- **N2.** Offline for any other feature. Teams, posts, pavilion, profile stay
  online-only. This exemption is scoped to the scoring write path.
- **N3.** Offline *match setup*. Creating matches, toss, and lineup lock still
  require connectivity. Only ball-by-ball scoring of an already-started innings goes
  offline.
- **N4.** Spectator offline. Spectators are read-only and stay online.

---

## 3. The core insight: this is the easy case of local-first

Most offline-sync horror stories come from concurrent editing of shared mutable
state — that is where CRDTs, vector clocks and merge semantics become necessary and
where projects drown. **Cricket scoring has none of those properties.**

| Property | Why it holds here | What it buys |
|---|---|---|
| **Single writer** | `_can_score_innings` already permits exactly one authorised scorer per innings | **No CRDTs, no vector clocks.** The hardest problem in local-first does not apply |
| **Append-only** | Deliveries are only ever appended; the sole mutation is undo-of-last | A plain log, not a mutable document |
| **Deterministic** | `applyBall` is already a pure function with no I/O | Same inputs produce the same outputs on both sides, provably |
| **Bounded** | A match is ~250 deliveries | The whole log fits in memory. No pagination, no partial sync, no compaction |
| **Naturally ordered** | Every ball carries a monotonic `seq` | Total order for free; no clock reconciliation |

This is the textbook shape of an event-sourced, single-writer local-first system:
each client keeps an append-only log of intent, and synchronisation is log
reconciliation rather than state merging.

**Design consequence:** we are not building a sync engine. We are building a queue
with an idempotency key. That is a materially smaller and safer thing, and the
distinction should survive into the implementation — if anyone finds themselves
writing merge logic, the design has been misread.

---

## 4. Decisions log

| # | Decision | Choice | Rationale | Status |
|---|---|---|---|---|
| D1 | Amend the ONLINE-ONLY constraint for `matches` | **Yes**, scoped to the scoring write path | §1 is an unfixable problem without local computation and local durability | **Accepted** |
| D2 | Port the scoring engine to Dart | **Yes** | A partial, uncontrolled duplicate already exists (§6). The choice is between an uncontrolled duplicate and a test-locked one | **Accepted** |
| D3 | Engine parity mechanism | **Shared golden vectors** run against both implementations in CI | 30 vectors already exist in `engine.test.ts`. One executable spec governs both | **Accepted** |
| D4 | Stage 1 (instant, online) ships before Stage 2 (offline) | **Yes** | Every delivery in Stage 1 is a free production parity test while the server is still reachable and authoritative | **Accepted** |
| D5 | Conflict resolution model | **Refuse and surface.** Server wins; scorer is told | Single writer means conflict is a genuine anomaly, not routine. Auto-merging a scorecard is worse than stopping | Recommended |
| D6 | Local store | **drift**, reusing `AppDatabase` | Already in the project for `WizardDrafts` + the messages cache. No new dependency | Recommended |
| D7 | Idempotency key | **Client-generated uuid per delivery** | Makes replay safe when the network flaps mid-request. Standard outbox practice | Recommended |
| D8 | Rust/WASM shared engine | **No** | Genuinely one implementation, but a whole toolchain for a 214-line pure function. Revisit only if D3 proves insufficient | Recommended |
| D9 | Drop the dead `record_ball` plpgsql function | **Yes** | Superseded by the edge function but never dropped. Leaving it means *three* implementations | Recommended |

---

## 5. Current state of the codebase

**Write path.** `ScoringController._record` → `MatchesRepository.recordBall` →
`MatchesRemoteDataSource.recordBall` → `functions.invoke('record-ball')` → Deno
edge function → one Postgres transaction over the Supavisor pooler.

**Engine.** `supabase/functions/_shared/scoring/engine.ts` — 214 lines, pure,
covered by 30 tests in `engine.test.ts`. It computes the ball row, the new innings
state, and an event set (all-out, overs complete, target reached, declared).

**Reads.** `liveMatchProvider`, `liveInningsStateProvider`, `liveBallsProvider` —
Supabase broadcast channels fed by `realtime.send()` in per-table triggers, with
replay/snapshot/poll resilience. Broadcast payloads are applied directly (no
refetch), and the scorer's own device receives its own broadcast (`self: true`).

**Local storage.** `AppDatabase` (drift, schemaVersion 6) with `WizardDrafts` plus
the `messages` read-through cache tables. No pending-ops queue, no sync service.

**Already improved (2026-08-20, shipped in this workstream):** the edge function now
returns the updated innings row, authenticates with `getClaims()` (local JWT
verification) instead of `getUser()` (network call), and folds the authorisation
check into the write transaction — which also closed a TOCTOU gap. The controller
applies that reply immediately rather than waiting for the broadcast. This removed
one server→phone leg and two server-side hops, but the tap is still gated on a
network round trip. **This document is about removing that gate entirely.**

---

## 6. The engine duplication that already exists

This section exists because it inverts the obvious objection to D2.

The natural argument against a Dart engine is *"don't implement the most
correctness-critical code twice."* That argument is already lost. `ScoringState`
reimplements, in Dart, today:

| Rule | Location | Server counterpart |
|---|---|---|
| Free-hit derivation | `scoring_state.dart:172` | `engine.ts:89` |
| Innings termination | `scoring_state.dart:186` | `engine.ts` events |
| Over completion | `scoring_state.dart:199` | `engine.ts` ball numbering |
| Batter statistics | `scoring_state.dart:304` | derived from `balls` |
| Bowler spell | `scoring_state.dart:325` | derived from `balls` |
| **Wide run attribution** | `scoring_state.dart:395` | `engine.ts:57` |

The code acknowledges it. `freeHitActive` is documented as *"Mirrors the engine's
`prevNonWideKind === 'no_ball'`. Duplicated rather than read from the server."*

And this duplication has **already produced a production defect**. `engine.ts:52`
records it: the scoring screen sent a wide's runs as `runsScored`, which kept the
team total right but inflated the batter's individual score and understated the
extras column. *"The scoreboard looked fine; the scorecard was wrong."* That is a
drift bug, of exactly the class the objection warns about, that happened because the
duplicate was partial and ungoverned.

**Conclusion.** The decision is not *one implementation versus two*. It is **an
uncontrolled partial duplicate (status quo) versus a complete duplicate governed by
a shared executable spec**. The second is safer than what exists today, and that is
true regardless of whether offline ever ships.

---

## 7. Architecture overview

```
        TAP
         │
         ▼
  ┌──────────────────┐   apply immediately, 0ms
  │  Dart engine     │───────────────────────────────► UI
  │  (pure)          │
  └────────┬─────────┘
           │ append intent (uuid = idempotency key)
           ▼
  ┌──────────────────┐
  │  local WAL       │  drift · append-only · survives kill
  └────────┬─────────┘
           │ drained in background, in order
           ▼
  ┌──────────────────┐
  │  outbox / sync   │  retry + backoff · online only
  └────────┬─────────┘
           │ POST record-ball  (idempotency key)
           ▼
  ┌──────────────────┐
  │  TS engine       │  AUTHORITY. validates, persists, broadcasts
  └────────┬─────────┘
           │ authoritative ball + innings
           ▼
     reconcile ──► agree: mark synced
                └► differ: PARITY ALARM (§8), server wins
```

Both engines are the same pure function in two languages, pinned to one shared
spec. The client's answer is **provisional**; the server's is **final**. Every
delivery is therefore a parity check.

---

## 8. Engine parity: the golden-vector contract

This is the mechanism that makes D2 safe, and the part of the plan most worth
attacking in review.

**The contract.** Extract the cases in `engine.test.ts` into a language-neutral
fixture — `supabase/functions/_shared/scoring/vectors.json` — each entry being
`{name, state, format, input, ctx, expected}`. Both the Deno test suite and a Dart
test suite load the *same* file and assert the *same* expected output. CI fails if
either diverges.

**Why this is sufficient.** `applyBall` is pure and total: no I/O, no clock, no
randomness. A pure function is fully characterised by its input/output pairs, so a
sufficiently dense vector set *is* the specification. Adding a rule means adding a
vector first; the vector fails in both languages until both implement it.

**Coverage bar before Stage 2.** Vectors must cover, at minimum: every `BallKind`;
wides with and without runs run; no-balls with runs off the bat; free-hit derivation
including the wide-does-not-consume rule; every dismissal type including the
free-hit-allowed subset (`run_out`, `hit_wicket`, `obstructing`, `handled_ball`);
strike rotation on odd/even runs; end-of-over rotation; over completion including
The Hundred's 10-ball ends; per-bowler over caps; all four innings-termination
reasons; and the boundary conditions on each.

**Runtime alarm.** In Stage 1, when the server's reply disagrees with the local
prediction, log it on a dedicated `match.parity` channel with both computed states
and the input that produced them. This is a production oracle that no test suite can
match, and it runs on real matches for as long as Stage 1 does.

---

## 9. Stage 1 — local engine, instant apply, still online

**Scope.** Port the engine to Dart. On tap: run it locally, apply the result to
`ScoringState` immediately, and dispatch the network write in the background. No
local durability yet, no queue, no offline.

**What the user sees.** The scoreboard moves on the tap. The pad never disables. A
small, non-blocking indicator shows unconfirmed deliveries; it clears as the server
confirms.

**Failure handling.** A failed write rolls the delivery back with a clear message
("Not recorded — check connection"), the same rollback discipline as any optimistic
update. Because there is no local log yet, a failure genuinely loses the delivery —
which is the status quo, not a regression.

**Why this stage exists.** It is worth shipping on its own for G1. But its real
purpose is **de-risking D2**: every delivery in every real match becomes a parity
test, run while the server is still reachable and authoritative. A season of
production traffic through the parity alarm is stronger evidence of engine
equivalence than any test suite, and it is collected *before* any match data depends
on the Dart engine offline.

Going straight to Stage 2 means trusting an unproven port with data that has no
server to fall back on. That is the single sequencing decision I feel strongest
about.

**Exit criterion.** Zero unexplained parity alarms across an agreed volume of real
deliveries.

---

## 10. Stage 2 — the local write-ahead log and outbox

Only after §9's exit criterion is met.

### 10.1 Local schema

Two drift tables, added to `AppDatabase` with a schema bump and migration.

```
ScoringOps                       -- the write-ahead log
  opId          text  PK         -- client uuid; the idempotency key
  matchId       text
  inningsNumber int
  localSeq      int              -- monotonic per (match, innings)
  kind          text             -- 'ball' | 'undo'
  payload       text             -- json: the BallDraft, or the undone opId
  createdAt     datetime
  syncedAt      datetime?        -- null = still owed to the server
  attempts      int
  lastError     text?

ScoringSnapshots                 -- resume without replaying from ball 1
  matchId       text
  inningsNumber int
  state         text             -- json: innings state at the last synced op
  updatedAt     datetime
  PRIMARY KEY (matchId, inningsNumber)
```

`ScoringOps` is append-only. The local innings state is a fold of the snapshot plus
the ops after it — recomputable at any time, which is what makes crash recovery a
non-event.

### 10.2 Write path

1. Generate `opId`; append to `ScoringOps` **before** touching UI state. The log is
   the durable record of intent; anything not in it never happened.
2. Fold it through the Dart engine; update `ScoringState`. UI moves.
3. Nudge the outbox.

Step 1 preceding step 2 is deliberate: if the process is killed between them, the
delivery is recoverable. The reverse order loses it.

### 10.3 Outbox

Drains strictly in `localSeq` order — the engine is sequential, so out-of-order
application is meaningless. Stops on the first failure rather than skipping ahead.
Retries with exponential backoff, resumes on connectivity regain
(`isOnlineProvider` already exists), and on app foreground.

**Sign-out wipes it**, via `AppDatabase.clear()`, exactly as the messages cache does.
An unsynced op belongs to the signed-in scorer.

---

## 11. Sync, idempotency and reconciliation

**Idempotency.** `opId` travels with the request. The server records applied `opId`s
per innings and, on replay, returns the stored result rather than re-applying. This
is what makes "request sent, reply lost" safe — the single most common failure on a
flaky ground connection, and the one that would otherwise double-record a delivery.

> Requires a server change: an `applied_ops` table (or a unique column on `balls`)
> keyed by `opId`, checked inside the existing transaction.

**Reconciliation.** The server's reply carries the authoritative ball and innings
row (already true as of 2026-08-20). Compare against the local prediction:

- **Agree** → mark the op synced, advance the snapshot. Normal path.
- **Differ** → **server wins.** Overwrite local state, raise a parity alarm, and
  tell the scorer the scorecard was corrected. Never silent: a silent correction is
  how a scorer loses trust in the app permanently.
- **Rejected (422)** → the engine refused the delivery. Local prediction was wrong
  about legality. Roll the op back and surface the server's reason.

---

## 12. Undo across the offline boundary

Undo is the only mutation and needs care because the ball may be in one of three
states.

| Ball state | Undo behaviour |
|---|---|
| Unsynced, still in the local WAL | Delete the op locally. Nothing was ever sent. No server call |
| Synced | Append an `undo` op referencing the target `opId`; drains to the existing `undo_last_ball` path |
| In flight | Block until the write settles, then take one of the two rows above. Do **not** race a delete against an in-flight insert |

**Invariant:** undo only ever targets the last delivery. That is enforced today and
must remain enforced — undo of an arbitrary ball would turn this from a log into a
mutable document and forfeit everything in §3.

---

## 13. Conflict, multi-scorer and the version guard

The `version` optimistic lock on `match_innings_state` already exists and is already
sent as `p_expected_version`.

Offline widens the window in which a second scorer could write. Given N1 this is an
anomaly, not routine, so the handling is deliberately blunt (**D5**):

1. Server rejects with 409 on version mismatch.
2. Client **stops draining** — it does not skip, retry-with-newer-version, or merge.
3. The scorer is shown: *"Someone else has scored this innings. Your unsent
   deliveries could not be applied."* with the count and the option to review them.

Rebasing a local log onto a diverged server log is technically possible and I am
recommending against it: it means reordering deliveries in a scorecard, and there is
no reading of the Laws under which that is safe to do automatically. A human should
decide.

---

## 14. What spectators see

Unchanged in mechanism. The server still broadcasts on write, so spectators receive
deliveries as they sync. When the scorer is offline, the spectator feed **lags by
the offline duration and then catches up in a burst**.

This is inherent — the deliveries genuinely have not left the ground. It should be
made legible rather than hidden: a "last updated N minutes ago" indicator on the
spectator scoreboard, so a follower can tell the difference between "nothing is
happening" and "the scorer is out of coverage."

---

## 15. Edge cases catalogue

| # | Case | Handling |
|---|---|---|
| E1 | App killed mid-innings, offline | State = snapshot + unsynced ops. Resumes exactly |
| E2 | Reply lost after server applied the write | `opId` dedupe returns the stored result. No double-record (§11) |
| E3 | Innings ends while offline | Engine emits the termination event locally; the transition is confirmed on sync. Do **not** navigate to the result screen on a local-only prediction — a match result is not provisional |
| E4 | Device clock wrong | Nothing depends on wall-clock time. Ordering is `localSeq`; timestamps are display-only |
| E5 | Battery dies mid-over | Same as E1 |
| E6 | Scorer signs out with unsynced ops | Warn explicitly and require confirmation before `AppDatabase.clear()` discards them |
| E7 | Two devices, same scorer account | Second device's ops trip the version guard (§13) |
| E8 | Local storage full | Drift write fails → refuse the tap with a clear error. Never accept a delivery that could not be logged |
| E9 | Free hit spans an offline boundary | Derived from the ball log, which is local and complete. Correct by construction |
| E10 | Server engine updated while a client holds unsynced ops | Server is authority; divergent replay surfaces as a parity alarm. Vectors are versioned alongside the engine |
| E11 | Match completed on the server while scorer offline | Sync rejects; scorer is told the match was closed elsewhere |
| E12 | Very long offline period (whole innings) | ~250 ops. Well within a single drain; no batching required |

---

## 16. Proposed CLAUDE.md amendment

Approving this document means replacing the ONLINE-ONLY banner's scope. Proposed
text, to sit alongside the existing `messages` exemption:

> **EXEMPTION 2 (2026-08-20) — `matches` live scoring write path only.**
> Ball-by-ball scoring is **local-first**. Deliveries are computed by a Dart port of
> the scoring engine, appended to a drift-backed write-ahead log (`ScoringOps`,
> `ScoringSnapshots`), applied to the UI immediately, and drained to Supabase by a
> background outbox keyed on a client-generated idempotency uuid. The server remains
> the **authority**: it recomputes every delivery with `_shared/scoring/engine.ts`
> and its answer overrides the client's on any disagreement.
>
> This exemption is **strictly scoped to recording deliveries in an already-started
> innings.** Match creation, toss, lineup lock, challenges, and every read surface
> outside the scoring screen remain online-only. There is still NO general sync
> service and NO LWW — the queue is single-writer and append-only, which is why it
> needs neither.
>
> The two engines are held together by shared golden vectors
> (`_shared/scoring/vectors.json`) executed by both the Deno and Dart test suites.
> **A change to scoring rules is a change to the vectors first.** Do not modify
> either engine without updating the vectors, and do not let the suites diverge.
>
> Do NOT generalise this to other features. The properties that make it safe here —
> single writer, append-only, deterministic, bounded — do not hold elsewhere.

Rule 7 and §14's reference table would need corresponding edits.

---

## 17. Build plan

| Slice | Content | Gate |
|---|---|---|
| **S0** ✅ | Extract `vectors.json` from `engine.test.ts`; Deno suite reads it. No behaviour change | **Met** — 35 vectors + 2 meta, 37/37 green; mutation-tested |
| **S1** ✅ | Dart engine port + Dart vector suite | **Met** — 38/38 in both, off one `vectors.json`; parity guard mutation-tested |
| **S2** ✅ | Stage 1 wiring: local apply, background write, parity alarm on `match.parity` | **Built** — pad no longer blocks; alarm + category tagging live. Soak (S3) pending |
| **S3** | *Soak.* Real matches on S2. No code | Agreed delivery volume, alarms triaged |
| **S4** | Server: `applied_ops` idempotency inside the transaction | Replay test double-records nothing |
| **S5** | Drift tables + migration + WAL append before UI apply | Kill-and-resume test passes |
| **S6** | Outbox: ordered drain, backoff, connectivity + foreground triggers | Airplane-mode innings syncs intact |
| **S7** | Undo across the boundary (§12); conflict UX (§13); sign-out guard (E6) | Edge catalogue covered |
| **S8** | Spectator staleness indicator (§14); drop dead `record_ball` (D9); CLAUDE.md amendment | Docs true |

S0–S3 deliver G1 and carry no offline risk. S4–S8 deliver G2.

---

## 18. Risks

| Risk | Severity | Mitigation |
|---|---|---|
| Dart/TS engines diverge | **High** | Shared vectors (§8) + production parity alarm + S3 soak before anything depends on it |
| Local WAL corrupted or lost | **High** | Append-before-apply; snapshot + ops is recomputable; E8 refuses unloggable taps |
| Idempotency gap double-records a delivery | **High** | S4 gated on an explicit replay test; `opId` generated once at append, never regenerated on retry |
| Scope creep into general offline-first | Medium | Amendment text (§16) is explicit; architecture test could assert no other feature imports the scoring WAL |
| Complexity exceeds the team | Medium | Staging: S0–S3 are independently valuable and revert cleanly |
| Silent correction erodes scorer trust | Medium | §11 mandates visible correction, never silent |

---

## 19. Decisions taken

The forks in §4 were delegated rather than answered individually. These are the
answers, with the reasoning, so they can be challenged later on the merits.

### 19.1 — D1: amend ONLINE-ONLY. **Yes**, but the amendment lands at S8

Accepted on the scope in §16. The amendment text is **not** written into CLAUDE.md
yet, and deliberately so: CLAUDE.md is the agent-readable contract, and text saying
*"ball-by-ball scoring is local-first"* would be false until S5–S6 exist. A contract
that describes unbuilt behaviour misleads every future session that reads it.

The decision is recorded here now; CLAUDE.md changes when the code does, at **S8**,
exactly as the build plan already sequences it.

### 19.2 — Soak volume: **path coverage, not delivery count**

Raw volume is the wrong gate. 2,000 dot balls prove almost nothing; twenty free hits
and ten innings terminations prove a great deal. The exit criterion for S3 is
therefore **both**:

- **≥ 2,000 real deliveries** through the parity alarm, **and**
- **every vector category in §8 observed at least once in production** — with a
  floor on the paths tests are thinnest on: ≥ 20 free-hit deliveries, ≥ 10 innings
  terminations covering all four reasons, ≥ 5 per-bowler over-cap rejections, and at
  least one delivery of every `BallKind` and every dismissal type reachable in play.

Both conditions, zero unexplained alarms. A tournament will usually satisfy the count
long before it satisfies the coverage, and the coverage is the part that matters.

Instrumentation implication: the parity alarm must also record **which category** a
delivery fell into, so coverage is measurable rather than estimated. That is a small
addition to S2 and should be built there, not retrofitted.

### 19.3 — §13 conflict: **refuse and surface**, and never discard

Confirmed. No auto-rebase: reordering deliveries in a scorecard is not something
software should decide.

One addition to the design: on conflict, the unsent deliveries must remain
**visible, readable and exportable** — a plain list of what could not be applied,
with the option to copy it. "Your deliveries could not be applied" is only
acceptable if the scorer can still see what they were. Losing them silently would be
worse than the original problem.

### 19.4 — E3 result from a local prediction: **never**

Confirmed, and worth stating as an invariant rather than a preference.

The local engine **may** enter the innings-complete state — it stops accepting
deliveries, shows the innings as ended, and says it is waiting to confirm. It **may
not** render a result, declare a winner, or navigate to the result screen on local
computation alone. A score can be provisional; a result cannot. If a match result
ever appears and then changes, the app has told a team it won and then taken it back,
and no amount of correctness elsewhere recovers from that.

### 19.5 — §14 spectator lag: **acceptable, if it is legible**

Accepted. The requirement is that a follower can always distinguish *"nothing is
happening"* from *"the scorer is out of coverage."*

Concretely: the spectator scoreboard shows `LIVE` when the last delivery arrived
within the expected cadence, and `LIVE · updated 4m ago` once it has not. The
threshold should be generous — overs genuinely take minutes — so this reads as
information, not as an error state.

### 19.6 — Region: **unresolved, and a prerequisite for S4**

I cannot determine this from outside; the project sits behind Cloudflare and DNS
reveals nothing about the origin.

Recommendation: confirm it from the dashboard **before S4**. It does not change
whether this plan is right, but it changes the payoff distribution — a distant region
lowers Stage 1's ceiling (the background write still lags) and raises Stage 2's value
(local durability matters more when every sync is expensive). If the region turns out
to be far from Pakistan, migrating it is likely cheaper than anything in S4–S8 and
should be sequenced first.

---

## 20. Tooling: running the vector suite

`engine.test.ts` documents its own runner — *"Run: `deno test`"* — but Deno is not
installed on the development machine. **It does not need to be.** Docker is already
running for the local Supabase stack, so the suite runs in a container:

```
docker run --rm -v "$PWD":/app -w /app denoland/deno:latest \
  test --allow-read --allow-net supabase/functions/_shared/scoring/engine.test.ts
```

This is the command CI should use too — it pins the runtime rather than depending on
whatever Deno a given machine happens to have, which matters more than usual here
because this suite is the parity contract.

---

## 21. Progress

### S0 — complete (2026-08-20)

`vectors.json` is extracted and is now the executable specification; `engine.test.ts`
is a runner over it. No engine behaviour changed.

**35 vectors** across 12 categories (`legal`, `wide`, `no_ball`, `bye`, `leg_bye`,
`wicket`, `validation`, `over_end`, `termination`, `bowler_cap`, `free_hit`,
`hundred`), plus two meta-tests that fail if the fixture is emptied or grows a
duplicate name. 37/37 green.

Two design points worth carrying into S1:

- **`expect` is a partial match**, not full equality — a vector asserts only the keys
  it names. This keeps vectors additive: tightening one case never forces every other
  case to spell out fields it does not care about. The Dart runner must implement the
  same semantics or the two suites are not actually running the same spec.
- **The harness was mutation-tested.** A partial-match assertion can pass vacuously if
  the subset logic is wrong, which would leave the suite green while checking nothing.
  Flipping one expected value produced a clean failure with the offending key named.
  Any reimplementation of the runner should be mutation-tested the same way before it
  is trusted.

### S1 — complete (2026-08-20)

`lib/features/matches/domain/scoring/` holds the Dart port: `scoring_types.dart`
(data in / data out) and `scoring_engine.dart` (`applyBall`). Pure Dart —
no Flutter, no Riverpod, no I/O — so Rule 1 holds and the vectors remain a
complete specification.

**38/38 green in both suites**, driven by the same `vectors.json`.

#### A real divergence the port would have shipped

`runsRun` (runs actually *run*, which drives strike rotation) evaluates to **-1**
on a no-ball carrying no penalty. On negative operands:

| | `-1 % 2` | rotates? |
|---|---|---|
| JavaScript (the authority) | `-1` | no |
| Dart `%` (Euclidean) | `1` | **yes** |
| Dart `.remainder(2)` | `-1` | no ✓ |

A naive port using `%` would have silently rotated strike differently from the
server on that input — a wrong scorecard behind a right-looking scoreboard, which
is precisely the failure mode §6 describes. The engine uses `.remainder(2)`, and a
**parity-guard vector** now pins it. Reintroducing `%` fails that vector with
`Expected 'S', Actual 'N'` — verified by mutation, not assumed.

This is the concrete argument for D3. The bug is invisible to code review, invisible
to the type system, and reachable only through one malformed input. Only an
executable spec run against both implementations catches it.

#### Decisions worth carrying forward

- **The engine has its own minimal types**, not the domain entities. `Ball` and
  `MatchInningsState` carry ids, timestamps and persistence concerns the engine has
  no business knowing; mapping happens at the edge. This keeps `applyBall` pure and
  keeps the Dart contract field-for-field with the TypeScript one.
- **`BallKind` / `WicketType` are reused** from `domain/entities/ball.dart` — their
  `wire` values are already the strings the TS engine speaks, and a third copy of
  those enums would be one more thing to drift.
- **Both runners implement partial matching identically.** If they disagreed about
  what "expected" means, the suites would not be running the same spec even while
  reading the same file.

#### Pattern variation to document (CLAUDE.md §13)

`domain/scoring/` is a new subfolder under a feature's domain layer — the documented
layout is `entities` / `value_objects` / `repositories`. A pure rules engine is not
any of those, but it is the most domain-ish code in the app: no framework, no I/O,
only cricket. Flagging it here rather than forcing it into `entities/`. This should
land in the CLAUDE.md edits at **S8**.

### S2 — built (2026-08-20)

A tap now costs **no network time**. The local engine computes the delivery, the
screen paints it, and the write goes out behind it.

**New in `domain/scoring/`** — all pure, all tested:

| File | Role |
|---|---|
| `scoring_adapter.dart` | domain entities → engine inputs; derives `prevNonWideKind` and `bowlerLegalBalls` from the ball log |
| `scoring_categories.dart` | which vector categories a delivery exercised — the coverage measurement §19.2 requires |
| `scoring_parity.dart` | did the two engines agree, and precisely where |

**Controller.** `_record` predicts → paints → enqueues. `_settle` reconciles the
server's answer and raises the alarm. `_rollback` removes a delivery whose write
failed.

**211 Dart tests + 38 Deno**, analyzer clean.

#### Four things that needed care

- **Writes are serialised, the paint is not.** Deliveries are sequential and the
  server holds an optimistic version lock, so two entered inside one round trip
  would race and the second would lose the version check against a row the first
  had not committed. An in-memory chain orders them. This is *not* the durable
  outbox — that is S6 — but the ordering requirement arrives with S2, not later.
- **The pad no longer gates on `isBusy`, but undo still does.** There is nothing to
  undo until the delivery has actually reached the server.
- **`MatchInningsState.copyWith` needed explicit `clear*` flags.** Null is a
  meaningful value for all three on-field ids — a wicket clears the striker, an over
  end clears the bowler — and `id ?? this.id` cannot express it. Without the flags a
  projected wicket would silently keep the dismissed batter at the crease.
- **The parity check deliberately ignores server-assigned fields** (`seq`, ball id,
  timestamps). Flagging those would fire on every delivery and train everyone to
  ignore the channel, costing us the one alarm that matters.

#### A side benefit worth naming

Illegal deliveries are now refused **locally, instantly**, with the same error the
server would return — the round trip was pure cost. A free-hit dismissal by `bowled`
is rejected before it leaves the phone, which is defence in depth behind the wicket
sheet's own filter.

#### Known duplication, deliberately not addressed here

`ScoringState` still derives `freeHitActive`, `inningsOver` and `overJustCompleted`
itself (§6), and those now sit alongside an engine that computes the same things.
Consolidating the screen onto the engine's `events` is the right end state, but it
rewrites how the whole screen derives state and does not belong in the same slice as
the write path. **Scheduled for S7.**

### Edge-function rewrite — verification (2026-08-20)

The `record-ball` changes from §5 were unverified when written. The riskiest part
was not the latency work but the **security boundary**: authorization moved inside
the write transaction, resolving the caller through a GUC we set ourselves on a
direct pooled connection. Verified against the local stack:

| Check | Result |
|---|---|
| `auth.uid()` with no claims on a direct connection | `null` |
| `auth.uid()` after `set_config('request.jwt.claims', …, true)` | resolves to `sub` ✅ |
| `auth.uid()` **after COMMIT** | back to `null` ✅ — no leak across pooled requests |
| `is_team_manager()` as the team owner | `true` ✅ |
| `is_team_manager()` as a stranger | `false` ✅ — the boundary still bites |
| `is_team_manager()` with no claims | `false` ✅ — fails closed |
| `deno check` on the rewritten function | clean ✅ |
| `getClaims` present in resolved supabase-js | yes ✅ |

The third row is the one that mattered. Connections are pooled (`max: 3`) and reused
across requests, so a session-scoped setting would have carried one scorer's identity
into the next request. `is_local = true` is what prevents that, and it is now tested
rather than assumed.

#### Correction: the project DOES use asymmetric JWT keys

An earlier note in this workstream said local auth used a symmetric secret, inferred
from the `JWT_SECRET` in `supabase start` output. That was wrong — that value is the
legacy secret. The JWKS endpoint shows **ES256** signing keys on both local and
production:

```
/auth/v1/.well-known/jwks.json → {"keys":[{"alg":"ES256","kty":"EC",…}]}
```

So `getClaims()` verifies the JWT **locally against a cached JWKS** rather than
calling the Auth server. The hop it replaces was real, and removing it is a real
saving on every delivery — not merely a no-op with a safe fallback.

#### Still unverified

The function has **not been executed end to end**. The security mechanism, the
typecheck and the client are all verified; what is not is the whole request path
against a real match — `returning *` shaping the innings row, and the response
reaching the client in the expected form. That needs a full fixture (auth user →
team → match → match_players → innings state) plus a signed JWT.

**Do that before deploying to production.** The client degrades gracefully if the
innings row is absent, so a bad deploy is not destructive — but it would leave the
parity alarm's innings half dark, which is precisely the half worth watching.

### Next: S3 — soak

No code. Real matches on S2, watching `match.parity`, until §19.2's two conditions
are met: ≥2,000 deliveries **and** every vector category observed, zero unexplained
alarms.

Two prerequisites before the soak means anything:

1. **Deploy `record-ball`.** Without it the reply carries no innings row, so
   `compareParity` skips the innings half — and that half is where strike rotation
   lives, the exact failure the alarm exists to catch.
2. **Get S1–S2 onto the device.** Nothing in this workstream has run on hardware
   yet.
