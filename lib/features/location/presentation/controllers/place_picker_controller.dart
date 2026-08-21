import 'dart:async';
import 'dart:math';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/geo_place.dart';
import '../../domain/entities/place_suggestion.dart';
import '../providers/location_providers.dart';
import '../state/place_picker_state.dart';

part 'place_picker_controller.g.dart';

/// Drives one place-autocomplete field.
///
/// Keyed by [field] so two pickers on the same screen (say a team's city and
/// its home ground) keep independent state and independent billing sessions.
///
/// Session tokens: Google bills autocomplete keystrokes as one session when
/// they share a token and that token is passed to the eventual details call.
/// A new token is minted after every resolution — reusing one across
/// selections is billed as separate sessions anyway and muddies analytics.
@riverpod
class PlacePicker extends _$PlacePicker {
  static const Duration _debounceWindow = Duration(milliseconds: 300);

  /// Google's autocomplete returns nothing useful for one character, and a
  /// keystroke costs money.
  static const int _minQueryLen = 2;

  Timer? _debounce;
  int _ticket = 0;
  String _sessionToken = _mintToken();

  @override
  PlacePickerState build(String field) {
    ref.onDispose(() {
      _debounce?.cancel();
      _debounce = null;
    });
    return const PlacePickerState();
  }

  /// User typed. Debounced; clears any previously resolved place because the
  /// text no longer describes it.
  void setQuery(String q) {
    state = state.copyWith(query: q, picked: null, error: null);
    _debounce?.cancel();

    if (q.trim().length < _minQueryLen) {
      _ticket++;
      state = state.copyWith(suggestions: const [], searching: false);
      return;
    }
    _debounce = Timer(_debounceWindow, _autocomplete);
  }

  /// User tapped a prediction. Resolves it to coordinates.
  Future<void> select(PlaceSuggestion suggestion) async {
    _debounce?.cancel();
    state = state.copyWith(
      query: suggestion.fullText,
      suggestions: const [],
      resolving: true,
      error: null,
    );

    final res = await ref.read(locationRepositoryProvider).placeDetails(
          suggestion.placeId,
          sessionToken: _sessionToken,
        );
    if (!ref.mounted) return;

    // The session closes with the details call either way.
    _sessionToken = _mintToken();

    state = res.fold(
      (failure) => state.copyWith(resolving: false, error: failure),
      (place) => state.copyWith(
        resolving: false,
        picked: place,
        query: place.city ?? place.label,
      ),
    );
  }

  /// "Use my location" — reads the device GPS and reverse-geocodes it. This
  /// is the path that works for villages no gazetteer lists.
  Future<void> useCurrentLocation() async {
    _debounce?.cancel();
    state = state.copyWith(resolving: true, error: null, suggestions: const []);

    final res = await ref.read(locationRepositoryProvider).currentLocation();
    if (!ref.mounted) return;

    state = res.fold(
      (failure) => state.copyWith(resolving: false, error: failure),
      (place) => state.copyWith(
        resolving: false,
        picked: place,
        query: place.city ?? place.label,
      ),
    );
  }

  /// Last resort: keep the typed text with no coordinates. Explicitly
  /// modelled rather than implicit, so a caller can tell "typed, unresolved"
  /// from "resolved" and warn the user their team will not be findable by
  /// distance.
  void keepAsTyped() {
    _debounce?.cancel();
    _ticket++;
    state = state.copyWith(
      suggestions: const [],
      searching: false,
      picked: GeoPlace.manual(state.query),
    );
  }

  Future<void> _autocomplete() async {
    final ticket = ++_ticket;
    state = state.copyWith(searching: true);

    final res = await ref.read(locationRepositoryProvider).autocomplete(
          state.query.trim(),
          sessionToken: _sessionToken,
        );

    if (ticket != _ticket || !ref.mounted) return;

    state = res.fold(
      // A failed prediction is not worth an error banner — the user can keep
      // typing, and the GPS + keep-as-typed paths still work.
      (_) => state.copyWith(searching: false, suggestions: const []),
      (list) => state.copyWith(searching: false, suggestions: list),
    );
  }

  /// Google requires a UUID-shaped token; it does not have to be a real v4,
  /// only unique per session. Avoids pulling the `uuid` package in here.
  static String _mintToken() {
    final r = Random();
    String hex(int n) => List.generate(
          n,
          (_) => r.nextInt(16).toRadixString(16),
        ).join();
    return '${hex(8)}-${hex(4)}-4${hex(3)}-a${hex(3)}-${hex(12)}';
  }
}
