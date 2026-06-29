import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/team_search_result.dart';

part 'team_search_state.freezed.dart';

/// Search-tab UI state. Concurrent fields with copyWith semantics — freezed
/// matches the codebase pattern (same call as TeamCreateState).
///
/// We model loading/error explicitly rather than wrapping the list in
/// `AsyncValue` for two reasons:
///   - the screen needs to render results + a refresh spinner overlay at
///     the same time (typing "lah" → "laho" should keep showing the old
///     list while the new request flies), and `AsyncValue.copyWithPrevious`
///     is `@internal` in riverpod 3.x;
///   - failures travel as the typed [Failure] (not an opaque Object) so the
///     screen can branch on `PermissionFailure` vs `NetworkFailure` vs
///     `ServerFailure` without `error is FailureWrapper` ceremony.
@freezed
abstract class TeamSearchState with _$TeamSearchState {
  const factory TeamSearchState({
    @Default('') String query,

    /// Active search centre. Non-null when "near me" is on OR a facet chip
    /// is picked. Drives proximity ranking / hard radius cutoff.
    double? centerLat,
    double? centerLng,

    /// Set when a facet chip is the centre source. Lets the UI render the
    /// chip as selected and distinguish "near me" from "facet" affordances.
    String? selectedFacetCity,

    /// Current near-me hard-radius cap in km. The sparse-area "expand" CTA
    /// doubles this; only relevant in near-me-browse mode (no [query]).
    @Default(25.0) double radiusKm,

    /// Last successfully loaded results. Stays populated under [loading] so
    /// the list does not blank on every keystroke.
    @Default(<TeamSearchResult>[]) List<TeamSearchResult> results,

    /// A search is in flight. Render as a refresh spinner over the existing
    /// list when [results] is non-empty; as a skeleton when empty.
    @Default(false) bool loading,

    /// The most recent failure. Cleared at the start of every search; set
    /// only when the round-trip returned [Left]. Survives subsequent
    /// successful searches only via [copyWith] explicit re-set.
    Failure? error,
  }) = _TeamSearchState;

  const TeamSearchState._();

  /// Empty initial state. Browse mode — the screen shows facet chips +
  /// "browse / recent" verified teams until the user types or toggles
  /// near-me.
  factory TeamSearchState.initial() => const TeamSearchState();

  bool get hasCenter => centerLat != null && centerLng != null;

  /// True when no input is active. The screen renders browse defaults
  /// (verified + recent + facet chips) instead of search results.
  bool get isBrowsing => query.trim().isEmpty && !hasCenter;
}
