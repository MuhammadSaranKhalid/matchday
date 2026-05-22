import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../teams/domain/entities/team.dart';
import '../entities/ball.dart';
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

  /// The latest innings for a match (for opening the spectator/scorer by match).
  Future<Either<Failure, Innings?>> getCurrentInnings(MatchId matchId);

  /// Mark a match completed with a result description. Moves to `completed`.
  Future<Either<Failure, Match>> completeMatch({
    required MatchId id,
    required String description,
  });

  /// Persist one delivery ([BallDraft]) and update the innings' current
  /// striker/non-striker/bowler. Aggregate totals update via a DB trigger.
  /// Returns the refreshed innings.
  Future<Either<Failure, Innings>> recordBall(BallDraft draft);

  /// Live deliveries for an innings (oldest first), via Supabase realtime.
  Stream<List<Ball>> watchBalls(InningsId inningsId);

  /// Live innings state (totals + current players), via Supabase realtime.
  Stream<Innings?> watchInnings(InningsId inningsId);
}
