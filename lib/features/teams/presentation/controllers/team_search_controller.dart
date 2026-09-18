import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../../location/presentation/providers/location_providers.dart';
import '../../domain/entities/place_facet.dart';
import '../providers/teams_providers.dart';
import '../state/team_search_state.dart';

part 'team_search_controller.g.dart';

/// Drives the Search tab. Stateful Notifier with `Future<void>` action
/// methods + error-in-state — matches the codebase's prevailing controller
/// convention.
///
/// Three real concerns this Notifier manages that an `AsyncNotifier<List>`
/// could not:
///   1. Debounced keystrokes (300 ms) so we don't fire a request per letter.
///   2. In-flight abort signal to cancel the superseded Supabase Edge Function request.
///   3. Race-defeat — a slow "lah" must not stomp a faster "lahore" reply.
///      [_ticket] increments on every dispatched search; only the latest
///      ticket's result is allowed to write state.
///   4. Loading transitions that preserve the previous list (`state.loading
///      = true` with `state.results` retained) so the screen does not
///      flicker to a skeleton on every keystroke.
///
/// The debounce timer and in-flight request are cancelled in [Ref.onDispose].
@riverpod
class TeamSearchController extends _$TeamSearchController {
  /// 300 ms matches the doc (§14) and industry norm for type-ahead. Tune
  /// in one place; do not scatter `Duration` literals.
  static const Duration _debounceWindow = Duration(milliseconds: 300);

  /// Below this length we treat the query as absent (browse mode). The
  /// trigram threshold makes 1-char queries effectively useless and we'd
  /// rather not pay the round-trip.
  static const int _minQueryLen = 2;

  Timer? _debounce;
  Completer<void>? _inFlightAbort;
  int _ticket = 0;

  @override
  TeamSearchState build() {
    ref.onDispose(() {
      _debounce?.cancel();
      _debounce = null;
      _cancelInFlight();
    });
    return TeamSearchState.initial();
  }

  void _cancelInFlight() {
    if (_inFlightAbort != null && !_inFlightAbort!.isCompleted) {
      _inFlightAbort!.complete();
    }
    _inFlightAbort = null;
  }

  // ─── Setters / actions ───────────────────────────────────────────────────

  /// Update the query and re-fetch after the debounce window. Empty / short
  /// queries fall back to browse mode (or near-me / facet mode if a centre
  /// is set).
  void setQuery(String q) {
    state = state.copyWith(query: q);
    _debounce?.cancel();
    _cancelInFlight();
    _debounce = Timer(_debounceWindow, _run);
  }

  /// Toggle near-me. If a centre is already set from the device GPS, clear
  /// it. Otherwise read the GPS once and use it. Permission / service
  /// errors surface via [state.error] so the screen can prompt; the centre
  /// stays null on failure (a stale "near me" tile would keep ranking).
  Future<void> toggleNearMe() async {
    final wasNearMe = state.hasCenter && state.selectedFacetCity == null;
    if (wasNearMe) {
      state = state.copyWith(centerLat: null, centerLng: null);
      await _run();
      return;
    }
    final loc = await ref
        .read(locationRepositoryProvider)
        .currentLocation();
    final next = loc.fold(
      (failure) => state.copyWith(error: failure),
      (geo) => state.copyWith(
        centerLat: geo.latitude,
        centerLng: geo.longitude,
        selectedFacetCity: null,
        error: null,
      ),
    );
    state = next;
    if (state.hasCenter) await _run();
  }

  /// Tap a city facet. Uses the facet's centroid as the search centre; the
  /// previous near-me / facet selection is replaced.
  Future<void> selectFacet(PlaceFacet facet) async {
    state = state.copyWith(
      centerLat: facet.lat,
      centerLng: facet.lng,
      selectedFacetCity: facet.city,
    );
    await _run();
  }

  /// Drop the current centre (facet or near-me). Browse mode resumes if
  /// the query is also empty.
  Future<void> clearCenter() async {
    state = state.copyWith(
      centerLat: null,
      centerLng: null,
      selectedFacetCity: null,
    );
    await _run();
  }

  /// Sparse-area CTA. Doubles the near-me radius (capped at 200 km) and
  /// re-fetches. No-op when there's no centre.
  Future<void> expandRadius() async {
    if (!state.hasCenter) return;
    final next = (state.radiusKm * 2).clamp(25.0, 200.0);
    if (next == state.radiusKm) return;
    state = state.copyWith(radiusKm: next);
    await _run();
  }

  /// Inline retry from the error state.
  Future<void> retry() => _run();

  // ─── Internal ────────────────────────────────────────────────────────────

  Future<void> _run() async {
    final ticket = ++_ticket;
    _cancelInFlight();
    final abort = Completer<void>();
    _inFlightAbort = abort;

    state = state.copyWith(loading: true, error: null);

    final q = state.query.trim();
    final hasQuery = q.length >= _minQueryLen;
    // The server reads `radiusKm` only in near-me-browse (q==null + centre);
    // in blend / browse modes the server ignores it. Pass it only when it
    // matters so a server-side default change doesn't fight a stale client
    // value.
    final passRadius = !hasQuery && state.hasCenter;

    final res = await ref.read(teamsRepositoryProvider).searchTeams(
          query: hasQuery ? q : null,
          lat: state.centerLat,
          lng: state.centerLng,
          radiusKm: passRadius ? state.radiusKm : null,
          cancelSignal: abort.future,
        );

    // Race-defeat: a newer search has already started; let it win.
    if (ticket != _ticket || !ref.mounted) return;

    state = res.fold(
      (failure) {
        if (failure is CancelledFailure) return state;
        return state.copyWith(loading: false, error: failure);
      },
      (list) => state.copyWith(loading: false, results: list, error: null),
    );
  }
}
