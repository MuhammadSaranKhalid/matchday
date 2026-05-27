import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/player_skills.dart';

part 'add_unclaimed_player_state.freezed.dart';

/// Three stops in the Add-as-unclaimed wizard:
///   * [name]    — Step 1 of 2: enter the player's display name
///   * [details] — Step 2 of 2: optional jersey + role + bat + bowl
///   * [success] — receipt + share-invite-code card
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

  /// True when the user has filled at least one Step-2 field. Drives the amber
  /// "details will be locked in until they edit" notice.
  bool get hasDetails =>
      jersey.trim().isNotEmpty ||
      playingRole != null ||
      battingStyle != null ||
      bowlingStyle != null;

  /// Parsed jersey number — null when blank or not parseable. The number's
  /// range (0–999) is validated by `JerseyNumber.create` at submit time.
  int? get jerseyNumber {
    final trimmed = jersey.trim();
    if (trimmed.isEmpty) return null;
    return int.tryParse(trimmed);
  }
}
