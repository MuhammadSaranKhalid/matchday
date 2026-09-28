import '../../domain/entities/match_room_snapshot.dart';
import 'match_dto.dart';
import 'match_innings_state_dto.dart';
import 'match_player_dto.dart';

class MatchRoomSnapshotDto {
  const MatchRoomSnapshotDto({
    required this.match,
    required this.revision,
    required this.participants,
    required this.capabilities,
    required this.serverTime,
    this.innings,
    this.scorerLease,
  });

  factory MatchRoomSnapshotDto.fromJson(Map<String, dynamic> json) {
    final match = _map(json['match']);
    if (match == null) throw const FormatException('Missing match snapshot');
    final capabilities = _map(json['capabilities']) ?? const {};
    final participantRows = json['participants'];
    final innings = _map(json['innings']);
    return MatchRoomSnapshotDto(
      match: MatchDto.fromJson(match),
      revision: _wireInt(json['revision']),
      participants:
          participantRows is List
              ? participantRows
                  .whereType<Map<Object?, Object?>>()
                  .map(
                    (row) =>
                        MatchPlayerDto.fromJson(Map<String, dynamic>.from(row)),
                  )
                  .toList(growable: false)
              : const [],
      innings: innings == null ? null : MatchInningsStateDto.fromJson(innings),
      capabilities: MatchRoomCapabilities(
        canRecordToss: capabilities['can_record_toss'] == true,
        canSetupInnings: capabilities['can_setup_innings'] == true,
        canAddParticipant: capabilities['can_add_participant'] == true,
        canScore: capabilities['can_score'] == true,
      ),
      scorerLease: _map(json['scorer_lease']),
      serverTime:
          DateTime.tryParse((json['server_time'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  final MatchDto match;
  final int revision;
  final List<MatchPlayerDto> participants;
  final MatchInningsStateDto? innings;
  final MatchRoomCapabilities capabilities;
  final Map<String, dynamic>? scorerLease;
  final DateTime serverTime;

  MatchRoomSnapshot toEntity() => MatchRoomSnapshot(
    match: match.toEntity(),
    revision: revision,
    participants: participants.map((player) => player.toEntity()).toList(),
    innings: innings?.toEntity(),
    capabilities: capabilities,
    scorerLease: scorerLease,
    serverTime: serverTime,
  );
}

Map<String, dynamic>? _map(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : null;

int _wireInt(Object? value) => switch (value) {
  final int value => value,
  final num value => value.toInt(),
  final String value => int.tryParse(value) ?? 0,
  _ => 0,
};
