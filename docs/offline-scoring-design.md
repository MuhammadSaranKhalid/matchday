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
>
> 🔄 **REVISED 2026-08-22 — the server is no longer the authority on cricket.**
> **D3** (two engines held together by golden vectors) and **D5/§19.3** (server wins
> on disagreement) are **superseded**. The phone owns the arithmetic; `record-ball`
> authorizes, de-duplicates, stores and totals, and does not recompute the delivery.
> See [§19.7](#197--d10d12-the-phone-is-the-authority-2026-08-22) for the reasoning.
> Sections 7, 8, 13 and 16 are rewritten to match; everything else stands.

---

## Table of contents

1. [Problem statement](#1-problem-statement)
2. [Goals & non-goals](#2-goals--non-goals)
3. [The core insight: this is the easy case of local-first](#3-the-core-insight-this-is-the-easy-case-of-local-first)
4. [Decisions log](#4-decisions-log)
5. [Current state of the codebase](#5-current-state-of-the-codebase)
6. [The engine duplication that already exists](#6-the-engine-duplication-that-already-exists)
7. [Architecture overview](#7-architecture-overview)
8. [The golden vectors: now the engine's specification](#8-the-golden-vectors-now-the-engines-specification)
9. [Stage 1 — local engine, instant apply, still online](#9-stage-1--local-engine-instant-apply-still-online)
10. [Stage 2 — the local write-ahead log and outbox](#10-stage-2--the-local-write-ahead-log-and-outbox)
11. [Sync, idempotency and reconciliation](#11-sync-idempotency-and-reconciliation)
12. [Undo across the offline boundary](#12-undo-across-the-offline-boundary)
13. [What the server checks](#13-what-the-server-checks)
14. [What spectators see](#14-what-spectators-see)
15. [Edge cases catalogue](#15-edge-cases-catalogue)
16. [CLAUDE.md amendment — applied](#16-claudemd-amendment--applied-2026-08-22)
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
- **G3.** ~~The server remains the **authority** on the scorecard.~~ **Revised
  2026-08-22:** the **scoring device** is the authority on the arithmetic of the
  innings it is scoring. The server authorizes the writer, rejects duplicates,
  stores the deliveries and totals them. It does not recompute them. A *score* may
  therefore be provisional only in the sense that it has not uploaded yet — not in
  the sense that it may be corrected by a second opinion.
- **G4.** ~~Any divergence between the client's and the server's arithmetic is
  detected and surfaced.~~ **Revised 2026-08-22:** with one engine there is no
  second arithmetic to diverge from. What must still be detected and surfaced is a
  **delivery that cannot be stored** — rejected writer, finished match, or a queue
  that will not drain. Silence is still not an option; the thing being watched has
  changed.
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
| D3 | Engine parity mechanism | ~~**Shared golden vectors** run against both implementations in CI~~ | ~~30 vectors already exist in `engine.test.ts`. One executable spec governs both~~ | **Superseded by D10** (2026-08-22) |
| D4 | Stage 1 (instant, online) ships before Stage 2 (offline) | **Yes** | Every delivery in Stage 1 is a free production parity test while the server is still reachable and authoritative | **Accepted** |
| D5 | Conflict resolution model | ~~**Refuse and surface.** Server wins; scorer is told~~ | ~~Single writer means conflict is a genuine anomaly~~ | **Superseded by D11** (2026-08-22) |
| D6 | Local store | **drift**, reusing `AppDatabase` | Already in the project for `WizardDrafts` + the messages cache. No new dependency | Recommended |
| D7 | Idempotency key | **Client-generated uuid per delivery** | Makes replay safe when the network flaps mid-request. Standard outbox practice | Recommended |
| D8 | Rust/WASM shared engine | **No** | Genuinely one implementation, but a whole toolchain for a 214-line pure function. Revisit only if D3 proves insufficient | Recommended |
| D9 | Drop the dead `record_ball` plpgsql function | **Yes** | Superseded by the edge function but never dropped. Leaving it means *three* implementations | Recommended |
| D10 | Where the rules of cricket live | **One engine, on the phone.** The server does no cricket arithmetic | The phone must compute unaided during a signal gap — that is the whole premise. A server that recomputes is a second opinion nobody asked for, and keeping two in step forever is the cost | **Accepted** 2026-08-22 |
| D11 | What the server checks | **Writer, duplicate, liveness — never cricket.** Is this person permitted to score this innings; have I seen this delivery before; is this match still live | These are the three things a phone cannot be trusted on, and none of them need the Laws. Cheap, and they are what actually protects the data | **Accepted** 2026-08-22 |
| D12 | Handover between innings | **Batting side scores its own innings**; control passes at the innings break, after the first innings has uploaded | Matches how a real match is scored, and gives the single-writer property a natural boundary rather than a policy | **Accepted** 2026-08-22 |
| D13 | Totals on the server | **Derived by summing the stored deliveries**, not accumulated by a per-ball counter | Makes undo "remove the last row and re-total" instead of "carefully subtract", which is where the reversal bugs live. §12's invariant becomes trivial to honour | **Accepted** 2026-08-22 |

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
  │  record-ball     │  authorize · de-duplicate · store · total
  │  (no cricket)    │  broadcasts on write
  └────────┬─────────┘
           │ stored ball + innings totals (summed, not recomputed)
           ▼
     mark synced
```

**Revised 2026-08-22 (D10/D11).** The engine runs in exactly one place: the phone.
`record-ball` no longer recomputes the delivery — it checks the three things the
phone cannot be trusted on (§13), writes the row, sums the innings, and broadcasts.
It has no opinion about whether that was a wide.

This is what the offline requirement already implied. During a signal gap the phone
computes the innings unaided because nothing else can; a server that recomputes the
same balls afterwards is a second opinion that must be kept in step forever, and
the disagreements are silent when it drifts. One engine cannot disagree with itself.

The client's answer is not "provisional pending recomputation" — it is the answer.
What is provisional is only whether it has **reached** the server yet.

---

## 8. The golden vectors: now the engine's specification

> 🔄 **Revised 2026-08-22.** This section previously described a *parity contract*
> between two engines. With D10 there is only one engine, so there is no parity to
> keep. The vectors survive — and matter just as much — but their job has changed:
> they are no longer a treaty between two implementations, they are **the executable
> specification of the rules of cricket** for the single Dart engine.
>
> Everything below about density, purity and "a rule change is a vector change
> first" stands unaltered. What is retired is the claim that CI must run them
> against a second implementation, and the §7 runtime parity alarm — with one
> engine there is nothing to compare a delivery against.
>
> **Do not delete `vectors.json`.** It is the only complete written statement of the
> scoring rules in the project, and the Dart suite must keep executing it.

**The contract.** `supabase/functions/_shared/scoring/vectors.json` holds cases of
the form `{name, state, format, input, ctx, expected}`. The Dart test suite loads it
and asserts the expected output for every one. CI fails if the engine diverges from
the spec.

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
| Synced | Append an `undo` op referencing the target `opId`; drains to a server call that **deletes the last stored delivery and re-totals** (D13). There is no reversal arithmetic to get wrong — the totals are a sum of what remains |
| In flight | Block until the write settles, then take one of the two rows above. Do **not** race a delete against an in-flight insert |

**Invariant:** undo only ever targets the last delivery. That is enforced today and
must remain enforced — undo of an arbitrary ball would turn this from a log into a
mutable document and forfeit everything in §3.

---

## 13. What the server checks

> 🔄 **Rewritten 2026-08-22 (D11/D12).** This section previously described an
> optimistic-lock conflict protocol built on `p_expected_version`. That machinery
> guarded against a second scorer writing the same innings — which D12 now prevents
> structurally rather than detecting after the fact.

**The writer is decided by the match, not by a race.** The batting side scores its
own innings; control passes at the innings break (D12). Exactly one device is
entitled to write a given innings, and `_can_score_innings(match, innings)` — which
takes the innings number precisely so it can answer this — is the rule.

So `record-ball` checks three things, none of which are cricket:

| Check | Question | Failure |
|---|---|---|
| **Writer** | Is this account permitted to score *this innings* of this match? | `403` — and it is a real error, not a race. Someone is scoring an innings that isn't theirs |
| **Duplicate** | Have I already stored a delivery with this idempotency key (D7)? | `200`, returning the delivery already stored. A phone retrying after a dropped connection must not double-record |
| **Liveness** | Is this match still live — not completed, abandoned or walked over? | `409`. The innings is closed; the queue should stop, not retry |

**The version column is no longer a lock.** It survives as a change counter for
readers, but nothing gates a write on it. A single entitled writer cannot race
itself, and gating on it caused exactly one real bug: a scorer tapping a second ball
before the first reply landed sent a stale expected-version and had the delivery
refused.

**If the writer check ever fails**, §19.3's rule still applies in full: the unsent
deliveries must stay **visible, readable and exportable**. Never discard silently.

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

## 16. CLAUDE.md amendment — ✅ APPLIED 2026-08-22

> **Applied.** §19.1 originally held this edit back until S8, on the reasoning that
> a contract describing unbuilt behaviour misleads every future session. The owner
> released it on 2026-08-22 because the machinery now exists in the tree — the Dart
> engine, the drift WAL and the outbox are all built (see §21, S5+S6) — so the
> amendment now describes what *is*, not what is planned. The text below was
> corrected for D10/D11 before being written into CLAUDE.md: the earlier draft said
> the server recomputes every delivery and overrides the client, which is no longer
> true.

Text as written into CLAUDE.md, alongside the existing `messages` exemption:

> **EXEMPTION 2 (2026-08-20) — `matches` live scoring write path only.**
> Ball-by-ball scoring is **local-first**. Deliveries are computed by a Dart port of
> the scoring engine, appended to a drift-backed write-ahead log (`ScoringOps`,
> `ScoringSnapshots`), applied to the UI immediately, and drained to Supabase by a
> background outbox keyed on a client-generated idempotency uuid. The server remains
> **not** recompute the delivery — it authorizes the writer, rejects duplicates by
> idempotency key, stores the row and sums the innings.
>
> This exemption is **strictly scoped to recording deliveries in an already-started
> innings.** Match creation, toss, lineup lock, challenges, and every read surface
> outside the scoring screen remain online-only. There is still NO general sync
> service and NO LWW — the queue is single-writer and append-only, which is why it
> needs neither.
>
> The rules of cricket live in **exactly one place**: the Dart engine. Its
> specification is `_shared/scoring/vectors.json`, executed by the Dart test suite.
> **A change to scoring rules is a change to the vectors first.** Do not add cricket
> arithmetic to the edge function or to a database trigger — that is how three
> disagreeing implementations appeared once already.
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
| **S5** ✅ | Drift tables + migration + WAL append before UI apply | **Met** — 120-delivery offline innings survives a DB reopen |
| **S6** ✅ | Outbox: ordered drain, connectivity + foreground triggers | **Met** — offline over kept, drains in order on reconnect |
| **S7** ◐ | Undo across the boundary (§12); conflict UX (§13); sign-out guard (E6). **Rule consolidation done early** | Edge catalogue covered |
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

> **Superseded 2026-08-22.** The amendment has been applied — see §16. The reasoning
> above was sound while the local-first machinery was unbuilt; S5+S6 (§21) shipped
> it, so the banner now describes behaviour that exists. The text written into
> CLAUDE.md is D10/D11-corrected, not the 2026-08-20 draft.

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

> 🔄 **Partly superseded 2026-08-22.** The *conflict* this describes — two scorers
> racing the same innings — is prevented structurally by D12 rather than detected by
> a version guard, so the 409-on-mismatch protocol is gone (§13 rewritten). **The
> never-discard rule below survives untouched and applies to any refused write.**

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

### 19.7 — D10–D12: the phone is the authority (2026-08-22)

The original plan had the server recompute every delivery and win any disagreement,
with shared golden vectors keeping the two engines honest. That was coherent, and it
is being overturned deliberately.

**Why it changes.** The offline requirement was restated on the ground: signal at
these grounds drops for minutes at a time and comes back. During those minutes the
phone computes the innings unaided, because there is nothing else. So the phone is
already the authority for part of every match — the question was only whether to
admit it. Keeping a second engine to re-derive the same balls afterwards buys one
thing (catching a buggy client) and costs three: two implementations that must agree
forever, a parity alarm that must be watched, and a soak period before anyone can
trust the result.

**What made the trade tip.** D12. Once the batting side scores its own innings and
control passes at the break, exactly one device is entitled to write a given innings
and the entitlement is decided by the match rather than by a race. The scenarios a
server recomputation would have caught are mostly scenarios that can no longer
happen.

**What is given up, stated plainly.** A phone that is buggy, tampered with, or
running an old build can now write a wrong scorecard, and the server will store it.
The mitigations are that the writer is authenticated and entitled, the log is
append-only and attributable, and the rules have one tested implementation rather
than three that drift. That is a real reduction in defence and it is accepted with
open eyes.

**What did not change.** §19.4 stands and is worth restating because it is the line
this revision does *not* cross: the phone may show an innings as complete and
awaiting confirmation, but it **may never declare a result**. A score can be
provisional. A result cannot.

**Also settled the same day:** undo remains one step back, the last delivery only
(§12, unchanged — it was already the invariant). D13 makes it cheap.

---

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

#### End-to-end execution — verified (2026-08-20)

The function was then run for real against the local stack: a fixture match, a
genuine signed-in scorer (created through the auth API, not a hand-rolled token),
and live HTTP requests.

| Case | Result |
|---|---|
| Single off the bat | `ok`, ball written, **innings row returned**, strike rotated ✅ |
| Wide | `ball_in_over: 0` sentinel, legal count unchanged, +1 extra ✅ |
| Free-hit dismissal by `bowled` | rejected `free_hit_dismissal` ✅ — server agrees with the client |
| `version` increment | default 0 → 1 → 2 across deliveries ✅ |

#### A severe bug this caught, that code review would not have

The reply serialises `version` (a Postgres `bigint`) as a **JSON string** — `"1"` —
because the function reads it over a direct postgres.js connection, and postgres.js
renders bigint as a string to avoid JS precision loss. The realtime broadcast, built
with `to_jsonb(new)`, sends the same field as a **number**.

`MatchInningsStateDto` accepted only the number. Parsing the reply threw
`type 'String' is not a subtype of type 'num?'`, the repository turned that into a
failure, and the controller rolled the delivery back — so **every ball would have
appeared to fail while the server had in fact recorded it**. The scorer would have
seen their scorecard refuse every entry.

Nothing in the type system, the analyzer, or the Dart test suite could see this: both
sides were internally consistent, and the mismatch existed only on the wire between
them. It took executing the real function against a real database.

`version` now parses leniently (`intFromWire`), with tests covering both routes,
their agreement — which the overlay's version comparison depends on — and graceful
degradation to 0 rather than a throw.

**223 Dart tests + 38 Deno.** The local fixture was removed afterwards; the
development database is back as it was.

#### Remaining gap

Only the transaction-pooler path is untested: `supabase start` had stopped
`supabase_pooler_crick`, so the direct connection was used locally where production
goes through Supavisor with `prepare: false`. Worth watching on the first production
deploy, though the `prepare: false` setting is already correct for that mode.

### S5 + S6 — built (2026-08-21). Offline scoring works.

**Re-sequenced.** These were scheduled after the S3 soak. That was wrong, on the
owner's push-back and on the merits: the soak gates whether the Dart engine can be
trusted to *display* a score offline, but the write-ahead log stores the scorer's
**intent** and the server recomputes every op authoritatively on sync. A client
rules bug can produce a wrong provisional display; it can never lose a delivery. So
durability never depended on parity, and gating it behind a 2,000-delivery soak
delayed the one thing the feature exists for.

**What now happens when the signal drops:** the scorer keeps scoring. Each delivery
is written to `scoring_ops` before it is painted and before it is sent. The outbox
drains when it can. Nothing is lost.

#### The contract changed

A tap now returns success when the delivery is **durable**, not when the server has
it. That is the whole point — and it is a real semantic change, which is why eleven
controller tests were rewritten rather than patched.

A failed write no longer rolls the delivery back off the screen. It stays, and is
retried. Rollback-on-failure was the old behaviour and it was precisely the
interruption this feature removes.

#### Failure taxonomy — the distinction that matters

| Outcome | Behaviour | Why |
|---|---|---|
| Could not send (network, server, unknown) | keep, retry forever | This is the offline path. Not an error state — the feature working |
| Server **refused** (validation, not-found) | discard, remove from screen | It will be refused every time; retrying blocks every delivery behind it for the rest of the match |
| **Conflict** (another scorer) | stop the drain, keep everything owed | §13. Reordering a scorecard is not software's decision |

#### Bug found while wiring

`drainOutbox` used a boolean re-entrancy guard, so a caller that awaited it was
turned away whenever a tap had already fired one — making "wait until the outbox is
empty" unanswerable, and silently truncating the drain. It now holds the in-flight
future and joins it.

#### Undo across the boundary (§12)

Where the ball lives decides what undo means: still in the log → discard it, no
server call; already accepted → ask the server; in flight → settle first. Racing a
delete against an in-flight insert is how a scorecard gains a ball nobody can
account for.

#### Retry triggers

New tap, connectivity returning, app foreground. The last two are what turn "saved"
into "sent" without the scorer doing anything.

#### Sign-out

`AppDatabase.clear()` wipes the log with everything else — a privacy guarantee that
must not be weakened. Unsent deliveries are now counted and logged before it runs.
That is a last resort, not the guard: **the scoring screen should warn before a
scorer reaches sign-out with a non-empty outbox, and that UI is not built yet.**

**243 Dart tests + 38 Deno**, analyzer clean.

### The cricket left the server — 2026-08-22

D10/D11/D13 implemented. The rules of cricket now exist in exactly one place.

**Database** (`20260101000400_matches.sql`)
- `fn_process_delivery` and `trg_delivery_insert` **deleted**. That trigger was the
  third implementation of the rules; it rotated strike on `runs_off_bat % 2` (so runs
  run off a no-ball never changed ends), hardcoded a six-ball over, never incremented
  `total_wickets` and never cleared `bowler_id` at the end of an over. A comment block
  now stands where it was, saying why nothing may replace it.
- `_can_score_innings(match, innings)` **written** — it was called by the edge
  function and had never existed. Implements D12: the batting side (derived from the
  toss) scores its own innings; organisers and a practice-match creator may score
  either. `can_score_innings` now delegates to it, so the UI gate and the write path
  cannot drift apart.
- The trigger's `version = version + 1` is gone with it. It used to bump alongside the
  edge function's own bump, advancing the row by 2 per delivery while the client
  projected 1 — which refused the second of any two quick taps.
- `total_extras` added as a generated column summing the five breakdown columns, so it
  can never drift from its parts and `returning *` actually carries it.

**Edge function** (`record-ball/index.ts`)
- `applyBall` and the engine import **removed**. The function now does the four things
  in §13: writer, liveness, duplicate, store — then re-derives the innings by SUMMING
  `match_deliveries` (D13).
- Duplicate handling is a single `on conflict (innings_id, idempotency_key) do nothing`;
  a retry returns the delivery already stored with `200`, so a flapping connection
  cannot double-record and cannot stall the queue either.
- `p_idempotency_key` is now **required**. D7 was accepted on 2026-08-20 and never
  implemented — the client sent nothing and the function minted a fresh uuid per
  attempt, which defeated the unique constraint it was supposed to use.
- Result computation **stays** here, per §19.4.

**Second engine deleted** — `_shared/scoring/engine.ts` and `engine.test.ts` are gone;
nothing imported them once the edge function stopped computing. `vectors.json` stays
and is now executed by the Dart suite alone. A `README.md` in that directory records
why there is no engine there and what must not be added back.

**Client**
- `ComputedDelivery` added to `BallDraft`: the over position, free-hit flag, resulting
  trio, all-out and innings-ended flags. The controller fills it from `applyBall` and
  the repository ships it; the server stores it verbatim.
- `expectedVersion` **removed** end to end.
- A `409` is no longer treated as a benign retry. It now means the innings is not open
  for writing, so the provisional delivery is removed and the screen re-syncs — it used
  to only log, leaving a ball painted that would never be recorded.

**Verification.** `flutter analyze` clean; **265 tests pass** (two added: a draft that
never ran the engine is refused before the wire, and the engine's answer plus the
idempotency key reach it). The SQL and the edge function are **not runtime-verified** —
no local Supabase stack was available in that session (Docker not running, Deno not
installed), so both are reviewed but unexecuted. First run against a real project is
the real test.

### A match can be created and finished again — 2026-08-22

Three faults found reviewing the path end to end, all of which stopped a match
reaching a result. Fixed in `20260822110000_match_creation_and_format_fixes.sql`.

- **`_normalize_match_format(jsonb)` written.** It was called by
  `accept_pool_application` and had never been defined anywhere in this repo — not
  in the current tree, not at HEAD. Every pool acceptance failed at runtime. It now
  guarantees the full key set the client's `MatchDto` and the Dart engine read.
- **`matches.format` no longer defaults to `{}`.** The sane defaults lived in
  `rules_config` under *different* key names (`max_overs`, not `overs_per_innings`),
  so a match created without an explicit format had `overs_per_innings = 0` — which
  the engine reads as **unlimited**. An innings could not end on overs. The column
  default is now the normalised shape, and existing rows are repaired in place.
- **Both match-creation RPCs write the current `match_players` shape.** They were
  still inserting `profile_id` / `is_captain` / `is_keeper` / `team_side = 'a'`, and
  no `display_name` at all — which is NOT NULL. plpgsql bodies are not
  column-checked at CREATE time, so both compiled and failed on first use: no match
  ever got a lineup. Bodies were transformed from the existing sources rather than
  retyped, so only the INSERT changed.
  - Note a modelling loss worth knowing about: the new schema has one `role` enum
    where the old one had independent `is_captain` / `is_keeper` booleans, so a
    captain who also keeps wicket can no longer be recorded as both. Captain wins,
    because that is the role carrying permissions.

**Also closed while in the file:**

- **`start_innings` had no authorization at all** — the only lifecycle RPC without
  one. Any authenticated account could overwrite any match's on-field trio, and
  because it set `status = 'live'` unconditionally it could resurrect a completed
  match. Now gated on `_can_score_innings` (D12: starting an innings is the same act
  as scoring it) and refuses a finished match.
- **`start_innings` derived the batting side from `innings_number % 2`**, hardcoding
  odd = team_a. Every match where team B batted first recorded both innings against
  the wrong side. Now derived from the toss, matching `_can_score_innings` and the
  client.
- **The innings break never sent the chase target.** `innings_break_screen` computed
  it, displayed it, passed it to `_start(target)` — and then called `startInnings`
  without the argument. `target` stayed null, so `targetReached` could never fire and
  a chase ran its full quota of overs after the runs were knocked off.

**Verification.** `flutter analyze` clean, 265 tests pass, and the called-vs-defined
sweep across all 42 migrations now reports no undefined functions. Still not
runtime-verified — no local Supabase stack was available.

### Undo works end to end — 2026-08-22

§12's invariant (undo targets the last delivery, only ever) was already enforced
client-side and the WAL path already handled an unsent delivery. What was missing
was everything after it reached the server.

- **`undo_last_ball` now exists.** It authorizes via `_can_score_innings`, deletes
  the last delivery, and re-derives the innings totals from the remaining ledger —
  D13 in action: nothing is subtracted, so there is no reversal arithmetic to get
  wrong.
- **The on-field trio is restored from the deleted row.** Each delivery stores the
  striker, non-striker and bowler it was bowled to, so undoing ball N means putting
  back what ball N recorded. That is reading a stored fact, not recomputing cricket
  — the D10 line holds.
- **The match transition is reversed.** If that delivery had ended the innings,
  `record-ball` moved the match to `innings_break` or `completed` with a result.
  Undo now puts it back to `live` and clears the result, otherwise the score says
  the innings is live while the match row says it is over and everyone lands on a
  result screen the scorecard no longer supports.
  - 🟥 This is the one path that can **un-declare a result**. §19.4 forbids a
    result being *rendered* from local computation and it still is not — the server
    declared it. But a scorer who mis-taps the winning run must be able to take it
    back, and a permanently wrong match is worse. Flagging it because it is the
    closest anything comes to that line.
- **`ball_deleted` is broadcast.** `watchBalls` has listened for it since it was
  written and nothing ever sent it, so an undo corrected the score everywhere (via
  the innings-state broadcast) while the removed delivery stayed in every
  spectator's ball log. The client also read the removed row's `ball_id`, which has
  not been a column since the reset; it reads `delivery_id` now.
- **`search_path` pinned and privileges revoked** on the new functions, matching
  every other security-definer function in the file.

**And the reason undo was often unavailable even when it worked:** `pendingOpsCount`
was **device-wide**. The scoring screen gates undo on it being zero, and a failed op
is never pruned — `pruneOps` only removes *synced* ones. So a single delivery the
server had permanently refused, in a different match, left every future innings
reading as unsaved and undo greyed out forever. It is now scoped to
(match, innings), with two tests covering it.

**Verification.** `flutter analyze` clean, **267 tests** pass (two added). SQL still
not runtime-verified.

### Duplicate ball positions inside an over — fixed 2026-08-22

Reported from a live session: over 9 recorded as `8.1, 8.2, 8.3, 8.4, 8.2, 8.3,
8.4, 8.5, 8.6` — positions repeating inside one over — and the following over
appearing to end after only two deliveries.

**One bug, two symptoms.** `over_number` and `ball_in_over` are derived from
`legalBallCount` at tap time. `_settle` adopted the server's innings row
wholesale, but that row is only current as of the delivery it confirms. With
further balls already tapped, adopting it dragged the local count backwards, and
the next tap re-issued a position that had already been used. The short over is
the same fault seen from the other end: four of its six deliveries were stamped
with the previous over's numbers, so only two were left to display.

Note what stayed correct throughout: the delivery **count**. Every ball
incremented it by one, so the score, the run rate and the balls-remaining were
all right while the over fell apart — which is why this reached a real match.

**Fix.** `_settle` adopts `outcome.innings` only when that settle drains the
queue. The device owns the arithmetic (D10), so the server's row is a
confirmation, never a correction; once nothing is pending it reflects every
delivery the device has and the two agree. It also stops matching provisional
deliveries on `seq` when replacing them — provisional seqs are local guesses and
collide with the real ones, which could discard a different pending ball.

**On the test.** The first regression test written for this would have passed on
the broken code. Three rapid taps all build their drafts before any reply lands,
so they advance correctly with or without the bug; the count has to be dragged
back *between* taps to reproduce it. The test now holds the first write open
with a completer, lets exactly one reply land mid-sequence, then taps again. It
was confirmed to fail on the unfixed controller with `[1, 2, 3, 2]` — the fourth
delivery re-issuing position 2 — before being confirmed to pass on the fixed one.

**Related, not fixed:** `ScoringState.legalBalls` (and `totalRuns`,
`totalWickets`) still reconcile server and local with `math.max`. That masked
this bug's effect on the score, and now that the device is authoritative and
parity watches for drift, the max() is working against both. Worth removing.

### A delivery could be recorded with an empty end — fixed 2026-08-22

Reported from a live session: four consecutive wickets, the non-striker's card
showing `—` with no player, and then a single recorded anyway.

**Nothing stopped it.** The engine clears whichever end the dismissed batter was
at, which is right, and the replacement is normally chosen inside the wicket
sheet. But if that step was skipped — the sheet dismissed, or its bench empty —
the slot stayed vacant and *nothing noticed*. There was a `bowlerSet` guard on
the run pad and on `_record`, and no equivalent for batters.

**Fixed in three places**, because one was not enough:

- `ScoringState.battersSet` / `needsBatter` — the state can now answer it.
- A `ScoringSurface.needsBatter` gate on the run pad, with a notice that
  distinguishes *"choose someone"* from *"there is no one left"* — a side that
  has run out of batters is not waiting on a tap.
- A guard in `ScoringController._record`, as the backstop for every other route
  into a write.

Ordered after `needsBowler` so the gate agrees with the post-delivery prompt,
which offers the bowler first. The batter picker is also reachable directly now;
previously it existed only inside the wicket sheet, so a dismissed sheet left no
way back.

**Separately visible in the same screenshot, NOT fixed:** the innings should
already have been over. The batting side had five players and five were out, but
`wicketsToAllOut` defaults to `playersPerTeam - 1` and the match format says 11,
so all-out never fired. Two readings — the format is wrong for the fixture, or
the engine should derive the threshold from the actual XI rather than the
nominal squad size. The second is more robust and would cover every short-handed
match, but it is a **rules change**, so per §8 it starts with a vector, not with
the engine. Not taken unilaterally.

### Undo was disabled exactly when it was needed — fixed 2026-08-22

Found immediately after the batter gate landed: with the pad correctly blocked,
there was no way out, because Undo was greyed out too.

**`canUndo` required `pendingCount == 0`.** The reasoning recorded on `isBusy`
was that a delivery which has not been written has nothing to undo. That was
never true — `MatchesRepositoryImpl.undoLastBall` has always handled an unsent
delivery by discarding the queued write — and the gate meant nothing could ever
reach that path. Worse, `pendingCount` only returns to zero when writes land, so
the moment writes stopped landing (out of coverage, or a backend not yet
deployed) undo was disabled **permanently**, at precisely the moment a scorer
most needs to take a mis-tap back. §12 promised this case worked; the UI forbade
it.

**Undo's two paths are now distinct**, which they had to become before the gate
could be opened safely:

| Outcome | What happens |
|---|---|
| `discardedPending` | The delivery never left the device. The queued write is thrown away and **the server is not contacted** — asking it to delete *its* last delivery would remove a different ball entirely. |
| `removedStored` | The stored delivery is deleted server-side and the screen re-syncs. |

The controller used to re-read the ball list from the server after **any** undo.
For a queued delivery that erased every *other* unsent ball from the screen,
because the server has seen none of them. It now rolls the local projection back
instead — restoring the trio from the delivery being removed (each ball records
who was on strike and bowling when it was bowled) and recounting the totals from
what remains, the same derive-don't-subtract shape the server uses.

Three tests cover it: the gate holds while a write is queued, a queued undo never
touches the server, and the stored path still delegates.

### Undo targeted the wrong delivery — fixed 2026-08-22

Reported after the migrations landed: Undo was now enabled but did nothing.

**The repository chose between undo's two paths by looking at the write-ahead
log alone.** If any op was unsent it discarded the newest and reported a local
undo. That is right only while the log matches what is on screen — and it had
stopped matching. Every delivery recorded before the migrations was refused by
the server and left `pending` (`markOpFailed` does not clear an op, and
`pruneOps` only removes *synced* ones). So the log held a pile of ops that
corresponded to nothing visible, and Undo discarded one of those: the controller
then looked for a painted ball with that op id, found none, and changed nothing.
Silence, and the delivery the scorer wanted gone stayed put.

**The caller now says which delivery is unsent.** Only the presentation side
knows what is on screen: the last painted delivery is either provisional — its
op id embedded in the local ball id — or a row the server already holds.
`undoLastBall` takes `pendingOpId` and no longer guesses.

**Un-replayable ops are discarded rather than retried.** An op recorded before
the idempotency key became mandatory can never be accepted, and because a failed
send halts the drain, one of them blocked everything queued behind it forever.
`syncPendingOps` now drops them. The queue is also kicked once when the scoring
screen opens, so a device that scored through an outage heals without the scorer
having to background the app.

### Lineup is not the roster — 2026-08-22 (behaviour, not a bug)

Reported alongside: a player added to the team did not appear as an available
batter. `availableBatters` derives from `match_players`, which is materialised
from the roster **when the match is created**. Editing the team afterwards does
not reach an existing match, by design — a lineup has to be stable once play
starts or the scorecard means nothing.

There is no substitute flow. Adding someone mid-match currently needs a direct
insert into `match_players`. Worth building properly: injuries, late arrivals and
short-handed sides are normal at this level.

### Two plpgsql type errors reached production — 2026-08-22

Both surfaced only when the function was called, because **Postgres does not
typecheck a plpgsql body at CREATE time**. Both migrations applied cleanly and
reported success.

1. **`undo_last_ball`** used `coalesce(delivery_type, ball_type)`. `delivery_type`
   is the `delivery_kind` enum, `ball_type` is `text`; no common type exists, so
   every undo failed with *"COALESCE types delivery_kind and text cannot be
   matched"*. Reported from the device.
2. **`start_innings`** declared the batting side as `text`, assigned a `uuid`
   into it, then compared it back against a uuid column — *"operator does not
   exist: text = uuid"*. Found by re-reading after (1), not reported: it would
   have broken "Start the chase" at the innings break **and** every bowler change
   and incoming batter, since both route through that RPC.

Repaired forward in `20260822130000_repair_scoring_rpcs.sql`, and at source so a
fresh build is correct. Team ids and side labels are now separate variables of
the right types, and the undo aggregate reads the real columns — matching the one
`record-ball` uses, so the two agree about what an innings totals to.

**The process lesson.** Five migrations and a rewritten edge function were
authored without ever executing them, and that was stated each time — but the
risk was described as generic. It is not: the specific hazard is that
`CREATE FUNCTION` validates syntax and nothing else, so a plpgsql body can carry
a type error through a clean migration run and fail on first call. A deliberate
declare-vs-usage type sweep was run over every function written in this
workstream after (1) was reported; it found (2). That sweep should happen before
a push, not after a bug report.

### Still open

1. **Sign-out warning UI** — the count exists; the dialog does not.
2. **A visible "N unsent" indicator** on the scoring screen. `pendingCount` is on
   the state and unused by the UI.
3. **S4 client half** — the server-side `scoring_ops` idempotency table and edge
   function are written; the client does not yet send `p_op_id`. Until it does, a
   lost reply still risks a double-record on retry. **This is the most important
   remaining gap**, because the outbox now retries where it previously gave up.
4. **S3 soak** — still wants real matches, and still wants `record-ball` deployed.

### "Offline" and "refused" were the same code path — fixed 2026-08-30

`MatchesRemoteDataSource` translated every failure into `ServerException`. It
never threw `NetworkException`, so the repository had no way to ask the question
the write path turns on: **did the server never hear us, or did it hear us and
say no?**

Three consequences, in increasing order of severity:

1. `startInnings` caught `ServerException`, commented it "Offline / network
   failure", and returned `Right(unit)`. A rule violation — the one failure that
   is definitely *not* offline — was reported to the scorer as **success**.
2. Both write paths called `markOpFailed` on a refusal, leaving the op pending
   forever. `pendingOpsCount` never returned to zero, and §21's own note about a
   stuck count disabling undo describes exactly this.
3. The drain loop `break`ed on `ServerException`. One permanently refused
   delivery stalled **every op queued behind it** for the rest of the match.

**The fix.** A refusal is now a distinct terminal state, `scoring_ops.refused_at`
(schema v9):

| Outcome | WAL | Returned |
|---|---|---|
| Transport failure (`NetworkException`) | stays pending, `attempts++` | `Right` for `startInnings`, `NetworkFailure` for `recordBall` |
| Server refused (server/conflict/auth) | `markOpRefused` — leaves the queue, row kept | `Left(<Failure>)` |

The data source now throws `NetworkException` for `SocketException` /
`http.ClientException` / `TimeoutException`, mirroring the precedent already set
in `messages_remote_datasource.dart`.

Two properties are deliberate:

- **Refused rows are kept, never deleted** (§19.3). `pruneOps` skips them and
  `refusedOps(match, innings)` reads them back, so "what could not be applied"
  stays answerable. The previous code *discarded* on auth failure and conflict,
  which §19.3 forbids — a scorer who lost their lease silently lost their
  deliveries.
- **The drain `continue`s past a refusal** instead of breaking. It still breaks
  on a transport failure, because the ops behind must not overtake the one that
  did not land.

Covered by `test/features/matches/data/repositories/scoring_write_failure_taxonomy_test.dart`
(real SQLite — a durability claim asserted against a mock is not asserted) and
three cases in `matches_local_datasource_test.dart`.

**Still open, unchanged by this:** the refused list has no UI. `refusedOps` is
readable but nothing reads it, so §19.3's "visible, readable and exportable"
is still only half-satisfied — it is now durable, not yet visible. That joins
items 1 and 2 in *Still open* above; all three are the same missing surface.
