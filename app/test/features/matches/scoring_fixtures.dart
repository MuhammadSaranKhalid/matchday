// Shared fixtures for the scoring write path.
//
// One lineup, one format, one innings row — used by the replay, session and
// controller tests so a change to the shape of a match does not have to be
// made in three places, and so those three are demonstrably talking about the
// same match.
import 'package:matchday/features/matches/domain/entities/ball.dart';
import 'package:matchday/features/matches/domain/entities/match.dart';
import 'package:matchday/features/matches/domain/entities/match_innings_state.dart';
import 'package:matchday/features/matches/domain/entities/match_player.dart';
import 'package:matchday/features/teams/domain/entities/team.dart';

const kMatchId = 'm1';
const kTeamA = TeamId('a');
const kTeamB = TeamId('b');

Match match({int oversPerInnings = 20, int ballsPerOver = 6}) => Match(
      id: const MatchId(kMatchId),
      teamAId: kTeamA,
      teamBId: kTeamB,
      format: MatchFormat(
        oversPerInnings: oversPerInnings,
        playersPerTeam: 11,
        ballType: MatchBallType.tape,
        maxOversPerBowler: 4,
        ballsPerOver: ballsPerOver,
      ),
      status: MatchStatus.live,
      createdBy: 'capA',
      createdAt: DateTime(2026),
      teamACaptain: 'capA',
      teamBCaptain: 'capB',
      tossWonBy: kTeamA,
      tossDecision: TossDecision.bat,
      startPhase: MatchStartPhase.live,
    );

List<MatchPlayer> lineup() => const [
      MatchPlayer(
        id: MatchPlayerId('mp1'),
        matchId: MatchId(kMatchId),
        teamSide: MatchTeamSide.a,
        profileId: 'p1',
        displayName: 'Striker',
      ),
      MatchPlayer(
        id: MatchPlayerId('mp2'),
        matchId: MatchId(kMatchId),
        teamSide: MatchTeamSide.a,
        profileId: 'p2',
        displayName: 'Non-striker',
      ),
      MatchPlayer(
        id: MatchPlayerId('mp3'),
        matchId: MatchId(kMatchId),
        teamSide: MatchTeamSide.a,
        profileId: 'p3',
        displayName: 'Next in',
      ),
      MatchPlayer(
        id: MatchPlayerId('mp9'),
        matchId: MatchId(kMatchId),
        teamSide: MatchTeamSide.b,
        profileId: 'p9',
        displayName: 'Bowler',
      ),
      MatchPlayer(
        id: MatchPlayerId('mp10'),
        matchId: MatchId(kMatchId),
        teamSide: MatchTeamSide.b,
        profileId: 'p10',
        displayName: 'Other bowler',
      ),
    ];

MatchInningsState innings({
  int legalBallCount = 0,
  int totalRuns = 0,
  int totalWickets = 0,
  int totalExtras = 0,
  int version = 1,
  String? strikerId = 'mp1',
  String? nonStrikerId = 'mp2',
  String? bowlerId = 'mp9',
  int? target,
}) =>
    MatchInningsState(
      matchId: const MatchId(kMatchId),
      inningsNumber: 1,
      version: version,
      updatedAt: DateTime(2026),
      strikerId: strikerId == null ? null : MatchPlayerId(strikerId),
      nonStrikerId: nonStrikerId == null ? null : MatchPlayerId(nonStrikerId),
      bowlerId: bowlerId == null ? null : MatchPlayerId(bowlerId),
      legalBallCount: legalBallCount,
      totalRuns: totalRuns,
      totalWickets: totalWickets,
      totalExtras: totalExtras,
      target: target,
    );

/// A confirmed delivery, as the server would return it.
Ball ball({
  required String id,
  required int seq,
  int runs = 1,
  int overNumber = 0,
  int ballInOver = 1,
  bool isLegalDelivery = true,
  BallKind kind = BallKind.legal,
  int extras = 0,
  bool isWicket = false,
}) =>
    Ball(
      id: BallId(id),
      matchId: const MatchId(kMatchId),
      inningsNumber: 1,
      seq: seq,
      overNumber: overNumber,
      ballInOver: ballInOver,
      isLegalDelivery: isLegalDelivery,
      ballKind: kind,
      runsScored: runs,
      extras: extras,
      isWicket: isWicket,
      isFreeHit: false,
      batsmanId: 'mp1',
      nonStrikerId: 'mp2',
      bowlerId: 'mp9',
    );

/// A delivery off the bat, as the scorer entered it.
BallDraft draft({int runs = 1, String? batsman = 'mp1'}) => BallDraft(
      matchId: const MatchId(kMatchId),
      inningsNumber: 1,
      isLegalDelivery: true,
      ballKind: BallKind.legal,
      runsScored: runs,
      batsmanId: batsman,
      nonStrikerId: 'mp2',
      bowlerId: 'mp9',
    );
