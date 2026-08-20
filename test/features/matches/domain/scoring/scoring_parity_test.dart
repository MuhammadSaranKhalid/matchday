// The parity check itself.
//
// This is the production oracle: every delivery in every real match compares
// the client engine's prediction to the server's authoritative answer. It has
// to catch real divergence and — just as important — must not cry wolf about
// fields only the server can know, or the channel gets ignored and stops
// working as an alarm at all.
import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/features/matches/domain/entities/ball.dart';
import 'package:matchday/features/matches/domain/entities/match.dart';
import 'package:matchday/features/matches/domain/entities/match_innings_state.dart';
import 'package:matchday/features/matches/domain/entities/match_player.dart';
import 'package:matchday/features/matches/domain/scoring/scoring_parity.dart';
import 'package:matchday/features/matches/domain/scoring/scoring_types.dart';

const _matchId = MatchId('m1');

ComputedBall _predicted({
  int runsScored = 4,
  int ballInOver = 1,
  bool isFreeHit = false,
}) =>
    ComputedBall(
      overNumber: 0,
      ballInOver: ballInOver,
      isFreeHit: isFreeHit,
      isLegalDelivery: true,
      ballKind: BallKind.legal,
      runsScored: runsScored,
      extras: 0,
      isWicket: false,
    );

Ball _actual({
  int runsScored = 4,
  int ballInOver = 1,
  bool isFreeHit = false,
  int seq = 7,
}) =>
    Ball(
      id: const BallId('server-assigned'),
      matchId: _matchId,
      inningsNumber: 1,
      seq: seq,
      overNumber: 0,
      ballInOver: ballInOver,
      isLegalDelivery: true,
      ballKind: BallKind.legal,
      runsScored: runsScored,
      extras: 0,
      isWicket: false,
      isFreeHit: isFreeHit,
    );

NewInningsState _predictedState({
  String? striker = 'mp1',
  String? nonStriker = 'mp2',
  int totalRuns = 4,
}) =>
    NewInningsState(
      legalBallCount: 1,
      totalRuns: totalRuns,
      totalWickets: 0,
      totalExtras: 0,
      strikerId: striker,
      nonStrikerId: nonStriker,
      bowlerId: 'mp9',
    );

MatchInningsState _actualState({
  String? striker = 'mp1',
  String? nonStriker = 'mp2',
  int totalRuns = 4,
}) =>
    MatchInningsState(
      matchId: _matchId,
      inningsNumber: 1,
      version: 2,
      updatedAt: DateTime(2026),
      strikerId: striker == null ? null : MatchPlayerId(striker),
      nonStrikerId: nonStriker == null ? null : MatchPlayerId(nonStriker),
      bowlerId: const MatchPlayerId('mp9'),
      legalBallCount: 1,
      totalRuns: totalRuns,
    );

void main() {
  test('identical computations agree', () {
    final report = compareParity(
      predictedBall: _predicted(),
      predictedState: _predictedState(),
      actualBall: _actual(),
      actualInnings: _actualState(),
    );

    expect(report.agrees, isTrue, reason: report.summary);
    expect(report.diffs, isEmpty);
  });

  test('server-assigned fields are not treated as divergence', () {
    // `seq`, the ball id and timestamps are the database's to decide. Flagging
    // them would fire on every single delivery and train everyone to ignore
    // the channel — which would cost us the one alarm that matters.
    final report = compareParity(
      predictedBall: _predicted(),
      predictedState: _predictedState(),
      actualBall: _actual(seq: 999),
      actualInnings: _actualState(),
    );

    expect(report.agrees, isTrue, reason: report.summary);
  });

  test('a runs disagreement is caught and named', () {
    final report = compareParity(
      predictedBall: _predicted(runsScored: 4),
      predictedState: _predictedState(),
      actualBall: _actual(runsScored: 6),
      actualInnings: _actualState(),
    );

    expect(report.agrees, isFalse);
    expect(report.summary, contains('ball.runsScored'));
    expect(report.summary, contains('predicted=4'));
    expect(report.summary, contains('actual=6'));
  });

  test('a strike-rotation disagreement is caught', () {
    // The important one. This is the shape of the wide-attribution bug: the
    // runs are right, so the scoreboard looks correct, while the batters are
    // at the wrong ends and the scorecard is quietly wrong.
    final report = compareParity(
      predictedBall: _predicted(),
      predictedState: _predictedState(striker: 'mp1', nonStriker: 'mp2'),
      actualBall: _actual(),
      actualInnings: _actualState(striker: 'mp2', nonStriker: 'mp1'),
    );

    expect(report.agrees, isFalse);
    expect(report.summary, contains('state.strikerId'));
    expect(report.summary, contains('state.nonStrikerId'));
  });

  test('a free-hit disagreement is caught', () {
    final report = compareParity(
      predictedBall: _predicted(isFreeHit: true),
      predictedState: _predictedState(),
      actualBall: _actual(isFreeHit: false),
      actualInnings: _actualState(),
    );

    expect(report.agrees, isFalse);
    expect(report.summary, contains('ball.isFreeHit'));
  });

  test('a missing innings row skips that half rather than alarming', () {
    // An older deployment of record-ball does not return the innings row.
    // Reporting every field as a mismatch would be a false alarm on every
    // delivery.
    final report = compareParity(
      predictedBall: _predicted(),
      predictedState: _predictedState(),
      actualBall: _actual(),
    );

    expect(report.agrees, isTrue, reason: report.summary);
  });

  test('all disagreements are reported, not just the first', () {
    final report = compareParity(
      predictedBall: _predicted(runsScored: 4, ballInOver: 1),
      predictedState: _predictedState(totalRuns: 4),
      actualBall: _actual(runsScored: 6, ballInOver: 2),
      actualInnings: _actualState(totalRuns: 6),
    );

    expect(report.diffs.length, greaterThanOrEqualTo(3));
  });
}
