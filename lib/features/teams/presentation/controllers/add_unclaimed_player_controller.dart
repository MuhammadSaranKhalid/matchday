import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/player_skills.dart';
import '../../domain/entities/team.dart';
import '../../domain/usecases/add_unclaimed_player.dart';
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

    final result = await ref.read(addUnclaimedPlayerUseCaseProvider).call(
          AddUnclaimedPlayerParams(
            teamId: TeamId(teamId),
            displayName: state.name,
            jerseyNumber: state.jerseyNumber,
            playingRole: state.playingRole,
            battingStyle: state.battingStyle,
            bowlingStyle: state.bowlingStyle,
          ),
        );

    state = result.fold(
      (Failure f) => state.copyWith(submitting: false, submitError: f.message),
      (_) => state.copyWith(
        submitting: false,
        step: AddUnclaimedPlayerStep.success,
      ),
    );
  }

  /// Reset to the empty Step 1 — used by "Add another" on the success view.
  void resetForAnother() => state = const AddUnclaimedPlayerState();
}
