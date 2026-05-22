import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/match.dart';

part 'match_setup_state.freezed.dart';

/// The wizard steps. Type is fixed to Friendly in Phase 1; scorer is fixed to
/// "Me". The thin-roster gate resolver and propose-changes flows are v1.1.
enum MatchSetupStep { type, opponent, format, whenWhere, scorer, pickXi, review }

@freezed
abstract class MatchSetupState with _$MatchSetupState {
  const factory MatchSetupState({
    @Default(MatchSetupStep.type) MatchSetupStep step,
    String? opponentId,
    String? opponentName,
    @Default(20) int overs,
    @Default(11) int playersPerTeam,
    @Default(MatchBallType.tape) MatchBallType ballType,
    @Default(4) int maxOversPerBowler,
    DateTime? when,
    @Default('') String venueGround,
    @Default('') String venueCity,
    @Default(<String>{}) Set<String> selectedPlayers,
    String? captainId,
    String? keeperId,
    @Default(false) bool submitting,
    String? submitError,
    String? createdMatchId,
  }) = _MatchSetupState;

  const MatchSetupState._();

  bool get canPickOpponent => opponentId != null;
  bool get canFormat => overs > 0 && playersPerTeam >= 2;
  bool get canWhenWhere => when != null && venueGround.trim().isNotEmpty;
  bool get xiComplete =>
      selectedPlayers.length == playersPerTeam &&
      captainId != null &&
      selectedPlayers.contains(captainId);

  MatchFormat get format => MatchFormat(
        oversPerInnings: overs,
        playersPerTeam: playersPerTeam,
        ballType: ballType,
        maxOversPerBowler: maxOversPerBowler,
      );
}
