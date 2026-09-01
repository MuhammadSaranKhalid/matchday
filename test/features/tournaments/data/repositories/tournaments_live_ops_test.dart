import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/core/error/exceptions.dart';
import 'package:matchday/core/error/failures.dart';
import 'package:matchday/features/tournaments/data/datasources/tournaments_remote_datasource.dart';
import 'package:matchday/features/tournaments/data/repositories/tournaments_repository_impl.dart';
import 'package:matchday/features/tournaments/domain/entities/tournament_live_match.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements TournamentsRemoteDataSource {}

void main() {
  late _MockRemote remote;
  late TournamentsRepositoryImpl repo;

  setUp(() {
    remote = _MockRemote();
    repo = TournamentsRepositoryImpl(remote: remote);
  });

  group('abandonMatch', () {
    test('rejects a reschedule with no date, without calling the remote',
        () async {
      final result = await repo.abandonMatch(
        matchId: 'm1',
        mode: AbandonMode.reschedule,
      );

      expect(result.isLeft(), isTrue);
      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
      verifyNever(
        () => remote.abandonMatch(
          matchId: any(named: 'matchId'),
          mode: any(named: 'mode'),
          rescheduleTo: any(named: 'rescheduleTo'),
          reason: any(named: 'reason'),
        ),
      );
    });

    test('a no-result needs no date and passes the wire value through',
        () async {
      when(
        () => remote.abandonMatch(
          matchId: any(named: 'matchId'),
          mode: any(named: 'mode'),
          rescheduleTo: any(named: 'rescheduleTo'),
          reason: any(named: 'reason'),
        ),
      ).thenAnswer((_) async {});

      final result = await repo.abandonMatch(
        matchId: 'm1',
        mode: AbandonMode.noResult,
        reason: 'Rain',
      );

      expect(result.isRight(), isTrue);
      verify(
        () => remote.abandonMatch(
          matchId: 'm1',
          mode: 'no_result',
          rescheduleTo: null,
          reason: 'Rain',
        ),
      ).called(1);
    });

    test('translates a ServerException into a ServerFailure', () async {
      when(
        () => remote.abandonMatch(
          matchId: any(named: 'matchId'),
          mode: any(named: 'mode'),
          rescheduleTo: any(named: 'rescheduleTo'),
          reason: any(named: 'reason'),
        ),
      ).thenThrow(ServerException('Only tournament organizers can run live ops'));

      final result = await repo.abandonMatch(
        matchId: 'm1',
        mode: AbandonMode.noResult,
      );

      expect(result.getLeft().toNullable(), isA<ServerFailure>());
    });
  });

  group('overrideResult', () {
    test('requires a reason of at least 10 characters', () async {
      final result = await repo.overrideResult(
        matchId: 'm1',
        winnerTeamId: 't1',
        reason: 'typo',
      );

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
      verifyNever(
        () => remote.overrideResult(
          matchId: any(named: 'matchId'),
          winnerTeamId: any(named: 'winnerTeamId'),
          reason: any(named: 'reason'),
        ),
      );
    });

    test('trims the reason before sending it to the audit log', () async {
      when(
        () => remote.overrideResult(
          matchId: any(named: 'matchId'),
          winnerTeamId: any(named: 'winnerTeamId'),
          reason: any(named: 'reason'),
        ),
      ).thenAnswer((_) async {});

      final result = await repo.overrideResult(
        matchId: 'm1',
        winnerTeamId: 't1',
        reason: '  Scorer recorded 4 extra runs in the 18th over.  ',
      );

      expect(result.isRight(), isTrue);
      verify(
        () => remote.overrideResult(
          matchId: 'm1',
          winnerTeamId: 't1',
          reason: 'Scorer recorded 4 extra runs in the 18th over.',
        ),
      ).called(1);
    });
  });

  group('sendAnnouncement', () {
    test('rejects an empty message', () async {
      final result = await repo.sendAnnouncement(
        tournamentId: 't1',
        message: '   ',
      );
      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    });

    test('rejects a message over 300 characters', () async {
      final result = await repo.sendAnnouncement(
        tournamentId: 't1',
        message: 'x' * 301,
      );
      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    });

    test('returns the recipient count the RPC reports', () async {
      when(
        () => remote.sendAnnouncement(
          tournamentId: any(named: 'tournamentId'),
          message: any(named: 'message'),
        ),
      ).thenAnswer((_) async => 120);

      final result = await repo.sendAnnouncement(
        tournamentId: 't1',
        message: '  Rain delay, matches pushed back two hours.  ',
      );

      expect(result.getOrElse((_) => -1), 120);
      // The trimmed message is what goes out.
      verify(
        () => remote.sendAnnouncement(
          tournamentId: 't1',
          message: 'Rain delay, matches pushed back two hours.',
        ),
      ).called(1);
    });
  });

  group('LiveInningsLine', () {
    test('renders balls as cricket O.B over notation', () {
      const line = LiveInningsLine(
        inningsNumber: 2,
        battingTeamId: 't2',
        runs: 142,
        wickets: 3,
        legalBalls: 98,
      );
      // 98 balls = 16 overs and 2 balls.
      expect(line.oversText, '16.2');
      expect(line.scoreText, '142/3 (16.2)');
    });

    test('a completed 20-over innings reads as 20.0', () {
      const line = LiveInningsLine(
        inningsNumber: 1,
        battingTeamId: 't1',
        runs: 161,
        wickets: 7,
        legalBalls: 120,
      );
      expect(line.scoreText, '161/7 (20.0)');
    });
  });

  group('TournamentLiveMatch', () {
    TournamentLiveMatch match({
      String status = 'scheduled',
      String? scorerId,
    }) =>
        TournamentLiveMatch(
          matchId: 'm1',
          venue: 'Ground 1',
          status: status,
          scheduledStartTime: DateTime(2026, 9, 1, 9),
          scorerId: scorerId,
        );

    test('needsScorer is true only for an unfinished, unassigned fixture', () {
      expect(match().needsScorer, isTrue);
      expect(match(scorerId: 'u1').needsScorer, isFalse);
      // A finished match never needs a scorer, assigned or not.
      expect(match(status: 'completed').needsScorer, isFalse);
      expect(match(status: 'walkover').needsScorer, isFalse);
      expect(match(status: 'no_result').needsScorer, isFalse);
    });

    test('an innings break still counts as live', () {
      expect(match(status: 'live').isLive, isTrue);
      expect(match(status: 'innings_break').isLive, isTrue);
      expect(match(status: 'super_over').isLive, isTrue);
      expect(match(status: 'scheduled').isLive, isFalse);
    });
  });
}
