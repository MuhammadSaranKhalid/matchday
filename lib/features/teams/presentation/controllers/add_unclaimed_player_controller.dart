import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/player_skills.dart';
import '../../domain/entities/team.dart';
import '../../domain/value_objects/jersey_number.dart';
import '../../domain/value_objects/player_display_name.dart';
import '../providers/teams_providers.dart';
import '../state/add_unclaimed_player_state.dart';

part 'add_unclaimed_player_controller.g.dart';

/// Drives the 2-step add-as-unclaimed wizard.
///
/// Pure form state — duplicate-name and jersey-clash detection live in the
/// screen (which has live access to the roster stream). The controller's job
/// is field state + step navigation + submit.
@riverpod
class AddUnclaimedPlayerController extends _$AddUnclaimedPlayerController {
  @override
  AddUnclaimedPlayerState build(String teamId) =>
      const AddUnclaimedPlayerState();

  // ─── Field setters ────────────────────────────────────────────────────────

  void setName(String v) => state = state.copyWith(name: v, submitError: null);
  void setJersey(String v) =>
      state = state.copyWith(jersey: v, submitError: null);
  void setPlayingRole(PlayingRole? r) =>
      state = state.copyWith(playingRole: r, submitError: null);
  void setBattingStyle(BattingStyle? b) =>
      state = state.copyWith(battingStyle: b, submitError: null);
  void setBowlingStyle(BowlingStyle? b) =>
      state = state.copyWith(bowlingStyle: b, submitError: null);

  // ─── Navigation ───────────────────────────────────────────────────────────

  void next() {
    if (state.step == AddUnclaimedPlayerStep.name) {
      state = state.copyWith(step: AddUnclaimedPlayerStep.details);
    }
  }

  void back() {
    if (state.step == AddUnclaimedPlayerStep.details) {
      state = state.copyWith(step: AddUnclaimedPlayerStep.name);
    }
  }

  // ─── Submit ───────────────────────────────────────────────────────────────

  /// Calls [AddUnclaimedPlayer] and advances to [AddUnclaimedPlayerStep.success]
  /// on Right. On Left, surfaces the failure message via [submitError]; the
  /// screen renders that as a SnackBar.
  Future<void> submit() async {
    if (state.submitting) return;
    state = state.copyWith(submitting: true, submitError: null);

    final nameRes = PlayerDisplayName.create(state.name);
    if (nameRes.isLeft()) {
      state = state.copyWith(
        submitting: false,
        submitError: nameRes.getLeft().toNullable()!.message,
      );
      return;
    }

    JerseyNumber? jersey;
    if (state.jerseyNumber != null) {
      final jerseyRes = JerseyNumber.create(state.jerseyNumber!);
      if (jerseyRes.isLeft()) {
        state = state.copyWith(
          submitting: false,
          submitError: jerseyRes.getLeft().toNullable()!.message,
        );
        return;
      }
      jersey = jerseyRes.getRight().toNullable();
    }

    final result = await ref.read(teamsRepositoryProvider).addUnclaimedPlayer(
          teamId: TeamId(teamId),
          displayName: nameRes.getRight().toNullable()!,
          jerseyNumber: jersey,
          playingRole: state.playingRole,
          battingStyle: state.battingStyle,
          bowlingStyle: state.bowlingStyle,
        );

    state = result.fold(
      (Failure f) => state.copyWith(submitting: false, submitError: f.message),
      (_) => state.copyWith(
        submitting: false,
        step: AddUnclaimedPlayerStep.success,
      ),
    );

    // The `team_members` table is not (yet) in the `supabase_realtime`
    // publication, so the open roster stream on the Team Page doesn't see
    // our new row pushed to it. Force a re-subscription — that emits a fresh
    // initial snapshot that DOES include the row.
    if (result.isRight()) {
      ref.invalidate(rosterProvider(teamId));
    }
  }

  /// Reset to the empty Step 1 — used by "Add another" on the success view.
  void resetForAnother() => state = const AddUnclaimedPlayerState();
}
