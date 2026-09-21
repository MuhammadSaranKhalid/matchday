# Matchday — Cricket Setup-Side + Atomic Toss + Generic RBAC

> **Status:** Superseding implementation package  
> **Supersedes:** the earlier `matches.host_side` package. Do **not** apply that package.

This package implements the corrected multi-sport architecture after re-auditing the live database and current `main` branch.

## Final boundary

```text
matches
    = sport-neutral event shell

match_teams
    = sport-neutral team_a/team_b competitor slots

match_players
    = sport-neutral participant identity

cricket_matches
    = Cricket-only rules and workflow state
```

Therefore Match Start ownership belongs here:

```text
cricket_matches.setup_side
```

and **not** here:

```text
matches.host_side      ❌
matches.setup_side     ❌
```

`setup_side` answers one Cricket-domain question:

> Which match side administers the peer-to-peer Cricket setup before the toss has been recorded?

It is `team_a | team_b | NULL` and is structurally tied to `match_teams(match_id, team_side)`.

## Final Match Start flow

```text
SCHEDULED CRICKET MATCH
        |
        v
cricket_matches.phase = toss
        |
        v
cricket_matches.setup_side
        |
        | resolve through match_teams
        v
setup team
        |
        | cricket.match.setup
        v
record complete physical toss
(winner + bat/bowl in one command)
        |
        v
phase = lineup
        |
        v
derive batting side
        |
        | cricket.match.setup
        v
select opening batters
        |
        v
phase = ready
        |
        | cricket.match.setup
        v
start match
        |
        v
matches.status = live
cricket_matches.phase = live
```

A neutral tournament Cricket fixture may use:

```text
cricket_matches.setup_side = NULL
```

and an assigned scorer receives a match-scoped:

```text
cricket.match.setup
match.score
```

grant.

## One atomic toss command

Removed:

```text
record_toss_winner
record_toss_decision
```

Added:

```text
record_toss
```

Payload:

```json
{
  "action": "record_toss",
  "p_match_id": "<match uuid>",
  "p_won_by": "<team uuid>",
  "p_decision": "bat"
}
```

The Edge Function locks the shared shell, both side slots, and the Cricket child; authorizes with `cricket.match.setup`; verifies the selected team belongs to the match; converts the team UUID into a stable side; writes winner + decision + actor + timestamp atomically; advances Cricket to `lineup`; commits; then publishes the committed snapshot through Ably.

There is no digital “waiting for the toss winner to choose bat/bowl” state because that conversation happens physically at the ground.

## Authorization

The generic RBAC engine remains the authorization infrastructure:

```text
public.can(scope, entity_id, permission)
```

The Cricket setup capability is explicitly sport-specific:

```text
cricket.match.setup
```

Default team grants are migrated from the existing Match Start policy:

```text
owner   → allowed
manager → allowed
captain → allowed
player  → not granted
```

Per-team overrides are migrated too.

The previous generic-looking key:

```text
match.lineup.set
```

is removed after migration. No compatibility alias is retained.

`matches.created_by` remains audit/history only. Role names remain identity/display; permissions authorize.

## Peer-to-peer creation

For accepted direct/open challenges:

```text
from_team     → match_teams.team_a
other team    → match_teams.team_b

cricket_matches.setup_side = team_a
```

The user who executes acceptance remains `matches.created_by` for audit only.

## Tournament creation

`matches` and `match_teams` remain generic.

Only for Cricket is the sport extension created:

```text
cricket_matches(
  match_id,
  setup_side = NULL,
  ...
)
```

The assigned scorer may receive match-scoped Cricket setup authority.

## Package contents

```text
README.md
ARCHITECTURE.md
DEPLOYMENT.md
PATCH_MAP.md
TEST_MATRIX.md
REMAINING_MULTISPORT_DEBT.md
DELETE_MANIFEST.txt

migration/
  cricket_setup_atomic_toss_rbac.sql
  verify_cricket_setup_atomic_toss_rbac.sql

supabase/functions/cricket-match-action/
  complete Edge Function replacement

flutter_replacements/
  match_start_state.dart
  match_start_controller.dart
  stage_toss.dart
  stage_lineup.dart

repo_tools/
  apply_flutter_and_repository_changes.py
```

## Verification status

Fresh checks performed while producing this package:

- internal TypeScript command/domain/repository modules pass `tsc --noEmit`;
- static architecture scans confirm the replacement runtime reads `cm.setup_side`, not a generic `matches.host_side`;
- the two split toss actions are absent from the replacement Edge Function;
- creator/captain Match Start authorization shortcuts are absent from the replacement setup flow;
- the Flutter patcher passes Python syntax compilation;
- the patcher target patterns were checked against current GitHub `main`.

Not performed here:

- the SQL migration has **not** been executed against your connected Supabase project;
- Flutter code has **not** been compiled because Dart/Flutter is not installed in this environment;
- the full Deno Edge Function has not been compiled with Deno because Deno is not installed.

Run the supplied verification SQL plus `flutter analyze`, `flutter test`, and your normal local/reset migration test before deployment.
