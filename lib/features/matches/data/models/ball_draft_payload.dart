// Wire format for the scoring write path.
//
// Two encodings live here, and they are not the same thing:
//
//   • `recordBallParams` — what the `record-ball` edge function reads. Verbose,
//     snake_case, and carrying a duplicate `p_`-prefixed alias for every key.
//   • `ballDraftToWal` / `trioToWal` — what the write-ahead log stores. Compact
//     and shaped like the domain, because a queued op has to be replayed
//     through the ENGINE (to paint the screen) as well as sent.
//
// Storing the RPC params in the log conflated the two, which is why the engine
// answer used to be frozen at tap time: replaying wire format back into engine
// input was not worth doing, so it wasn't done. Keeping the log in domain shape
// is what lets the projection derive the answer instead.
library;

import '../../domain/entities/ball.dart';
import '../../domain/entities/match.dart';

/// Current write-ahead log payload version for a queued delivery.
const _walVersion = 2;

/// The `record-ball` request body.
///
/// The `p_`-prefixed duplicates are a compatibility tail from when this was a
/// Postgres RPC rather than an edge function. They are cheap and some deployed
/// function versions still read them; drop them only together with a backend
/// release that no longer does.
Map<String, dynamic> recordBallParams(
  BallDraft d, {
  required String opId,
  required ComputedDelivery computed,
}) {
  final core = <String, dynamic>{
    'match_id': d.matchId.value,
    'innings_number': d.inningsNumber,
    'idempotency_key': opId,
    'is_legal_delivery': d.isLegalDelivery,
    'ball_type': d.ballKind.wire,
    'runs_scored': d.runsScored,
    'extras': d.extras,
    'is_wicket': d.isWicket,
    if (d.wicketType != null) 'wicket_type': d.wicketType!.wire,
    if (d.dismissedPlayerId != null) 'dismissed_player_id': d.dismissedPlayerId,
    if (d.batsmanId != null) 'batsman_id': d.batsmanId,
    if (d.nonStrikerId != null) 'non_striker_id': d.nonStrikerId,
    if (d.bowlerId != null) 'bowler_id': d.bowlerId,
    if (d.fielderId != null) 'fielder_id': d.fielderId,
    if (d.commentary != null) 'commentary': d.commentary,
    'over_number': computed.overNumber,
    'ball_in_over': computed.ballInOver,
    'is_free_hit': computed.isFreeHit,
    'is_bowler_credited': computed.isBowlerCredited,
    'balls_per_over': computed.ballsPerOver,
    'striker_after': computed.strikerAfter,
    'non_striker_after': computed.nonStrikerAfter,
    'bowler_after': computed.bowlerAfter,
    'is_all_out': computed.isAllOut,
    'innings_ended': computed.inningsEnded,
  };
  return {
    ...core,
    for (final e in core.entries) 'p_${e.key}': e.value,
  };
}

/// A queued delivery, as stored in the write-ahead log.
Map<String, dynamic> ballDraftToWal(BallDraft d) => <String, dynamic>{
      'v': _walVersion,
      'match_id': d.matchId.value,
      'innings_number': d.inningsNumber,
      'is_legal_delivery': d.isLegalDelivery,
      'ball_type': d.ballKind.wire,
      'runs_scored': d.runsScored,
      'extras': d.extras,
      'is_wicket': d.isWicket,
      'wicket_type': d.wicketType?.wire,
      'dismissed_player_id': d.dismissedPlayerId,
      'batsman_id': d.batsmanId,
      'non_striker_id': d.nonStrikerId,
      'bowler_id': d.bowlerId,
      'fielder_id': d.fielderId,
      'commentary': d.commentary,
    };

/// Read a queued delivery back out of the log.
///
/// Also accepts the pre-v2 payload, which was the raw `record-ball` body. A
/// device that scored through an outage and updated mid-match still holds
/// those, and they are deliveries somebody actually bowled — discarding them
/// to simplify this function would lose real runs.
BallDraft? ballDraftFromWal(Map<String, dynamic> json) {
  String? str(String key) {
    final v = json[key] ?? json['p_$key'];
    return v is String ? v : null;
  }

  int intOr(String key, int fallback) {
    final v = json[key] ?? json['p_$key'];
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  bool boolOr(String key, bool fallback) {
    final v = json[key] ?? json['p_$key'];
    return v is bool ? v : fallback;
  }

  final matchId = str('match_id');
  if (matchId == null) return null;

  return BallDraft(
    matchId: MatchId(matchId),
    inningsNumber: intOr('innings_number', 1),
    isLegalDelivery: boolOr('is_legal_delivery', true),
    ballKind: BallKind.fromWire(str('ball_type')),
    runsScored: intOr('runs_scored', 0),
    extras: intOr('extras', 0),
    isWicket: boolOr('is_wicket', false),
    wicketType: WicketType.fromWire(str('wicket_type')),
    dismissedPlayerId: str('dismissed_player_id'),
    batsmanId: str('batsman_id'),
    nonStrikerId: str('non_striker_id'),
    bowlerId: str('bowler_id'),
    fielderId: str('fielder_id'),
    commentary: str('commentary'),
  );
}

/// A queued trio change, as stored in the log. Key names match the pre-v2
/// shape so existing queued rows keep parsing.
Map<String, dynamic> trioToWal({
  required String matchId,
  required int inningsNumber,
  required String strikerId,
  required String nonStrikerId,
  required String bowlerId,
  int? target,
}) =>
    <String, dynamic>{
      'match_id': matchId,
      'innings_number': inningsNumber,
      'striker_id': strikerId,
      'non_striker_id': nonStrikerId,
      'bowler_id': bowlerId,
      'target': target,
    };

/// Read a queued trio change back out of the log. Null when the row predates
/// the fields it needs, in which case there is nothing to replay or send.
({
  String matchId,
  int inningsNumber,
  String strikerId,
  String nonStrikerId,
  String bowlerId,
  int? target,
})? trioFromWal(Map<String, dynamic> json) {
  String? str(String key) {
    final v = json[key] ?? json['p_$key'];
    return v is String ? v : null;
  }

  final matchId = str('match_id');
  final striker = str('striker_id');
  final nonStriker = str('non_striker_id');
  final bowler = str('bowler_id');
  if (matchId == null ||
      striker == null ||
      nonStriker == null ||
      bowler == null) {
    return null;
  }

  final rawInnings = json['innings_number'] ?? json['p_innings_number'];
  final rawTarget = json['target'] ?? json['p_target'];

  return (
    matchId: matchId,
    inningsNumber: rawInnings is num
        ? rawInnings.toInt()
        : int.tryParse('$rawInnings') ?? 1,
    strikerId: striker,
    nonStrikerId: nonStriker,
    bowlerId: bowler,
    target: rawTarget is num
        ? rawTarget.toInt()
        : (rawTarget == null ? null : int.tryParse('$rawTarget')),
  );
}
