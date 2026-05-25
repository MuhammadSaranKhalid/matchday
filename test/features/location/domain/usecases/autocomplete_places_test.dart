import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novex_clean_arch/core/error/failures.dart';
import 'package:novex_clean_arch/features/location/domain/entities/place_suggestion.dart';
import 'package:novex_clean_arch/features/location/domain/repositories/location_repository.dart';
import 'package:novex_clean_arch/features/location/domain/usecases/autocomplete_places.dart';

class _MockLocationRepo extends Mock implements LocationRepository {}

void main() {
  late _MockLocationRepo repo;
  late AutocompletePlaces useCase;

  setUp(() {
    repo = _MockLocationRepo();
    useCase = AutocompletePlaces(repo);
  });

  test('short-circuits a too-short query without hitting the repo', () async {
    final result = await useCase(
      const AutocompletePlacesParams(query: 'a', sessionToken: 't'),
    );
    expect(result, equals(const Right<Failure, List<PlaceSuggestion>>([])));
    verifyNever(() => repo.autocomplete(
          any(),
          sessionToken: any(named: 'sessionToken'),
          languageCode: any(named: 'languageCode'),
          regionCode: any(named: 'regionCode'),
        ));
  });

  test('trims then short-circuits a whitespace-padded short query', () async {
    final result = await useCase(
      const AutocompletePlacesParams(query: '  m ', sessionToken: 't'),
    );
    expect(result.getRight().toNullable(), isEmpty);
    verifyNever(() => repo.autocomplete(
          any(),
          sessionToken: any(named: 'sessionToken'),
          languageCode: any(named: 'languageCode'),
          regionCode: any(named: 'regionCode'),
        ));
  });

  test('delegates a long-enough query with its session + locale', () async {
    const suggestions = [
      PlaceSuggestion(
        placeId: 'p1',
        primaryText: 'Mardan',
        secondaryText: 'Khyber Pakhtunkhwa, Pakistan',
      ),
    ];
    when(() => repo.autocomplete(
          any(),
          sessionToken: any(named: 'sessionToken'),
          languageCode: any(named: 'languageCode'),
          regionCode: any(named: 'regionCode'),
        )).thenAnswer((_) async => const Right(suggestions));

    final result = await useCase(const AutocompletePlacesParams(
      query: 'mard',
      sessionToken: 'sess-1',
      languageCode: 'en',
      regionCode: 'PK',
    ));

    expect(result.getRight().toNullable(), suggestions);
    verify(() => repo.autocomplete(
          'mard',
          sessionToken: 'sess-1',
          languageCode: 'en',
          regionCode: 'PK',
        )).called(1);
  });
}
