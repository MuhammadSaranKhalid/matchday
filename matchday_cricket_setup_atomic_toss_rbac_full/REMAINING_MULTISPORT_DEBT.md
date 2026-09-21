# Remaining Multi-Sport Generalization Debt

This package fixes the Match Start/toss boundary. It does **not** claim the whole existing database is already perfectly generalized.

The live audit found additional Cricket-specific concepts inside generic-looking subsystems. Handle these in a separate architecture phase.

## `match_challenges`

Current Cricket-specific concepts include:

```text
from_team_xi
from_team_keeper_id
players_per_side
countered_players_per_side
```

and Cricket-like player-count constraints.

A future direction may be a generic challenge shell plus a Cricket challenge extension after a dedicated flow audit.

## `match_pool_applications`

Current sport-specific concepts include:

```text
applicant_xi
applicant_keeper_id
```

These should be reconsidered when that subsystem is generalized.

## `match_format_presets`

The live table still carries a top-level scoring-mode concept that should be re-audited against the sport-specific preset architecture.

## `match_officials.role`

The global role check mixes scorer/umpire/referee vocabulary. Official roles differ by sport and may eventually need a sport-aware official-role catalog.

## Generalization rule

Promote something into the shared layer only when:

1. its meaning is truly sport-neutral; and
2. a real second-sport requirement demonstrates the commonality.
