# Cricket Formats Architecture & Specification

This document defines the canonical specification for cricket match formats, presets, scoring rules, playing conditions, and challenge contracts in Match Day.

---

## 1. Conceptual Model: Format Identity vs Rules vs Playing Conditions

In Match Day, cricket match configurations are structured into three distinct orthogonal layers:

```
┌────────────────────────────────────────────────────────┐
│                   FORMAT IDENTITY                      │
│   t20 · t10 · quick_6 · quick_8 · over_30 · over_40    │
│   over_45 · over_50 · custom                           │
└──────────────────────────┬─────────────────────────────┘
                           │ defines default
                           ▼
┌────────────────────────────────────────────────────────┐
│                     SCORING RULES                      │
│   overs_per_innings · balls_per_over                   │
│   max_overs_per_bowler · innings_per_side              │
│   wickets_to_all_out                                   │
└──────────────────────────┬─────────────────────────────┘
                           │ played under
                           ▼
┌────────────────────────────────────────────────────────┐
│                   PLAYING CONDITIONS                   │
│   ball_type (tape | tennis | leather)                  │
│   players_per_team (5..15, default 8 or 11)           │
│   venue · scheduled_start_time                         │
└────────────────────────────────────────────────────────┘
```

- **Format Identity (`format_code`)**: Identifies the cricket format agreed upon (e.g. `t20`, `t10`, `over_50`, or `custom`).
- **Scoring Rules (`MatchFormat` / `rules_snapshot`)**: The mechanical constraints that govern the ball-by-ball scoring engine. For system presets, these are strictly defined and invariant.
- **Playing Conditions**: Contextual parameters that do not alter the format identity. For instance, playing a 20-over match with 8 players per side using a tape-ball remains **T20**; however, changing the innings length from 20 overs to 18 overs transforms it into **Custom**.

---

## 2. Active V1 System Presets Catalog

The `public.match_format_presets` catalog stores official system presets for the limited-overs cricket engine:

| Code (`id`) | Label | Overs | Default Players | Balls/Over | Innings | Max Overs/Bowler | Sort Order |
|---|---|---|---|---|---|---|---|
| `t20` | T20 | 20 | 11 | 6 | 1 | 4 | 10 |
| `t10` | T10 | 10 | 11 | 6 | 1 | 2 | 20 |
| `quick_6` | 6 Over | 6 | 8 | 6 | 1 | 2 | 30 |
| `quick_8` | 8 Over | 8 | 8 | 6 | 1 | 2 | 40 |
| `over_30` | 30 Over | 30 | 11 | 6 | 1 | 6 | 50 |
| `over_40` | 40 Over | 40 | 11 | 6 | 1 | 8 | 60 |
| `over_45` | 45 Over | 45 | 11 | 6 | 1 | 9 | 70 |
| `over_50` | 50 Over | 50 | 11 | 6 | 1 | 10 | 80 |
| `custom` | Custom | 12 | 11 | 6 | 1 | 3 | 90 |

### Discontinued / Unsupported Formats
The following formats are deliberately omitted from the active catalog in V1:
- `odi` & `list_a`: These are international/first-class tournament classifications, not grassroots friendly presets.
- `tape`: Ball type is a playing condition, not a format identity.
- `super8`: Team size (8-a-side) is a playing condition, not a format identity.
- `box`: Box cricket uses distinct indoor/wall-based rule families not represented in standard limited-overs scoring.
- `hundred`: Requires 100-ball semantics with 5/10 ball overs and bowler end-change logic.

---

## 3. Dynamic Bowler Limit Derivation

For arbitrary overs (including custom presets), the default bowler quota is derived via:
$$\text{suggestedBowlerLimit}(overs) = \lceil \frac{overs}{5} \rceil$$

Examples:
- 6 overs $\rightarrow$ 2
- 8 overs $\rightarrow$ 2
- 10 overs $\rightarrow$ 2
- 20 overs $\rightarrow$ 4
- 30 overs $\rightarrow$ 6
- 40 overs $\rightarrow$ 8
- 45 overs $\rightarrow$ 9
- 50 overs $\rightarrow$ 10

---

## 4. Server-Side Validation Rules

All format proposals (during challenge creation, counter-proposals, and pool applications) are strictly validated server-side:

### System Presets (`t20`, `t10`, `quick_6`, etc.)
1. `overs_per_innings`: Must match the exact preset value.
2. `balls_per_over`: Must be exactly 6.
3. `innings_per_side`: Must be exactly 1.
4. `max_overs_per_bowler`: Must match the exact preset quota.
5. `players_per_team`: Allowed range `5..15`.
6. `ball_type`: Must be one of `'leather'`, `'tape'`, `'tennis'`.

### Custom Format (`custom`)
1. `overs_per_innings`: Integer between `1` and `50`.
2. `players_per_team`: Integer between `5` and `15`.
3. `balls_per_over`: Integer between `1` and `12` (UI defaults: 5, 6, 8, custom).
4. `innings_per_side`: Must be exactly 1.
5. `max_overs_per_bowler`: Integer between `0` and `overs_per_innings` (0 denotes unlimited).
6. `ball_type`: Must be one of `'leather'`, `'tape'`, `'tennis'`.
7. `wickets_to_all_out`: Optional integer between `0` and `players_per_team - 1` (defaults to `players_per_team - 1` when null).

---

## 5. Challenge Storage & Snapshot Semantics

1. **`match_format_presets`**: Reference catalog used as the UI template during challenge draft creation.
2. **`match_challenges.proposed_format_code`**: Preserves the explicit format identity (e.g. `'t20'`).
3. **`match_challenges.proposed_format`**: Immutable snapshot of the agreed rules at creation time. Subsequent updates or deactivations of preset catalog rows do not affect pending, countered, or accepted challenges.
4. **`cricket_matches.format_code`**: Materialized from `challenge.proposed_format_code` (or `countered_format_code` if accepted).
5. **`cricket_matches.rules_snapshot`**: Materialized verbatim from the agreed format snapshot.
6. **No Silent Normalization**: Missing or invalid formats are never silently fallen back to T20; malformed requests are rejected with typed validation errors.
