# Test Matrix — Cricket Setup / Atomic Toss / RBAC

## Schema ownership

| Test | Expected |
|---|---|
| `matches.host_side` | Absent |
| `matches.setup_side` | Absent |
| `cricket_matches.setup_side` | Present |
| Non-null Cricket setup side | FK resolves to same match's `match_teams` |
| Neutral tournament Cricket | `setup_side=NULL` allowed |

## RBAC

| Scenario | Expected |
|---|---|
| Setup-team owner | Allowed by default |
| Setup-team manager | Allowed by default |
| Setup-team captain | Allowed by default |
| Setup-team player | Denied |
| Manager denied by team override | Denied |
| Opponent before toss | Denied unless match-scoped official |
| Assigned Cricket scorer | Allowed via match-scoped `cricket.match.setup` |
| Non-Cricket scorer | No Cricket setup grant |

## Atomic toss

| Scenario | Expected |
|---|---|
| Winner missing | Reject |
| Decision missing | Reject |
| Winner + bat | Commit once, phase → lineup |
| Winner + bowl | Commit once, phase → lineup |
| Team not in match | Reject |
| Toss already recorded | Reject |
| Parent not scheduled | Reject |
| Success | actor + timestamp stored |

## First batting side

| Toss | First batting side |
|---|---|
| A wins + bat | A |
| A wins + bowl | B |
| B wins + bat | B |
| B wins + bowl | A |

## Challenge creation

| Scenario | Expected |
|---|---|
| Direct challenge accepted | original from team=`team_a`, setup side=`team_a` |
| Counter accepted | original from team remains setup side |
| Open pool accepted | posting team=`team_a`, setup side=`team_a` |
| accepting user belongs to receiver | no effect on setup authority |

## Tournament

| Scenario | Expected |
|---|---|
| Cricket fixture | Cricket child with `setup_side=NULL` |
| Other sport fixture | no Cricket child |
| Assign Cricket scorer | `match.score` + `cricket.match.setup` |
| Replace scorer | old grants removed, new grants inserted |
| Remove scorer | both grants removed |
| Terminal match | assignment rejected |
| Auto-assign | uses actual `tournament_official_candidates` |

## Hard-cut regression scan

The replacement runtime must not retain:

```text
record_toss_winner
record_toss_decision
match.lineup.set
matches.host_side
creator-only toss authorization
captain-only lineup/start authorization
```
