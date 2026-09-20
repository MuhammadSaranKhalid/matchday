import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../../sports/cricket/domain/entities/cricket_player_profile.dart';
import '../../domain/entities/team.dart';
import '../../domain/value_objects/jersey_number.dart';
import '../../domain/value_objects/player_display_name.dart';
import '../providers/team_membership_providers.dart';
import '../state/add_unclaimed_player_state.dart';

part 'add_unclaimed_player_controller.g.dart';

@riverpod
class AddUnclaimedPlayerController extends _$AddUnclaimedPlayerController {
  @override
  AddUnclaimedPlayerState build(String teamId) =>
      const AddUnclaimedPlayerState();

  void setName(String v) => state = state.copyWith(name: v, submitError: null);
  void setJersey(String v) =>
      state = state.copyWith(jersey: v, submitError: null);
  void setPlayerRole(PlayerRole? r) =>
      state = state.copyWith(playerRole: r, submitError: null);
  void setBattingStyle(BattingStyle? b) =>
      state = state.copyWith(battingStyle: b, submitError: null);
  void setBowlingStyle(BowlingStyle? b) =>
      state = state.copyWith(bowlingStyle: b, submitError: null);

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

    final result = await ref.read(teamMembershipRepositoryProvider).addUnclaimedCricketPlayer(
          teamId: TeamId(teamId),
          displayName: nameRes.getRight().toNullable()!,
          jerseyNumber: jersey,
          playerRole: state.playerRole,
          battingStyle: state.battingStyle,
          bowlingStyle: state.bowlingStyle,
          preferredBallTypes: state.preferredBallTypes,
          yearsPlaying: state.yearsPlaying,
        );

    state = result.fold(
      (Failure f) => state.copyWith(submitting: false, submitError: f.message),
      (_) => state.copyWith(
        submitting: false,
        step: AddUnclaimedPlayerStep.success,
      ),
    );

    if (result.isRight()) {
      ref.invalidate(rosterProvider(teamId));
    }
  }

  void resetForAnother() => state = const AddUnclaimedPlayerState();
}
