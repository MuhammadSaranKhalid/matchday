import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/place_facet.dart';
import 'teams_providers.dart';

part 'team_search_providers.g.dart';

/// Top cities by team count for the search filter chips. Cached per
/// [countryCode] (null = caller's profile country, defaulted server-side).
///
/// Facets change slowly (a new team materialising in a new village isn't
/// continuous traffic), so this stays autodispose — the provider rebuilds
/// when the Search tab is opened again, and a pull-to-refresh triggers
/// `ref.invalidate`. We deliberately do NOT subscribe to a realtime stream
/// here; facet drift is fine.
@riverpod
Future<List<PlaceFacet>> placeFacets(Ref ref, String? countryCode) async {
  final res = await ref
      .watch(teamsRepositoryProvider)
      .teamPlaceFacets(countryCode: countryCode);
  return res.fold(
    (failure) => throw FailureWrapper(failure),
    (list) => list,
  );
}
