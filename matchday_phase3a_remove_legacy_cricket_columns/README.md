# Matchday Phase 3A — Physical Legacy Cricket Column Removal

This is the destructive cleanup after Phase 2A and Phase 2B.

## Scope

Phase 3A removes Cricket-specific storage from the shared shell. It does **not**
yet redesign global enums/statuses.

### Final `matches`

```text
matches
├── match_id
├── tournament_id
├── match_type
├── stage / round / bracket metadata
├── venue / ground_id
├── sport_id
├── scheduled_start_time
├── actual_start_time
├── completed_at
├── status
├── winner_id
├── team_a_id
├── team_b_id
├── created_by
├── created_at
└── updated_at
```

### Final Cricket extension

```text
cricket_matches
├── match_id
├── format_code
├── rules_snapshot
├── toss_won_by
├── toss_decision
├── toss_face
├── toss_recorded_at
├── phase
├── openers_submitted_by
├── openers_submitted_at
├── scoring_mode
├── revised_conditions
├── result
├── result_summary
└── player_of_the_match_id
```

### Final `match_players`

```text
match_players
├── match_player_id
├── match_id
├── team_side
├── user_id / unclaimed_id
├── display_name
├── jersey_number
└── created_at
```

### Cricket participant extension

```text
cricket_match_players
├── match_player_id
├── match_id
├── is_playing_xi
├── batting_order
├── is_captain
├── is_vice_captain
├── is_wicket_keeper
└── is_substitute
```

## Physically removed columns

From `matches`:

```text
match_format
format
toss_won_by
toss_decision
toss_face
toss_recorded_at
start_phase
openers_submitted_by
openers_submitted_at
scoring_mode
revised_conditions
result
result_summary
player_of_the_match_id
team_a_captain
team_b_captain
```

From `match_players`:

```text
role
is_in_playing_xi
batting_order
```

From `match_teams`:

```text
is_batting_first
captain_player_id
keeper_player_id
```

`match_teams` itself is retained as a generic per-match side/team-name snapshot.

## Critical safety choices

### Phase 2A + 2B are hard prerequisites

The migration checks for their canonical objects and refuses to run if they
are missing.

The connected production database currently does **not** yet contain those
Phase-2 markers, so Phase 3A must not be pushed there until 2A and 2B have
actually been applied and verified.

### No `CASCADE`

Column deletion uses no `CASCADE`.

If a hidden view/function has a real PostgreSQL dependency on one of these
columns, the migration fails rather than silently deleting the dependent
object.

### Canonical-child completeness

Before destruction, the migration verifies:

```text
every Cricket matches row
    -> cricket_matches exists

every Cricket match_players row
    -> cricket_match_players exists

cricket_matches.result winner
    -> matches.winner_id agrees
```

## Read compatibility without storage compatibility

Flutter does **not** need to lose its Cricket fields.

The database read path remains:

```text
matches
      \
       -> cricket_match_details -> MatchDto
      /
cricket_matches
      \
       -> captain derivation from cricket_match_players
```

So the API can still return:

```text
format
toss_won_by
toss_decision
start_phase
result
team_a_captain
team_b_captain
```

even though none of those Cricket facts are stored on `matches`.

That is a clean aggregate view, not a legacy mirror.

## Captain semantics

`team_a_captain` / `team_b_captain` in the Cricket read view are now derived
only from:

```text
match_players
    +
cricket_match_players.is_captain
```

There is no fallback to the team's current captain and no fallback to a legacy
`matches.team_*_captain` column.

That means a match captain is a match-lineup fact, which is the correct
historical model.

## Unclaimed-player merge

`finalize_unclaimed_claim()` is rebuilt because the transitional version still
touched fields being removed.

The Phase-3 version merges only canonical Cricket participant flags, repoints
all innings/delivery/wicket foreign keys, updates Cricket POTM, and preserves
the surviving shared participant row.

## Apply sequence

1. Deploy and verify Phase 2A.
2. Deploy and verify Phase 2B.
3. Back up / snapshot according to your normal production process.
4. Create the migration file with your installed Supabase CLI:

```bash
supabase migration new multisport_match_shell_phase3a_remove_legacy_cricket_columns
```

5. Paste `multisport_match_shell_phase3a_remove_legacy_cricket_columns.sql`.
6. Test on local/staging with a full Cricket flow.
7. Apply Phase 3A.
8. Replace `match_player_dto.dart` with the canonical DTO in this package and
   regenerate Freezed/JSON output.
9. Run `verify_phase3a.sql`.
10. Run Supabase security/performance advisors.

Supabase currently documents `security_invoker=true` as the safe way for
public views to respect underlying permissions/RLS, so
`cricket_match_details` is recreated as a security-invoker view.

## Required functional regression test

Test all of these after the physical drop:

```text
Direct challenge
Pool acceptance
Tournament draw
Knockout advancement
Toss winner
Toss decision
Openers
Start innings
Ball recording
Undo
Rain revision
Super over
Walkover
No result
Result override
Normal completion
My Matches
Tournament fixtures
Tournament live board
Unclaimed player claim
Account deletion with historical match participation
```

The important test is that **none** of those flows can depend on a column that
no longer exists.

## Next phase: 3B

Only after 3A is stable:

```text
Phase 3B
├── redesign match_status as true cross-sport lifecycle
├── rename match_start_phase -> cricket_match_phase
├── review/rename scoring_mode and toss enums
├── remove unused match_role enum
├── remove unused match_format enum
└── remove/rename remaining Cricket-specific globally named helpers
```

Keeping 3B separate makes failures attributable: Phase 3A is a storage-boundary
change; Phase 3B is a type/lifecycle semantics change.
