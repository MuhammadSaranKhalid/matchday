# Matchday Multi-Sport Match Shell — Phase 1 Implementation

This bundle implements the first safe database step of the match refactor.

## Why Phase 1 is intentionally non-destructive

The current Matchday Cricket application and a number of deployed SQL RPCs still read/write Cricket-specific columns directly on:

- `matches`
- `match_players`
- `match_teams`

Deleting those columns in the same change that introduces the new architecture would require changing the match-start flow, challenge acceptance, tournament fixture generation, scoring RPCs, Realtime broadcasting, Flutter DTOs, and scoring data source at once.

That is a poor refactor boundary because a failed `db reset` would not tell us whether the problem is the new model or one of many migrated callers.

Phase 1 therefore establishes the new model **while preserving current behavior**.

## What this phase implements

```text
sports
  |
  v
matches                         shared identity/lifecycle
  |
  +---- cricket_matches         Cricket rules/state
  |
  +---- match_players           shared identity (legacy Cricket fields remain)
          |
          +---- cricket_match_players
  |
  +---- match_teams             shared side snapshot
          |
          +---- cricket_match_sides

cricket_matches
  |
  +---- match_innings           current name, now DB-enforced Cricket-only
          |
          +---- match_innings_state
          +---- match_deliveries
          +---- match_wickets
```

### Important final-state rule

`matches` may know **which sport** a match belongs to.

`matches` must not ultimately know **how Cricket works**.

Phase 1 creates that boundary and mirrors existing writes into it. Phase 2 changes readers/writers to the extension. Only then are the legacy Cricket columns removed.

## How to apply

Create the migration using your installed Supabase CLI rather than inventing a timestamp manually:

```bash
supabase migration new multisport_match_shell_phase1
```

Paste `multisport_match_shell_phase1.sql` into the generated migration file.

Then, because this project is currently resettable development:

```bash
supabase db reset
```

Run `verify_multisport_match_shell_phase1.sql` afterwards.

## What to test in the Flutter app

Do not add any multi-sport UI.

Use the existing Cricket UI and verify:

1. Create a Cricket team.
2. Send/accept a challenge.
3. Confirm the new `matches` row also gets a `cricket_matches` row.
4. Confirm materialised match players also appear in `cricket_match_players`.
5. Start the toss.
6. Record toss winner.
7. Record bat/bowl decision.
8. Lock openers.
9. Start the match.
10. Record deliveries.
11. Complete innings/match.
12. Compare legacy columns with the Cricket extension using the verification SQL.

All existing Cricket behavior should remain unchanged in Phase 1.

## Phase 2 boundary

After Phase 1 passes, the next change should:

- change Cricket RPCs to write `cricket_matches`;
- change Flutter Cricket reads to `cricket_match_details`;
- change lineup writes to `cricket_match_players`;
- move `team_a_captain` / `team_b_captain` to the Cricket extension or a generic match-authority model;
- change Realtime broadcasting so updates to `cricket_matches` publish the same match-state event;
- change tournament/leaderboard SQL to join Cricket state explicitly;
- stop writing legacy Cricket columns.

Then the mirror triggers can be removed.

## Phase 3 boundary

Only after no current caller uses the old shape:

- remove Cricket columns from `matches`;
- remove Cricket columns from `match_players`;
- remove Cricket columns from `match_teams`;
- make the shared `match_status` lifecycle-only;
- rename Cricket types:
  - `toss_decision` -> `cricket_toss_decision`
  - `match_start_phase` -> `cricket_match_phase`
  - `scoring_mode` -> `cricket_scoring_mode`
  - `delivery_kind` -> `cricket_delivery_kind`
  - `wicket_kind` -> `cricket_wicket_kind`
- rename Cricket engine tables:
  - `match_innings` -> `cricket_match_innings`
  - `match_innings_state` -> `cricket_match_innings_state`
  - `match_deliveries` -> `cricket_match_deliveries`
  - `match_wickets` -> `cricket_match_wickets`

That produces the final strict architecture without forcing every dependency to migrate blindly in one step.
