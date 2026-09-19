import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../../location/presentation/providers/location_providers.dart';
import '../../domain/entities/place_facet.dart';
import '../providers/teams_providers.dart';
import '../state/team_search_state.dart';

part 'team_search_controller.g.dart';

@riverpod
class TeamSearchController extends _$TeamSearchController {
  static const Duration _debounceWindow = Duration(milliseconds: 300);
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

  void setQuery(String q) {
    state = state.copyWith(query: q);
    _debounce?.cancel();
    _cancelInFlight();
    _debounce = Timer(_debounceWindow, _run);
  }

  Future<void> toggleNearMe() async {
    final wasNearMe = state.hasCenter && state.selectedFacetCity == null;
    if (wasNearMe) {
      state = state.copyWith(centerLat: null, centerLng: null);
      await _run();
      return;
    }
    final loc = await ref.read(locationRepositoryProvider).currentLocation();
    state = loc.fold(
      (failure) => state.copyWith(error: failure),
      (geo) => state.copyWith(
        centerLat: geo.latitude,
        centerLng: geo.longitude,
        selectedFacetCity: null,
        error: null,
      ),
    );
    if (state.hasCenter) await _run();
  }

  Future<void> selectFacet(PlaceFacet facet) async {
    state = state.copyWith(
      centerLat: facet.lat,
      centerLng: facet.lng,
      selectedFacetCity: facet.city,
    );
    await _run();
  }

  Future<void> clearCenter() async {
    state = state.copyWith(
      centerLat: null,
      centerLng: null,
      selectedFacetCity: null,
    );
    await _run();
  }

  Future<void> expandRadius() async {
    if (!state.hasCenter) return;
    final next = (state.radiusKm * 2).clamp(25.0, 200.0);
    if (next == state.radiusKm) return;
    state = state.copyWith(radiusKm: next);
    await _run();
  }

  Future<void> retry() => _run();

  Future<void> _run() async {
    final ticket = ++_ticket;
    _cancelInFlight();
    final abort = Completer<void>();
    _inFlightAbort = abort;

    state = state.copyWith(loading: true, error: null);

    final q = state.query.trim();
    final hasQuery = q.length >= _minQueryLen;
    final passRadius = !hasQuery && state.hasCenter;

    final res = await ref.read(teamsRepositoryProvider).searchTeams(
          query: hasQuery ? q : null,
          lat: state.centerLat,
          lng: state.centerLng,
          radiusKm: passRadius ? state.radiusKm : null,
          cancelSignal: abort.future,
        );

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
