import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/explore_results.dart';

part 'explore_state.freezed.dart';

/// Explore tab state.
///
/// Concurrent fields with copyWith semantics, matching [TeamSearchState] —
/// loading and error are modelled explicitly rather than wrapping the results
/// in `AsyncValue`, for the same two reasons:
///   - the screen renders results AND a refreshing indicator at once (typing
///     "lah" → "laho" must keep the old list visible), and
///     `AsyncValue.copyWithPrevious` is `@internal` in riverpod 3.x;
///   - failures travel as the typed [Failure] so the screen can branch on
///     `NetworkFailure` vs `ServerFailure` without unwrapping ceremony.
@freezed
abstract class ExploreState with _$ExploreState {
  const factory ExploreState({
    @Default('') String query,

    /// The query the currently-displayed [results] were fetched for. Used to
    /// highlight matched substrings — highlighting against the live [query]
    /// would flicker the highlight ahead of the data during the debounce.
    @Default('') String resultsQuery,

    /// Last successfully loaded search results. Retained under [loading] so
    /// the list does not blank on every keystroke.
    @Default(ExploreResults.empty) ExploreResults results,

    /// True while the field is focused with no query — shows recents and
    /// suggestions instead of browse content (artboard 04).
    @Default(false) bool searchFocused,

    /// A request is in flight. Render as a thin indeterminate bar over the
    /// existing list; as a skeleton only when there is nothing to keep.
    @Default(false) bool loading,

    /// Most recent failure. Cleared at the start of every request.
    Failure? error,
  }) = _ExploreState;

  const ExploreState._();

  factory ExploreState.initial() => const ExploreState();

  /// A query long enough to have been sent to the server.
  bool get hasQuery => query.trim().length >= 2;

  /// Show the recents/suggestions panel: focused, nothing typed yet.
  bool get showRecents => searchFocused && query.trim().isEmpty;

  /// Show the discovery sections: not searching, not in the recents panel.
  bool get showBrowse => !hasQuery && !showRecents;

  /// Results came back empty for a query that was actually sent.
  bool get isNoResults =>
      hasQuery && !loading && error == null && results.isEmpty;
}
