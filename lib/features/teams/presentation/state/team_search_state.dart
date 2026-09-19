import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/team_search_result.dart';

part 'team_search_state.freezed.dart';

@freezed
abstract class TeamSearchState with _$TeamSearchState {
  const factory TeamSearchState({
    @Default('') String query,
    double? centerLat,
    double? centerLng,
    String? selectedFacetCity,
    @Default(25.0) double radiusKm,
    @Default(<TeamSearchResult>[]) List<TeamSearchResult> results,
    @Default(false) bool loading,
    Failure? error,
  }) = _TeamSearchState;

  const TeamSearchState._();

  factory TeamSearchState.initial() => const TeamSearchState();

  bool get hasCenter => centerLat != null && centerLng != null;
  bool get isBrowsing => query.trim().isEmpty && !hasCenter;
}
