# `MatchDto` after Phase 3A

No field needs to be removed from the **Cricket-facing Dart DTO**.

That distinction is intentional:

```text
database storage
  matches                     -> generic only
  cricket_matches             -> Cricket only

read API
  cricket_match_details       -> flat Cricket aggregate

Flutter
  MatchDto                    -> consumes the flat Cricket aggregate
```

So fields such as:

```dart
teamACaptain
teamBCaptain
format
tossWonBy
tossDecision
startPhase
result
```

still belong in `MatchDto` because they come from `cricket_match_details`.

What should change is only its documentation. Replace the old opening comment:

```dart
/// Wire-format `matches` row...
```

with:

```dart
/// Cricket-facing match aggregate.
///
/// The shared `matches` table is sport-neutral. Cricket-only values in this
/// DTO (`format`, toss, start phase, result, captain snapshots) are supplied by
/// the `cricket_match_details` security-invoker view, which joins
/// `matches` + `cricket_matches` and derives captains from
/// `cricket_match_players`.
///
/// Do not point this DTO back at `matches`.
```
