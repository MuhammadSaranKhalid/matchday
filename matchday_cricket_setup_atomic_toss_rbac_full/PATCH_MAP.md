# Patch Map

## Migration

Create:

```bash
supabase migration new cricket_setup_atomic_toss_rbac
```

Use:

```text
migration/cricket_setup_atomic_toss_rbac.sql
```

Verification:

```text
migration/verify_cricket_setup_atomic_toss_rbac.sql
```

## Edge Function

Replace the entire:

```text
supabase/functions/cricket-match-action/
```

directory with the supplied directory.

Removed:

```text
commands/record_toss_winner.ts
commands/record_toss_decision.ts
```

Added:

```text
commands/record_toss.ts
```

## Flutter

Run:

```bash
python3 <package>/repo_tools/apply_flutter_and_repository_changes.py
```

Complete replacements:

```text
lib/features/matches/presentation/state/match_start_state.dart
lib/features/matches/presentation/controllers/match_start_controller.dart
lib/features/matches/presentation/widgets/match_start/stage_toss.dart
lib/features/matches/presentation/widgets/match_start/stage_lineup.dart
```

Strict current-main patches:

```text
lib/features/matches/domain/entities/match.dart
lib/features/matches/data/models/match_dto.dart
lib/features/matches/domain/repositories/matches_repository.dart
lib/features/matches/data/datasources/matches_remote_datasource.dart
lib/features/matches/data/repositories/matches_repository_impl.dart
lib/features/matches/presentation/providers/my_matches_providers.dart
lib/features/teams/domain/entities/team_relationship.dart
```

The client-facing `Match` gets `setupTeamId` and `tossRecordedBy`. `setupTeamId` is derived from the Cricket aggregate; it is not a generic `matches` column.

After patching:

```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```
