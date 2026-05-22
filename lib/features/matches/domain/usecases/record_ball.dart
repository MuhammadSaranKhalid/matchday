import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/ball.dart';
import '../entities/innings.dart';
import '../repositories/matches_repository.dart';

/// Records one delivery: computes its over/ball numbers, runs, boundary/wicket
/// flags, and the resulting strike rotation, then persists it. The innings
/// aggregate totals are updated by a DB trigger; this use case owns the
/// "current players" state (strike rotation, new batter, bowler change).
///
/// Phase 1 cases: normal runs, boundary 4/6, wide(+runs), no-ball(+bat runs),
/// wicket. Bye/leg-bye and run-out/stumping choreography are later cases.
class RecordBall implements UseCase<Innings, RecordBallParams> {
  const RecordBall(this._repo);
  final MatchesRepository _repo;

  @override
  Future<Either<Failure, Innings>> call(RecordBallParams p) async {
    final inn = p.innings;
    final input = p.input;

    final striker = inn.currentStrikerId;
    final nonStriker = inn.currentNonStrikerId;
    final bowler = inn.currentBowlerId;
    if (striker == null || nonStriker == null || bowler == null) {
      return const Left(ValidationFailure('Match has no active batters/bowler'));
    }
    if (input.runsOffBat < 0 || input.runsOffBat > 6) {
      return const Left(ValidationFailure('Runs off the bat must be 0–6'));
    }

    final extra = input.extraType;
    final legal = extra == null || extra == ExtraType.bye || extra == ExtraType.legBye;

    // Runs split.
    final runsOffBat = extra == ExtraType.wide ? 0 : input.runsOffBat;
    final extraRuns = switch (extra) {
      ExtraType.wide => 1 + input.extraRuns,
      ExtraType.noBall => 1 + input.extraRuns,
      ExtraType.bye || ExtraType.legBye || ExtraType.penalty => input.extraRuns,
      null => 0,
    };
    final total = runsOffBat + extraRuns;
    final isFour = extra == null && runsOffBat == 4;
    final isSix = extra == null && runsOffBat == 6;

    // Numbering. For an illegal delivery (wide/no-ball) legalBallNumber holds
    // the count BEFORE this ball — i.e. the same value as the preceding legal
    // delivery — since it doesn't advance the over.
    final legalBefore = inn.totalBallsFaced;
    final legalBallNumber = legalBefore + (legal ? 1 : 0);
    final overNumber = legalBefore ~/ 6;
    final ballNumber = p.deliveriesThisOver + 1;
    final overEnds = legal && legalBallNumber % 6 == 0;

    // Strike rotation.
    var s = striker, ns = nonStriker, b = bowler;
    if (runsOffBat.isOdd) {
      final t = s;
      s = ns;
      ns = t;
    }
    if (input.isWicket) {
      final dismissed = input.dismissedPlayerId ?? striker;
      if (input.newStrikerId == null) {
        return const Left(ValidationFailure('Select the next batter'));
      }
      if (dismissed == s) {
        s = input.newStrikerId!;
      } else if (dismissed == ns) {
        ns = input.newStrikerId!;
      } else {
        s = input.newStrikerId!;
      }
    }
    if (overEnds) {
      final t = s;
      s = ns;
      ns = t;
      if (input.newBowlerId == null) {
        return const Left(ValidationFailure('Select the next over\'s bowler'));
      }
      b = input.newBowlerId!;
    }

    final draft = BallDraft(
      inningsId: inn.id,
      matchId: inn.matchId,
      overNumber: overNumber,
      ballNumber: ballNumber,
      legalBallNumber: legalBallNumber,
      bowlerId: bowler,
      strikerId: striker,
      nonStrikerId: nonStriker,
      runsScored: runsOffBat,
      extraRuns: extraRuns,
      totalRuns: total,
      extraType: extra,
      isFour: isFour,
      isSix: isSix,
      isWicket: input.isWicket,
      wicketType: input.wicketType,
      dismissedPlayerId: input.isWicket
          ? (input.dismissedPlayerId ?? striker)
          : null,
      nextStrikerId: s,
      nextNonStrikerId: ns,
      nextBowlerId: b,
      overEnded: overEnds,
    );

    return _repo.recordBall(draft);
  }
}

/// What the scorer entered, plus any choreography ids the UI supplies.
class BallInput {
  const BallInput({
    this.runsOffBat = 0,
    this.extraType,
    this.extraRuns = 0,
    this.isWicket = false,
    this.wicketType,
    this.dismissedPlayerId,
    this.newStrikerId,
    this.newBowlerId,
  });

  final int runsOffBat;
  final ExtraType? extraType;

  /// Extra runs beyond the 1-run penalty (e.g. wide that went for 2 → 1).
  final int extraRuns;
  final bool isWicket;
  final WicketType? wicketType;
  final String? dismissedPlayerId;

  /// Incoming batter after a wicket; next-over bowler when the over ends.
  final String? newStrikerId;
  final String? newBowlerId;
}

class RecordBallParams {
  const RecordBallParams({
    required this.innings,
    required this.input,
    required this.deliveriesThisOver,
  });

  final Innings innings;
  final BallInput input;

  /// Deliveries already bowled in the current over (incl. extras) — drives
  /// `ball_number`.
  final int deliveriesThisOver;
}
