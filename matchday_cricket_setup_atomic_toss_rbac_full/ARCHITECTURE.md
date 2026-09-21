# Architecture Contract — Cricket Match Setup After the Multi-Sport Split

## 1. Ownership rule

The live schema establishes:

```text
matches
  sport-neutral match shell

match_teams
  sport-neutral side/team identity

match_players
  sport-neutral participant identity

cricket_matches
  Cricket-specific rules + workflow state
```

The initial Match Start controller therefore belongs to the Cricket extension:

```text
cricket_matches.setup_side
```

It does **not** belong in `matches`.

## 2. Meaning of `setup_side`

`setup_side` is:

```text
team_a | team_b | NULL
```

It means:

> The side responsible for administering the initial peer-to-peer Cricket Match Start workflow.

It does not mean home side, venue owner, permanent match authority, winner, batting side, or bowling side.

After the toss, authority can move to the derived batting side. Neutral tournament Cricket fixtures may have `setup_side = NULL`.

## 3. Structural integrity

```text
cricket_matches(match_id, setup_side)
               |
               v
match_teams(match_id, team_side)
```

A non-null setup side must therefore be a side of the same match.

## 4. Audit, domain state, and authorization are distinct

```text
matches.created_by
    = user who materialized the match row
    = audit/history

cricket_matches.setup_side
    = side responsible for initial Cricket setup
    = Cricket domain state

cricket.match.setup
    = users allowed to perform Cricket setup
    = RBAC
```

## 5. Atomic physical toss

```text
physical coin toss
    ↓
one side wins
    ↓
setup representative / official asks:
"Bat or bowl?"
    ↓
winner answers verbally
    ↓
Matchday records both facts together
```

State transition:

```text
scheduled + cricket phase=toss
        |
        | record_toss(winner, decision)
        v
scheduled + cricket phase=lineup
```

Stored atomically:

```text
toss_won_by
toss_decision
toss_recorded_by
toss_recorded_at
```

## 6. Stage authority

### Toss

```text
match-scoped cricket.match.setup
    OR
setup_side -> match_teams.team_id
           -> team-scoped cricket.match.setup
```

### Lineup / ready

```text
match-scoped cricket.match.setup
    OR
derive first batting side from toss
    -> match_teams.team_id
    -> team-scoped cricket.match.setup
```

### Live scoring

```text
match.score
```

remains separate.

## 7. RBAC generalization

The engine stays generic:

```text
permissions
permission_scopes
role_permissions
grants
can(...)
team_can(...)
```

The capability itself is sport-specific:

```text
cricket.match.setup
```

That is cleaner than `match.lineup.set`, whose semantics explicitly referenced XI/toss/start.

## 8. Assigned tournament scorer

A neutral tournament Cricket fixture uses:

```text
cricket_matches.setup_side = NULL
```

For a Cricket scorer, the official grant mirror supplies:

```text
match.score
cricket.match.setup
```

For a future non-Cricket scorer it does not automatically grant a Cricket capability.

## 9. Match creation

### Direct challenge

```text
from team -> team_a
receiver  -> team_b
cricket setup_side -> team_a
```

### Open pool

```text
posting team -> team_a
accepted team -> team_b
cricket setup_side -> team_a
```

### Tournament

```text
generic matches + match_teams
if sport == cricket:
    create cricket_matches with setup_side=NULL
```

## 10. Flutter boundary

The Cricket aggregate view exposes:

```text
setup_side
setup_team_id
```

`setup_team_id` is derived from `cricket_matches.setup_side + match_teams`.

Flutter uses it only as the Cricket UI/API projection. No generic host property is added to `matches`.

## 11. Concurrency

Multiple authorized members may see the toss form. That is intended.

`record_toss` locks:

```text
matches
match_teams(team_a)
match_teams(team_b)
cricket_matches
```

and requires the match to still be scheduled, Cricket phase to still be toss, and the toss to remain unrecorded. A stale concurrent submit is rejected after the first commit.

## 12. Correction policy

`record_toss` is initial-entry only.

If correction is required later, implement a dedicated correction command with explicit rollback rules because changing the toss can invalidate batting-side lineup/innings state.

## 13. Generic shell remains clean

The shared `matches` table continues to own only sport-neutral event identity, tournament/bracket metadata, venue, schedule, generic lifecycle, generic winning side, creator audit, and timestamps.

Cricket setup/toss/openers/innings remain outside it.
