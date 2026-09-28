import 'package:equatable/equatable.dart';

import 'match.dart';
import 'match_innings_state.dart';
import 'match_player.dart';

class MatchRoomCapabilities extends Equatable {
  const MatchRoomCapabilities({
    this.canRecordToss = false,
    this.canSetupInnings = false,
    this.canAddParticipant = false,
    this.canScore = false,
  });

  final bool canRecordToss;
  final bool canSetupInnings;
  final bool canAddParticipant;
  final bool canScore;

  @override
  List<Object?> get props => [
    canRecordToss,
    canSetupInnings,
    canAddParticipant,
    canScore,
  ];
}

class MatchRoomSnapshot extends Equatable {
  const MatchRoomSnapshot({
    required this.match,
    required this.revision,
    required this.participants,
    required this.capabilities,
    required this.serverTime,
    this.innings,
    this.scorerLease,
  });

  final Match match;
  final int revision;
  final List<MatchPlayer> participants;
  final MatchInningsState? innings;
  final MatchRoomCapabilities capabilities;
  final Map<String, dynamic>? scorerLease;
  final DateTime serverTime;

  @override
  List<Object?> get props => [
    match,
    revision,
    participants,
    innings,
    capabilities,
    scorerLease,
    serverTime,
  ];
}
