import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/core/error/exceptions.dart';
import 'package:matchday/core/error/failures.dart';
import 'package:matchday/features/tournaments/data/datasources/tournaments_remote_datasource.dart';
import 'package:matchday/features/tournaments/data/models/ground_dto.dart';
import 'package:matchday/features/tournaments/data/repositories/tournaments_repository_impl.dart';
import 'package:matchday/features/tournaments/domain/entities/ground.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements TournamentsRemoteDataSource {}

void main() {
  late _MockRemote remote;
  late TournamentsRepositoryImpl repo;

  setUp(() {
    remote = _MockRemote();
    repo = TournamentsRepositoryImpl(remote: remote);
  });

  group('GroundDto', () {
    test('reads a table row, lifting city and coords out of location', () {
      final ground = GroundDto.fromJson({
        'ground_id': 'g1',
        'name': 'Model Town Ground',
        'location': {'city': 'Lahore', 'lat': 31.5, 'lng': 74.3},
        'surface': 'turf',
        'has_floodlights': true,
      }).toEntity();

      expect(ground.id, 'g1');
      expect(ground.city, 'Lahore');
      expect(ground.latitude, 31.5);
      expect(ground.longitude, 74.3);
      expect(ground.surface, GroundSurface.turf);
      expect(ground.hasFloodlights, isTrue);
      expect(ground.distanceKm, isNull);
    });

    test('reads a search row, where city is flat and distance is present', () {
      final ground = GroundDto.fromJson({
        'ground_id': 'g2',
        'name': 'LCCA Ground',
        'city': 'Lahore',
        'surface': 'matting',
        'has_floodlights': false,
        'distance_km': 4.25,
      }).toEntity();

      expect(ground.city, 'Lahore');
      expect(ground.distanceKm, 4.25);
      // No location jsonb on this shape — coordinates stay null.
      expect(ground.latitude, isNull);
    });

    test('an unknown surface degrades to null rather than throwing', () {
      final ground = GroundDto.fromJson({
        'ground_id': 'g3',
        'name': 'Somewhere',
        'surface': 'moon-dust',
      }).toEntity();
      expect(ground.surface, isNull);
    });
  });

  group('Ground.facilities', () {
    test('joins surface and floodlights into the wizard line', () {
      const g = Ground(
        id: 'g1',
        name: 'Model Town Ground',
        surface: GroundSurface.turf,
        hasFloodlights: true,
      );
      expect(g.facilities, 'Turf · floodlights');
    });

    test('falls back to notes when nothing structured is known', () {
      const g = Ground(id: 'g1', name: 'X', notes: 'Behind the school');
      expect(g.facilities, 'Behind the school');
    });

    test('is null when there is nothing to say', () {
      const g = Ground(id: 'g1', name: 'X');
      expect(g.facilities, isNull);
    });
  });

  group('createGround', () {
    test('rejects a name shorter than the table CHECK allows', () async {
      final result = await repo.createGround(name: ' A ');

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
      verifyNever(
        () => remote.createGround(
          name: any(named: 'name'),
          city: any(named: 'city'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          surface: any(named: 'surface'),
          hasFloodlights: any(named: 'hasFloodlights'),
          notes: any(named: 'notes'),
        ),
      );
    });

    test('trims before sending', () async {
      when(
        () => remote.createGround(
          name: any(named: 'name'),
          city: any(named: 'city'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          surface: any(named: 'surface'),
          hasFloodlights: any(named: 'hasFloodlights'),
          notes: any(named: 'notes'),
        ),
      ).thenAnswer(
        (_) async => const Ground(id: 'g9', name: 'Model Town Ground'),
      );

      final result = await repo.createGround(name: '  Model Town Ground  ');

      expect(result.isRight(), isTrue);
      verify(
        () => remote.createGround(
          name: 'Model Town Ground',
          city: null,
          latitude: null,
          longitude: null,
          surface: null,
          hasFloodlights: false,
          notes: null,
        ),
      ).called(1);
    });

    test('translates an unauthorized write into an AuthFailure', () async {
      when(
        () => remote.createGround(
          name: any(named: 'name'),
          city: any(named: 'city'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          surface: any(named: 'surface'),
          hasFloodlights: any(named: 'hasFloodlights'),
          notes: any(named: 'notes'),
        ),
      ).thenThrow(UnauthorizedException('Must be signed in'));

      final result = await repo.createGround(name: 'Model Town Ground');
      expect(result.getLeft().toNullable(), isA<AuthFailure>());
    });
  });

  group('setTournamentGrounds', () {
    test('passes the list through in order — order drives the G1/G2 labels',
        () async {
      when(
        () => remote.setTournamentGrounds(
          tournamentId: any(named: 'tournamentId'),
          groundIds: any(named: 'groundIds'),
        ),
      ).thenAnswer((_) async {});

      final result = await repo.setTournamentGrounds(
        tournamentId: 't1',
        groundIds: ['g2', 'g1'],
      );

      expect(result.isRight(), isTrue);
      verify(
        () => remote.setTournamentGrounds(
          tournamentId: 't1',
          groundIds: ['g2', 'g1'],
        ),
      ).called(1);
    });
  });
}
