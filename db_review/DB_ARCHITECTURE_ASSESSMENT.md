# Database Architecture Assessment: Scalability & Flexibility

> Produced by a 14-agent specialist review (Supabase/Postgres + architecture):
> 1 schema map → 6 dimension assessments (data-modeling, write-scale, read-scale,
> flexibility, security-rls, realtime) → 6 adversarial critiques → 1 synthesis.
> Only recommendations that survived critique are included. Read-only assessment;
> nothing here has been applied. Companion to `db_review/SCHEMA_AUDIT.md`.

## 1. Executive Summary

**The current Supabase/Postgres foundation is the right choice and is well-built.** The schema makes several genuinely correct architectural decisions that most teams get wrong:

- **`match_innings_state` split from `matches`** isolates the hot live-scoring row from the spectator-readable metadata row — the right hot-row decision.
- **Broadcast channels over `postgres_changes`** eliminates per-subscriber RLS fan-out on the highest-frequency event stream (ball-by-ball).
- **The two-table polymorphic XOR pattern** (real FKs + CHECK + split partial indexes), resolved once at `match_players` and then carried as clean UUIDs into `balls`/`match_innings_state`, is a model-extensibility win.
- **Format-as-snapshot** (`matches.format` jsonb frozen at creation, consumed by a pure scoring engine) correctly decouples rule evolution from stored data: old matches replay against their frozen rules; new format knobs are purely additive.
- **`(select auth.uid())` everywhere** prevents per-row re-evaluation in RLS.

None of the issues below are foundational. Every fix is a within-Postgres/Supabase change (indexing, rollup tables, trigger/RPC edits, RLS refactors). **No constraint genuinely blocks scale.** Online-only is fine; Supabase is fine; the repo-calls-Supabase-directly pattern is fine.

**The 5 highest-leverage changes** (all survived critique):

1. **Close the direct-write scoring bypass.** The three direct-write RLS policies on `balls` (`insert`/`delete`) still call `_can_score_match`, while the `record_ball` RPC correctly uses `_can_score_innings`. A bowling-side manager can POST directly to `/balls` and bypass the batting-side rule. One-migration fix: switch those policies to `_can_score_innings(match_id, innings_number)`. **(S effort, high impact, correctness.)**

2. **Decouple standings recompute from the match-completing transaction.** `recalculate_standings()` runs a synchronous `O(teams × matches)` jsonb-parsing loop inside the transaction that completes a match, holding the `matches` row lock and blocking the scorer's HTTP response. Replace with an **incremental delta UPDATE** to the two affected teams' rows. **(M effort, high impact, write-scale.)**

3. **Build a `player_career_stats` rollup + the supporting `match_innings_scorecard` projection.** Today there is *no* aggregation layer between the `balls` ledger and any stats read — every profile/leaderboard read would full-scan `balls`. `migrate_player_stats()` is a no-op stub, so claiming an unclaimed player silently loses attribution. This single investment unblocks player profiles, leaderboards, the `stat_milestone` notification, and the claim-cascade merge. **(L effort, high impact, read-scale + flexibility.)**

4. **Restrict PII on `unclaimed_players`.** `phone_number`/`email` are plaintext in a world-readable table (`USING (true)`) — any authenticated user can harvest contact details platform-wide. Narrow the SELECT policy to relationship-based access and move contact fields behind a SECURITY DEFINER RPC. **(M effort, high impact, security.)**

5. **Fix the team-manager privilege escalation.** The `teams_update_managers` policy's `WITH CHECK` lets a co-manager append arbitrary UUIDs to `managers` or claim a null `owner_id`. Add a BEFORE UPDATE trigger restricting `managers`/`owner_id` changes to the owner, with an explicit (non-dead-ending) succession path for ownerless teams. **(S effort, high impact, correctness/security.)**

---

## 2. Target Architecture

The shape below keeps the existing strong skeleton and adds the missing aggregation/projection layer, hardens the write path, and prepares the realtime/RLS boundary for private content — all additively.

### 2.1 New aggregation & projection layer (the central gap)

The `balls` ledger stays immutable and the source of truth. Insert a read-optimized projection layer between it and every aggregate read. **Sequence matters: build the projection first; it feeds both standings and career stats.**

**`match_innings_scorecard`** — typed per-innings totals, written inside the match-completion transaction from the `result` payload the orchestrator already holds:

```
match_innings_scorecard (
  match_id        uuid    references matches on delete cascade,
  innings_number  smallint,
  batting_team_id uuid,
  bowling_team_id uuid,
  runs            int,
  wickets         smallint,
  overs           numeric,
  extras          int,
  legal_balls     int,
  all_out         boolean,
  declared        boolean,
  primary key (match_id, innings_number)
)
```

- Populated by **both** result-writers — the `record-ball` edge orchestrator **and** the `submit_match_result` RPC (the audited dual path). If only one writes it, RPC-finalised matches have null rows.
- `recalculate_standings` then JOINs typed integer columns instead of calling `jsonb_array_elements` per match per team. Keep `matches.result` jsonb as the human-readable display blob (no breaking change).
- **Documented dependency:** the projection inherits any client-side computation error in the `result` payload (current design intent: totals are sourced from the payload, not recomputed). A future hardening step recomputes from `balls`.

**`player_match_stats`** — per-match, per-player line, populated **once at match completion** (not from a per-ball trigger, which would fire ~240×/match):

```
player_match_stats (
  match_player_id uuid primary key references match_players on delete cascade,
  match_id        uuid,
  innings_number  smallint,
  runs_scored int, balls_faced int, fours int, sixes int, is_out boolean,
  wickets_taken int, overs_bowled numeric, runs_conceded int, maidens int,
  catches int, stumpings int, run_outs int
)
```

**`player_career_stats`** — the rollup that makes profiles/leaderboards O(1). Key it to mirror `match_players` polymorphism so the claim-merge is a clean additive upsert:

```
player_career_stats (
  subject_kind text check (subject_kind in ('profile','unclaimed')),
  subject_id   uuid,
  matches int, innings_batted int, runs int, balls_faced int,
  innings_bowled int, balls_bowled int, runs_conceded int, wickets int,
  catches int, ...,
  updated_at timestamptz,
  primary key (subject_kind, subject_id)
)
```

- Written **only** by a SECURITY DEFINER finalizer; RLS denies direct writes (mirror `tournament_standings`).
- **The finalizer MUST be idempotent.** `matches.result` is rewritable post-completion (`match_result_history` proves corrections happen). A blind increment double-counts on every correction. Make it recompute-from-projection keyed by `match_id` (delta = new contribution minus previously-attributed for that match).
- **Derived stats (average, strike rate, economy) are computed at read time** from stored integers — never stored, to avoid float drift.
- `migrate_player_stats()` becomes real: on claim, sum the unclaimed `subject_id` row into the profile row and retire the placeholder.

### 2.2 Hot write path (live scoring)

**Single entry point.** Force all live scoring through the edge function's engine. The audited dual-path is the issue; the fix is the three `balls` direct-write policies (§3 Now). On `undo_last_ball`, add `p_expected_version bigint default null` (matching `record_ball`'s optimistic-concurrency signature) in **both** the 0410 original and the 0603 re-creation; raise `40001` on mismatch so the client's existing conflict-retry handler covers undo too.

**Eliminate the in-lock COUNT.** The edge function's per-bowler legal-ball `COUNT(*)` runs as a second round-trip while holding the `FOR UPDATE` lock. Materialize `bowler_legal_balls integer not null default 0` on `match_innings_state`: increment in the same UPDATE as `legal_ball_count` when legal; reset to 0 in the same CASE that nulls `bowler_id` on over-end; decrement in `undo_last_ball`. Both scoring paths must apply this atomically or the counter drifts; backfill in-progress matches at migration time.

**Connection pooling.** Set `max:1` and `idle_timeout:5` in the postgres.js pool in both `_shared/db.ts` and `list-my-matches`. Each invocation runs one short transaction; holding 3 connections per warm instance wastes pooler budget with no throughput benefit. Set `MATCH_DB_URL` explicitly to the transaction-pooler URI (port 6543) to remove env ambiguity across dev/CI/prod, and add a startup host:port warning in `db.ts`.

> **Note on `_balls_assign_seq` and `balls` autovacuum/fillfactor:** *not* on the target list. `SELECT max(seq)` over the composite index is a single B-tree right-edge probe (sub-ms), and `fillfactor=100` is correct for an append-only table. Undo is an infrequent corrective action. Revisit autovacuum tuning only if undo rates measurably bloat pages.

### 2.3 Match-list & feed reads

**`list-my-matches`:** add `before_created_at timestamptz` cursor + `LIMIT` (default 20–50) **immediately** (function redeploy, no migration). Add partial composite indexes that serve team-scoped ordered lookups and also help the cron and any future team-match-history screen:

```
matches_team_a_status on matches (team_a_id, status, created_at desc) where team_a_id is not null
matches_team_b_status on matches (team_b_id, status, created_at desc) where team_b_id is not null
```

Promote to a SECURITY DEFINER SQL function (UNION of two single-column index scans, avoiding the bitmap-OR on `IN (team_a_id, team_b_id)`) **once the schema stabilizes** — the function's own comment defers this, and `matches.sql` is still actively changing.

**Feed:** the keyset path (`posts_status_created` partial index + `FeedController` cursor) is already in good shape. The PostgREST author-profile embed is **not** an N+1 — PostgREST issues a single `WHERE user_id IN (...)` batch. No action; do **not** denormalize author fields into posts. If profiling ever shows the join is hot, add a covering index `profiles (user_id) INCLUDE (display_name, username, profile_photo_url)`.

**Completed-match scorecards:** read per-innings totals from `matches.result` (already structured), not from the live `match_innings_summary` view (a full GROUP BY over `balls`). The view stays useful only while `result IS NULL` (live). Query-routing change in the Dart data source; no schema change.

### 2.4 Flexibility headroom

**Stamp `rules_version smallint not null default 1` on `matches`**, written from a single `ENGINE_VERSION` const by **both** result-writers. The format knobs are snapshotted but the *engine semantics* (strike rotation, free-hit dismissal precedence, target-vs-all-out) are not — without this, a future scoring-rule fix cannot be reasoned about or backfilled per-row. Gate behavior changes behind `if (rulesVersion >= N)`. **(S effort, highest flexibility leverage.)**

**Match lifecycle completion.** The orchestrator dead-ends a tie at `status='completed'` and has no super-over/Test-declaration path, even though the `super_over` enum value, innings slots (1..4), and `super_over_wickets` format knob all exist. Extend the final-innings transition: on tie + `format.tieBreaker='super_over'`, set `status='super_over'` and open innings 3. Add a `tieBreaker` field to `MatchFormat`/`types.ts` (the engine currently can't read the knob). **Critically, aggregate the super-over separately** — `computeResult` sums all innings per team, so a naive add folds super-over runs into the main result. Add a captain-only `declare_innings(match_id, innings_number)` SECURITY DEFINER RPC for Test.

**Bracket advancement.** Generalize the hard-coded single-elimination `prev_match_a/b` winner-flow into a data-driven edge model (`winner|loser` edges) so richer brackets become additive. **Scope honestly:** the advance-path refactor is M; a correct `double_elimination`/`group_knockout` *generator* (loser-bracket seeding, byes, grand-final reset) is separate, larger work — not "just config."

**`managers`/`organizers` arrays:** leave as `uuid[]` for now (premature normalization adds joins to a hot RLS predicate). Add the zero-risk `CHECK (cardinality(managers) <= 20)`. When the first role-metadata requirement lands, migrate to `team_managers`/`tournament_organizers(…, role, added_by, added_at)`. **Correction to the original plan:** the migration is *not* "only function bodies" — `teams_update_managers` inlines `= any(managers)` and would also need rewriting. Grep for inlined array checks first. (Do **not** add a GIN index on `tournaments.organizers` — `tournaments_organizers_gin` already exists.)

**`posts` reactions / `notification_type` enum:** no action. Single `likes_count` + `post_likes` is correctly minimal (YAGNI); widen additively if typed reactions ever ship. Keep `notification_type` as an enum — `ALTER TYPE ... ADD VALUE` is millisecond-duration in Postgres 12+ with no table rewrite. The valuable adjacent work is a `validate_notification_payload(type, payload)` check called by the existing SECURITY DEFINER writers.

### 2.5 Realtime & RLS boundary

**Future-proof channel authorization now.** The realtime join policy is an unconditional prefix match — any authenticated user can join any `match:*` / `tournament:*` channel. Define `is_match_visible(uuid)` and `is_tournament_visible(uuid)` as `STABLE SECURITY DEFINER` functions returning `true` unconditionally today, and wire them into the policy. When private matches / pre-draw tournaments ship, it's a one-function-body change instead of an emergency policy migration. Add `is_post_visible()` (`status='active' OR author_id = auth.uid()`) on the post-comment branch to align REST and Realtime access.

**Curate broadcast payloads.** `broadcast_new_ball()` (and the comment-broadcast functions) emit `to_jsonb(new)` — full row, including `created_by` and any future column. Switch to an explicit `jsonb_build_object(...)` omitting `created_by`/`created_at`. Established pattern already exists (`broadcast_comment_deleted` emits three fields).

**Chat fan-out.** Replace the PL/pgSQL `FOR` loop in `broadcast_new_message()` with a single batch `INSERT INTO realtime.messages SELECT ... FROM chat_members WHERE chat_id = new.chat_id AND user_id IS DISTINCT FROM new.sender_id AND left_at IS NULL`. Same fan-out, one write instead of N inside the transaction. **Do not drop the loop** — FCM only covers backgrounded users; this ping is the only signal for users foregrounded on another screen.

**Internal predicate exposure.** Revoke direct `authenticated` execute on `_team_current_captain` (it returns another user's user_id — a leadership-role PII disclosure with no visibility gate); call it only from other SECURITY DEFINER functions. The other boolean/uuid predicates (`_can_score_innings`, `_is_match_captain`, `_batting_first_team`) carry intentional grants flowing from the project-wide `ALTER DEFAULT PRIVILEGES … GRANT EXECUTE … TO authenticated` default — lower actual risk (they return the caller's own authorization). Restrict `recalculate_standings` and the full `record_ball` to `service_role` per §3.

**Account suspension.** Handle content visibility in the suspension *workflow*, not in RLS. A `suspend_user(p_user_id)` SECURITY DEFINER RPC that atomically flips `posts.status→'hidden'` and active `comments.status→'deleted'` leverages existing status-based policies at zero query cost. Do **not** add `profiles.account_status` joins to every comment/post SELECT. Keep `balls` history visible (historical-record exception).

---

## 3. Prioritized Roadmap

### NOW (correctness/security holes; mostly one-migration, S effort)

| Item | Effort | Impact |
|---|---|---|
| Switch the three `balls` direct-write RLS policies (`insert`/`delete`) to `_can_score_innings(match_id, innings_number)`. Leave `update` on `_can_score_match` (commentary is match-scoped) with a documenting comment. | S | **High** — closes bowling-side bypass |
| `REVOKE EXECUTE ON record_ball / recalculate_standings FROM authenticated; GRANT … TO service_role` — **only after confirming no Flutter client calls these RPCs directly.** If a client still calls `record_ball`, instead add an innings-completion guard inside the SQL function (`RAISE` if all-out or target reached) and label it the degraded path. | S | **High** — eliminates engine bypass / standings DoS |
| Narrow `unclaimed_players` SELECT to `added_by / claimed_by_user_id / team-manager`; expose `phone_number`/`email` via `get_unclaimed_contact()` RPC. Verify the `team_members ↔ unclaimed_players` join column against migration 0210. **Do not** use Postgres column-level `REVOKE SELECT (col)` — it composes badly with RLS. | M | **High** — PII/GDPR |
| Team-manager escalation: BEFORE UPDATE trigger restricting `managers`/`owner_id` to the owner. **Explicitly handle null `owner_id`** (ownerless-team succession via a dedicated RPC) — do not create permanently unmanageable teams. | S | **High** — privilege escalation |
| `list-my-matches`: add `before_created_at` cursor + `LIMIT`. Add `matches_team_a_status` / `matches_team_b_status` partial composite indexes. | S→M | High — unbounded query today |
| `CHECK (cardinality(managers) <= 20)` on `teams.managers`. | S | Low-risk guard |
| `is_match_visible()` / `is_tournament_visible()` / `is_post_visible()` stubs wired into realtime policy. | S | Medium — avoids future emergency migration |
| Pool config: `max:1`, `idle_timeout:5` in both edge functions; set `MATCH_DB_URL` to pooler URI + startup warning. | S | Medium — pooler exhaustion |
| Curate `broadcast_new_ball()` payload (drop `created_by`/`created_at`); revoke `_team_current_captain` from `authenticated`. | S | Low/Medium |

### NEXT (the aggregation layer; M–L effort, unblocks features + scale)

| Item | Effort | Impact |
|---|---|---|
| **`match_innings_scorecard`** projection, written by both result-writers. | M | **High** — prerequisite for everything below |
| Replace synchronous `recalculate_standings` loop with **incremental delta UPDATE** to the two affected teams' rows (reads the new typed scorecard rows). Keep full recompute as a `service_role`-only admin RPC. *(This also collapses the N-broadcasts-per-completion issue to 2.)* | M | **High** — unblocks scorer write latency |
| **`player_match_stats` + `player_career_stats`** rollup; make the finalizer **idempotent** (recompute-keyed-by-`match_id`); implement real `migrate_player_stats` on claim. | L | **High** — unblocks profiles/leaderboards/claim continuity |
| `bowler_legal_balls` on `match_innings_state` — remove the in-lock `COUNT(*)`. | M | Medium — shortens lock hold |
| `rules_version` on `matches`, written by both result-writers. | S | Medium — future scoring-fix replayability |
| `p_expected_version` on `undo_last_ball` (both definitions). | S | Medium — closes last unguarded concurrent path |
| Route completed-match scorecard reads to `matches.result` (Dart data-source change). | S | Medium — avoids `balls` GROUP BY |
| Batch `broadcast_new_message()` into a single `INSERT … SELECT`. | S | Medium — large-chat write latency |
| `suspend_user()` RPC (atomic status flips). | M | Medium — moderation correctness |

### LATER (genuine product-driven extensions; do only when the requirement lands)

| Item | Effort | Impact |
|---|---|---|
| Super-over + Test-declaration lifecycle in the orchestrator (separate super-over aggregation; `declare_innings` RPC; `tieBreaker` on `MatchFormat`). | M+ | High *when these formats ship* |
| Data-driven bracket-edge model for advancement; per-type generators for `double_elimination`/`group_knockout`. | M (advance) + L (generators) | Flexibility *when richer brackets ship* |
| `team_managers`/`tournament_organizers` join tables (only when role metadata is needed); rewrite predicates **and** inlined `= any(...)` policies. | M | Flexibility |
| Followed-user feed: add `follows (follower_id, target_id) where target_type='user' and status='active'` before building it; fan-out-on-read CTE is sufficient for bounded follow counts. | S | Future feature |
| Partial composite index for the abandon-stale-matches cron and per-table autovacuum tuning on `balls` — **defer until `matches` > ~50k rows / undo rates warrant it.** | S | Low until scale |

---

## 4. Trade-offs & Anti-Recommendations

**Do NOT:**

- **Do not claim `record_ball` "still runs the 0410 body."** `CREATE OR REPLACE FUNCTION` is destructive — migration `20260603130000` is the effective definition and correctly uses `_can_score_innings`. The real gap is solely the three `balls` direct-write *policies*. Verify with `\df+ public.record_ball` before acting on any "stale RPC" narrative.
- **Do not blindly `REVOKE record_ball FROM authenticated`** without first confirming zero Flutter clients call it directly. If a client still uses the SQL path, you'll break scoring and force an app update. Add SQL-level guards (innings-completion) as the interim safety net.
- **Do not denormalize author fields into `posts`** to "fix" a profile-join N+1 that doesn't exist — PostgREST batches the embed. Denormalization just buys you staleness.
- **Do not add `profiles.account_status` joins to comment/post SELECT policies** for moderation — that's a per-read cost on the hot feed path for what is a workflow concern. Flip `status` in `suspend_user()` instead.
- **Do not use Postgres column-level `REVOKE SELECT (phone_number, email)`** on `authenticated` — it composes badly with RLS (policy evaluation referencing the column can error). Use the relationship-scoped policy + SECURITY DEFINER RPC.
- **Do not tune `balls` autovacuum/fillfactor now.** `fillfactor=100` is correct for append-only; undo is rare. This is premature at current scale.
- **Do not "parameterize" the `follows` cleanup trigger's `tg_table_name` dispatch** — that's not a real Postgres mechanism. If hardening is wanted, split into three per-table trigger functions plus a monthly `pg_cron` orphan sweep.
- **Do not convert `notification_type` to a FK-lookup table** or treat enum extension as a scale risk — `ADD VALUE` is millisecond-cheap in PG12+.
- **Do not promote `list-my-matches` to a SQL RPC yet** — `matches.sql` is still changing; the function's own comment defers it. Pagination + indexes first (no migration churn).
- **Do not present super-over or double-elimination as "free / config-only."** Super-over needs separate result aggregation and a new `MatchFormat` field; double-elimination needs real loser-bracket seeding logic on top of the edge-model refactor.

**Accepted limitations (explicitly fine for now):**

- **TOCTOU window** between the edge function's `_can_score_innings` preflight and the `FOR UPDATE` lock is theoretical for a cricket app (requires a millisecond-scale timing attack on a low-value target). Document it. Only refactor the predicate to take an explicit `p_actor_uid` (so it can run inside the service-role transaction) if multi-scorer matches become a production feature.
- **World-readable `matches` (`USING true`)** is the correct, intentional spectator posture — not a scalability risk (broadcast channels, not `postgres_changes`, carry the load). The visibility *stub* is the only forward-prep needed.
- **`match_innings_scorecard` duplicates data from `balls`/`result`** — that duplication is the correct read-performance trade, exactly as `match_innings_state` already duplicates derived state from `balls`. Mitigate drift by writing it in the same transaction from the same computed lines, from both result-writers.

**Cross-cutting implementation note (recurs in 3 dimensions):** `matches.result` is written by **two** paths — the `record-ball` edge orchestrator *and* the `submit_match_result` RPC. Every new column/projection (`rules_version`, `match_innings_scorecard`, `player_*_stats`) must be written by **both**, or it will be null/stale on RPC-finalised matches. And because `result` is rewritable post-completion, every rollup finalizer must be idempotent (recompute-keyed-by-`match_id`, never blind-increment).
