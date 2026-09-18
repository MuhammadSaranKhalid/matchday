import 'dart:async';

import 'package:matchday/core/error/failures.dart';
import 'package:matchday/features/explore/domain/entities/explore_results.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../providers/explore_providers.dart';
import '../state/explore_state.dart';
import 'recent_searches_controller.dart';

part 'explore_controller.g.dart';

/// Drives the Explore tab.
///
/// A stateful [Notifier] rather than an `AsyncNotifier<ExploreResults>`,
/// because three concerns need state an AsyncValue cannot carry:
///   1. Debounced keystrokes (300 ms) so we do not fire a request per letter.
///   2. In-flight abort signal to cancel the superseded Supabase Edge Function request.
///   3. Race-defeat — a slow "lah" must not overwrite a faster "lahore"
///      reply. [_ticket] increments per dispatch; only the newest may write.
///   4. Loading that PRESERVES the previous list, so the results never blank
///      between keystrokes (artboard 06 is explicit about this).
///
/// The debounce timer and in-flight request are cancelled in [Ref.onDispose].
@riverpod
class ExploreController extends _$ExploreController {
  /// 300 ms: the spec's figure (§7.5.1), the industry norm, and what the
  /// existing team-search controller already uses. Tune in one place.
  static const Duration _debounceWindow = Duration(milliseconds: 300);

  static const int _minQueryLen = 2;

  Timer? _debounce;
  Completer<void>? _inFlightAbort;
  int _ticket = 0;

  @override
  ExploreState build() {
    ref.onDispose(() {
      _debounce?.cancel();
      _debounce = null;
      _cancelInFlight();
    });
    return ExploreState.initial();
  }

  void _cancelInFlight() {
    if (_inFlightAbort != null && !_inFlightAbort!.isCompleted) {
      _inFlightAbort!.complete();
    }
    _inFlightAbort = null;
  }

  // ─── Actions ───────────────────────────────────────────────────────────────

  /// Update the query and re-search after the debounce window. Falling back
  /// below the minimum length returns to browse and cancels any pending
  /// request rather than firing an empty search.
  void setQuery(String q) {
    state = state.copyWith(query: q);
    _debounce?.cancel();
    _cancelInFlight();

    if (q.trim().length < _minQueryLen) {
      // Invalidate any in-flight reply so it cannot land after the user has
      // already cleared the field.
      _ticket++;
      state = state.copyWith(loading: false, error: null);
      return;
    }
    _debounce = Timer(_debounceWindow, _run);
  }

  /// Field gained or lost focus. Focus with an empty query shows recents.
  void setFocused({required bool focused}) =>
      state = state.copyWith(searchFocused: focused);

  /// Clear the field and return to browse.
  void clearQuery() {
    _debounce?.cancel();
    _cancelInFlight();
    _ticket++;
    state = state.copyWith(
      query: '',
      resultsQuery: '',
      results: ExploreResults.empty,
      loading: false,
      error: null,
    );
  }

  /// Run a query immediately, skipping the debounce — for a tapped recent
  /// search or suggestion chip. Records it in history, since it is an
  /// explicit submission rather than a keystroke.
  Future<void> submitQuery(String q) async {
    _debounce?.cancel();
    _cancelInFlight();
    state = state.copyWith(query: q, searchFocused: false);
    if (q.trim().length < _minQueryLen) return;
    await ref.read(recentSearchesProvider.notifier).record(q);
    await _run();
  }

  /// Commit whatever is currently typed to history (keyboard "search" key).
  Future<void> commitCurrentQuery() async {
    final q = state.query.trim();
    if (q.length < _minQueryLen) return;
    await ref.read(recentSearchesProvider.notifier).record(q);
  }

  /// Inline retry from the error state. Only meaningful while a query is
  /// active — browse retries by invalidating `exploreBrowseProvider`.
  Future<void> retry() async {
    if (state.hasQuery) await _run();
  }

  // ─── Internal ──────────────────────────────────────────────────────────────

  Future<void> _run() async {
    final ticket = ++_ticket;
    _cancelInFlight();
    final abort = Completer<void>();
    _inFlightAbort = abort;

    state = state.copyWith(loading: true, error: null);

    final q = state.query.trim();
    final res = await ref.read(exploreRepositoryProvider).search(
          q,
          cancelSignal: abort.future,
        );

    // Race-defeat: a newer search already started, or the notifier is gone.
    if (ticket != _ticket || !ref.mounted) return;

    state = res.fold(
      (failure) {
        if (failure is CancelledFailure) return state;
        return state.copyWith(loading: false, error: failure);
      },
      (results) => state.copyWith(
        loading: false,
        results: results,
        // Pin the highlight to the query these results are for, not the one
        // currently in the field.
        resultsQuery: q,
        error: null,
      ),
    );
  }
}
