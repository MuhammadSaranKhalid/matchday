import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/player_skills.dart';

part 'add_unclaimed_player_state.freezed.dart';

enum AddUnclaimedPlayerStep { name, details, success }

@freezed
abstract class AddUnclaimedPlayerState with _$AddUnclaimedPlayerState {
  const factory AddUnclaimedPlayerState({
    @Default(AddUnclaimedPlayerStep.name) AddUnclaimedPlayerStep step,
    @Default('') String name,
    @Default('') String jersey,
    PlayingRole? playingRole,
    BattingStyle? battingStyle,
    BowlingStyle? bowlingStyle,
    @Default(false) bool submitting,
    String? submitError,
  }) = _AddUnclaimedPlayerState;

  const AddUnclaimedPlayerState._();

  bool get hasDetails =>
      jersey.trim().isNotEmpty ||
      playingRole != null ||
      battingStyle != null ||
      bowlingStyle != null;

  int? get jerseyNumber {
    final trimmed = jersey.trim();
    if (trimmed.isEmpty) return null;
    return int.tryParse(trimmed);
  }
}
