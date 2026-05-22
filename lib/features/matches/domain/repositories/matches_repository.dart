import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../teams/domain/entities/team.dart';
import '../entities/innings.dart';
import '../entities/match.dart';

/// Online-only matches contract (Phase 1). Reads/writes hit Supabase directly;
/// no local mirror.
abstract class MatchesRepository {
  /// Propose a friendly. Creates a match in [MatchStatus.pending] with team A's
  /// side filled in.
  Future<Either<Failure, Match>> createMatchRequest({
    required TeamId teamAId,
    required TeamId teamBId,
    required MatchFormat format,
    required List<String> squad,
    required String captain,
    String? keeper,
    Venue? venue,
    DateTime? scheduledStartTime,
  });

  Future<Either<Failure, Match?>> getMatch(MatchId id);

  /// Matches involving any team the user owns/manages.
  Future<Either<Failure, List<Match>>> listMyMatches();

  /// Opponent accepts: fills team B's side and moves the match to `accepted`.
  Future<Either<Failure, Match>> acceptMatch({
    required MatchId id,
    required List<String> squad,
    required String captain,
    String? keeper,
  });

  /// Opponent declines, with an optional reason. Moves to `declined`.
  Future<Either<Failure, Match>> declineMatch({
    required MatchId id,
    String? reason,
  });

  /// Single-phone match start: records the toss, creates innings 1 with its
  /// openers, and moves the match accepted → live. Returns the new innings.
  Future<Either<Failure, Innings>> startMatch({
    required MatchId id,
    required TeamId tossWonBy,
    required TossDecision tossDecision,
    required TeamId battingTeamId,
    required TeamId bowlingTeamId,
    required String strikerId,
    required String nonStrikerId,
    required String bowlerId,
  });
}
