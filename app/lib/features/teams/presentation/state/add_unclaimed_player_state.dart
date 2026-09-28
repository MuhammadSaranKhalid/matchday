import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../sports/cricket/domain/entities/cricket_player_profile.dart';

part 'add_unclaimed_player_state.freezed.dart';

enum AddUnclaimedPlayerStep { name, details, success }

@freezed
abstract class AddUnclaimedPlayerState with _$AddUnclaimedPlayerState {
  const factory AddUnclaimedPlayerState({
    @Default(AddUnclaimedPlayerStep.name) AddUnclaimedPlayerStep step,
    @Default('') String name,
    @Default('') String jersey,
    PlayerRole? playerRole,
    BattingStyle? battingStyle,
    BowlingStyle? bowlingStyle,
    @Default([]) List<BallType> preferredBallTypes,
    int? yearsPlaying,
    @Default(false) bool submitting,
    String? submitError,
  }) = _AddUnclaimedPlayerState;

  const AddUnclaimedPlayerState._();

  bool get hasDetails =>
      jersey.trim().isNotEmpty ||
      playerRole != null ||
      battingStyle != null ||
      bowlingStyle != null ||
      preferredBallTypes.isNotEmpty ||
      yearsPlaying != null;

  int? get jerseyNumber {
    final trimmed = jersey.trim();
    if (trimmed.isEmpty) return null;
    return int.tryParse(trimmed);
  }
}
