import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/place_facet.dart';
import 'teams_providers.dart';

part 'team_search_providers.g.dart';

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
