import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/core/error/exceptions.dart';
import 'package:matchday/core/error/failures.dart';
import 'package:matchday/features/tournaments/data/datasources/tournaments_remote_datasource.dart';
import 'package:matchday/features/tournaments/data/repositories/tournaments_repository_impl.dart';
import 'package:matchday/features/tournaments/domain/entities/match_official.dart';
import 'package:matchday/features/tournaments/domain/entities/tournament_fee_entry.dart';
import 'package:matchday/features/tournaments/domain/ops/revised_target.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements TournamentsRemoteDataSource {}

void main() {
  late _MockRemote remote;
  late TournamentsRepositoryImpl repo;

  setUpAll(() {
    registerFallbackValue(PaymentChannel.cash);
    registerFallbackValue(OfficialRole.umpireMain);
    registerFallbackValue(TargetMethod.runRate);
  });

  setUp(() {
    remote = _MockRemote();
    repo = TournamentsRepositoryImpl(remote: remote);
  });

  // ─── recordPayment (artboard 24c) ───────────────────────────────────────────

  group('recordPayment', () {
    void stub() {
      when(
        () => remote.recordPayment(
          registrationId: any(named: 'registrationId'),
          amountPaid: any(named: 'amountPaid'),
          channel: any(named: 'channel'),
          reference: any(named: 'reference'),
        ),
      ).thenAnswer((_) async {});
    }

    test('rejects a negative amount without calling the remote', () async {
      final result = await repo.recordPayment(
        registrationId: 'r1',
        amountPaid: -1,
      );

      expect(result.isLeft(), isTrue);
      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
      verifyNever(
        () => remote.recordPayment(
          registrationId: any(named: 'registrationId'),
          amountPaid: any(named: 'amountPaid'),
        ),
      );
    });

    test('rejects a reference longer than the column', () async {
      final result = await repo.recordPayment(
        registrationId: 'r1',
        amountPaid: 100,
        reference: 'x' * 201,
      );

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    });

    test('trims the reference and drops an empty one', () async {
      stub();
      await repo.recordPayment(
        registrationId: 'r1',
        amountPaid: 5000,
        channel: PaymentChannel.cash,
        reference: '   ',
      );

      verify(
        () => remote.recordPayment(
          registrationId: 'r1',
          amountPaid: 5000,
          channel: PaymentChannel.cash,
          reference: null,
        ),
      ).called(1);
    });

    test('translates a server exception into a ServerFailure', () async {
      when(
        () => remote.recordPayment(
          registrationId: any(named: 'registrationId'),
          amountPaid: any(named: 'amountPaid'),
          channel: any(named: 'channel'),
          reference: any(named: 'reference'),
        ),
      ).thenThrow(ServerException('nope'));

      final result = await repo.recordPayment(
        registrationId: 'r1',
        amountPaid: 1,
      );

      expect(result.getLeft().toNullable(), isA<ServerFailure>());
    });
  });

  // ─── Officials (artboard 27j) ───────────────────────────────────────────────

  group('assignOfficial', () {
    test('refuses the scorer role — it has its own path', () async {
      final result = await repo.assignOfficial(
        matchId: 'm1',
        userId: 'u1',
        role: OfficialRole.scorer,
      );

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
      verifyNever(
        () => remote.assignOfficial(
          matchId: any(named: 'matchId'),
          userId: any(named: 'userId'),
          role: any(named: 'role'),
        ),
      );
    });

    test('forwards an umpire appointment', () async {
      when(
        () => remote.assignOfficial(
          matchId: any(named: 'matchId'),
          userId: any(named: 'userId'),
          role: any(named: 'role'),
        ),
      ).thenAnswer((_) async {});

      final result = await repo.assignOfficial(
        matchId: 'm1',
        userId: 'u1',
        role: OfficialRole.umpireLeg,
      );

      expect(result.isRight(), isTrue);
      verify(
        () => remote.assignOfficial(
          matchId: 'm1',
          userId: 'u1',
          role: OfficialRole.umpireLeg,
        ),
      ).called(1);
    });
  });

  group('removeOfficial', () {
    test('refuses to clear the scorer', () async {
      final result = await repo.removeOfficial(
        matchId: 'm1',
        role: OfficialRole.scorer,
      );

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    });
  });

  // ─── Rain revision (artboards 27m, 28b) ─────────────────────────────────────

  group('reviseMatchConditions', () {
    void stub() {
      when(
        () => remote.reviseMatchConditions(
          matchId: any(named: 'matchId'),
          revisedOvers: any(named: 'revisedOvers'),
          bowlerQuota: any(named: 'bowlerQuota'),
          revisedTarget: any(named: 'revisedTarget'),
          method: any(named: 'method'),
          reason: any(named: 'reason'),
        ),
      ).thenAnswer((_) async {});
    }

    test('enforces the five-over floor before the round trip', () async {
      final result = await repo.reviseMatchConditions(
        matchId: 'm1',
        revisedOvers: 4,
        bowlerQuota: 1,
      );

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
      verifyNever(
        () => remote.reviseMatchConditions(
          matchId: any(named: 'matchId'),
          revisedOvers: any(named: 'revisedOvers'),
          bowlerQuota: any(named: 'bowlerQuota'),
        ),
      );
    });

    test('rejects a bowler quota of zero', () async {
      final result = await repo.reviseMatchConditions(
        matchId: 'm1',
        revisedOvers: 15,
        bowlerQuota: 0,
      );

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    });

    test('forwards a valid revision with its method', () async {
      stub();
      final result = await repo.reviseMatchConditions(
        matchId: 'm1',
        revisedOvers: 14,
        bowlerQuota: 3,
        revisedTarget: 112,
        method: TargetMethod.dls,
        reason: 'Rain, 26 minutes lost',
      );

      expect(result.isRight(), isTrue);
      verify(
        () => remote.reviseMatchConditions(
          matchId: 'm1',
          revisedOvers: 14,
          bowlerQuota: 3,
          revisedTarget: 112,
          method: TargetMethod.dls,
          reason: 'Rain, 26 minutes lost',
        ),
      ).called(1);
    });
  });

  // ─── Super over (artboard 28c) ──────────────────────────────────────────────

  test('triggerSuperOver forwards the side batting first', () async {
    when(
      () => remote.triggerSuperOver(
        matchId: any(named: 'matchId'),
        batsFirstTeamId: any(named: 'batsFirstTeamId'),
      ),
    ).thenAnswer((_) async {});

    final result = await repo.triggerSuperOver(
      matchId: 'm31',
      batsFirstTeamId: 'gl',
    );

    expect(result.isRight(), isTrue);
    verify(
      () => remote.triggerSuperOver(matchId: 'm31', batsFirstTeamId: 'gl'),
    ).called(1);
  });

  // ─── Auto-assign (artboard 27k) ─────────────────────────────────────────────

  test('autoAssignScorers returns how many fixtures it filled', () async {
    when(() => remote.autoAssignScorers(any())).thenAnswer((_) async => 3);

    final result = await repo.autoAssignScorers('t1');

    expect(result.getRight().toNullable(), 3);
  });

  test('autoAssignScorers surfaces a permission error as AuthFailure', () async {
    when(() => remote.autoAssignScorers(any()))
        .thenThrow(UnauthorizedException('not an organiser'));

    final result = await repo.autoAssignScorers('t1');

    expect(result.getLeft().toNullable(), isA<AuthFailure>());
  });
}
