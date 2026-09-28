import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/core/error/exceptions.dart';
import 'package:matchday/core/error/failures.dart';
import 'package:matchday/features/tournaments/data/datasources/tournaments_remote_datasource.dart';
import 'package:matchday/features/tournaments/data/repositories/tournaments_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements TournamentsRemoteDataSource {}

class _FakeFile extends Fake implements File {}

void main() {
  late _MockRemote remote;
  late TournamentsRepositoryImpl repo;

  setUpAll(() => registerFallbackValue(_FakeFile()));

  setUp(() {
    remote = _MockRemote();
    repo = TournamentsRepositoryImpl(remote: remote);
  });

  test('with nothing to upload it short-circuits without touching storage',
      () async {
    final result = await repo.uploadArtwork(tournamentId: 't1');

    expect(result.isRight(), isTrue);
    final art = result.getOrElse((_) => throw Exception());
    expect(art.bannerUrl, isNull);
    expect(art.logoUrl, isNull);
    verifyNever(
      () => remote.uploadArtwork(
        tournamentId: any(named: 'tournamentId'),
        banner: any(named: 'banner'),
        logo: any(named: 'logo'),
      ),
    );
  });

  test('returns both URLs when both images are uploaded', () async {
    when(
      () => remote.uploadArtwork(
        tournamentId: any(named: 'tournamentId'),
        banner: any(named: 'banner'),
        logo: any(named: 'logo'),
      ),
    ).thenAnswer(
      (_) async => (
        bannerUrl: 'https://cdn/t1/banner.jpg?v=1',
        logoUrl: 'https://cdn/t1/logo.jpg?v=1',
      ),
    );

    final result = await repo.uploadArtwork(
      tournamentId: 't1',
      banner: _FakeFile(),
      logo: _FakeFile(),
    );

    final art = result.getOrElse((_) => throw Exception());
    expect(art.bannerUrl, 'https://cdn/t1/banner.jpg?v=1');
    expect(art.logoUrl, 'https://cdn/t1/logo.jpg?v=1');
  });

  test('a storage rejection surfaces as a Failure, never an exception',
      () async {
    // The realistic case: uploading before the tournament row exists, which
    // the storage policy denies because it authorises on the path's uuid.
    when(
      () => remote.uploadArtwork(
        tournamentId: any(named: 'tournamentId'),
        banner: any(named: 'banner'),
        logo: any(named: 'logo'),
      ),
    ).thenThrow(ServerException('new row violates row-level security policy'));

    final result = await repo.uploadArtwork(
      tournamentId: 't1',
      banner: _FakeFile(),
    );

    expect(result.getLeft().toNullable(), isA<ServerFailure>());
  });

  test('an unauthenticated upload maps to AuthFailure', () async {
    when(
      () => remote.uploadArtwork(
        tournamentId: any(named: 'tournamentId'),
        banner: any(named: 'banner'),
        logo: any(named: 'logo'),
      ),
    ).thenThrow(UnauthorizedException('Must be signed in'));

    final result = await repo.uploadArtwork(
      tournamentId: 't1',
      logo: _FakeFile(),
    );

    expect(result.getLeft().toNullable(), isA<AuthFailure>());
  });
}
