import 'dart:async';
import 'dart:ui' as ui;

import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/database/database_provider.dart';
import '../../../location/domain/entities/place_suggestion.dart';
import '../../../location/presentation/providers/location_providers.dart';
import '../../domain/entities/player_profile.dart';
import '../../domain/value_objects/city.dart';
import '../../domain/value_objects/display_name.dart';
import '../../domain/value_objects/username.dart';
import '../providers/onboarding_providers.dart';
import '../state/onboarding_state.dart';

part 'onboarding_controller.g.dart';

/// Drives the onboarding wizard: profile → player → welcome.
///
/// An [AsyncNotifier] so [build] can restore a persisted draft before the form
/// seeds. Once loaded, sub-states (username checking, submitting) live as
/// fields on [OnboardingState] rather than flipping the [AsyncValue] to
/// loading, so the form never disappears mid-edit.
@riverpod
class OnboardingController extends _$OnboardingController {
  Timer? _usernameDebounce;
  Timer? _cityDebounce;
  final _uuid = const Uuid();

  // Constant key is safe: AppDatabase.clear() wipes all wizard drafts on
  // sign-out, so a different user on the same device never inherits this one.
  static const _draftKey = 'onboarding';

  // Skip the autocomplete network call on 0–1 char queries (pure noise +
  // burns quota); the Places API never returns useful predictions below 2.
  static const _minAutocompleteLength = 2;

  @override
  Future<OnboardingState> build() async {
    ref.onDispose(() {
      _usernameDebounce?.cancel();
      _cityDebounce?.cancel();
    });

    final draft = await ref.read(wizardDraftStoreProvider).load(_draftKey);
    var initial =
        draft == null ? const OnboardingState() : _fromDraft(draft);

    // A restored username needs re-verifying — availability can change between
    // sessions and we never persist the "available" verdict.
    if (initial.username.isNotEmpty &&
        Username.create(initial.username).isRight()) {
      initial = initial.copyWith(usernameStatus: UsernameStatus.checking);
      _scheduleAvailabilityCheck(initial.username);
    }
    return initial;
  }

  OnboardingState? get _s => state.value;

  void _set(OnboardingState next, {bool persist = true}) {
    state = AsyncData(next);
    if (persist && !next.completed) _persistDraft(next);
  }

  // ─── Profile step ─────────────────────────────────────────────────────────

  void setDisplayName(String value) {
    final s = _s;
    if (s == null) return;
    _set(s.copyWith(displayName: value));
  }

  /// The user typed in the city field. Editing the text invalidates any
  /// previously resolved coordinates (they're now hand-editing → treated as
  /// manual until they pick a suggestion or use GPS), then debounces a search.
  void setCity(String value) {
    final s = _s;
    if (s == null) return;
    _set(s.copyWith(
      city: value,
      placeId: null,
      lat: null,
      lng: null,
      countryCode: null,
      cityError: null,
    ));
    _scheduleCitySearch(value);
  }

  void _scheduleCitySearch(String query) {
    _cityDebounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.length < _minAutocompleteLength) {
      final s = _s;
      if (s != null) {
        _set(
          s.copyWith(citySuggestions: const [], citySearching: false),
          persist: false,
        );
      }
      return;
    }

    final s0 = _s;
    if (s0 == null) return;
    // One session token spans the keystrokes of a search and the eventual
    // details lookup, so Google bills the whole thing as a single session.
    final token = s0.citySessionToken ?? _uuid.v4();
    _set(
      s0.copyWith(citySearching: true, citySessionToken: token),
      persist: false,
    );

    _cityDebounce = Timer(const Duration(milliseconds: 350), () async {
      final locale = ui.PlatformDispatcher.instance.locale;
      final result = await ref.read(locationRepositoryProvider).autocomplete(
            trimmed,
            sessionToken: token,
            languageCode:
                locale.languageCode.isEmpty ? null : locale.languageCode,
            regionCode: locale.countryCode,
          );
      // Bail if the user kept typing while the request was in flight.
      final s = _s;
      if (s == null || s.city.trim() != trimmed) return;
      result.fold(
        (_) => _set(
          s.copyWith(citySearching: false, citySuggestions: const []),
          persist: false,
        ),
        (list) => _set(
          s.copyWith(citySearching: false, citySuggestions: list),
          persist: false,
        ),
      );
    });
  }

  /// User tapped a prediction. Resolves it to coordinates (closing the billing
  /// session) and stores the structured geo.
  Future<void> selectCitySuggestion(PlaceSuggestion suggestion) async {
    final s = _s;
    if (s == null) return;
    _cityDebounce?.cancel();
    final token = s.citySessionToken ?? _uuid.v4();

    // Optimistically show the label and dismiss the dropdown.
    _set(s.copyWith(
      city: suggestion.fullText,
      citySuggestions: const [],
      citySearching: false,
    ));

    final result = await ref.read(locationRepositoryProvider).placeDetails(
          suggestion.placeId,
          sessionToken: token,
        );
    final cur = _s;
    if (cur == null) return;
    result.fold(
      (f) => _set(
        cur.copyWith(cityError: f.message, citySessionToken: null),
        persist: false,
      ),
      (place) => _set(cur.copyWith(
        city: place.label.isEmpty ? suggestion.fullText : place.label,
        placeId: place.placeId,
        lat: place.latitude,
        lng: place.longitude,
        countryCode: place.countryCode,
        citySessionToken: null, // session consumed
        cityError: null,
      )),
    );
  }

  /// "Use my location" — reads device GPS and reverse-geocodes it. The fallback
  /// that guarantees coordinates when autocomplete can't find the player's spot.
  Future<void> useMyLocation() async {
    final s = _s;
    if (s == null || s.locating) return;
    _cityDebounce?.cancel();
    _set(
      s.copyWith(locating: true, cityError: null, citySuggestions: const []),
      persist: false,
    );

    final locale = ui.PlatformDispatcher.instance.locale;
    final result = await ref.read(locationRepositoryProvider).currentLocation(
          languageCode:
              locale.languageCode.isEmpty ? null : locale.languageCode,
        );
    final cur = _s;
    if (cur == null) return;
    result.fold(
      (f) => _set(
        cur.copyWith(locating: false, cityError: f.message),
        persist: false,
      ),
      (place) => _set(cur.copyWith(
        locating: false,
        city: place.label,
        placeId: place.placeId,
        lat: place.latitude,
        lng: place.longitude,
        countryCode: place.countryCode,
        cityError: null,
      )),
    );
  }

  /// Cleans input to the allowed charset, validates format synchronously for
  /// instant feedback, then debounces the network availability check.
  void setUsername(String raw) {
    final s = _s;
    if (s == null) return;
    final cleaned =
        raw.toLowerCase().replaceAll(RegExp('[^a-z0-9_]'), '');

    if (cleaned.isEmpty) {
      _usernameDebounce?.cancel();
      _set(s.copyWith(
        username: '',
        usernameStatus: UsernameStatus.idle,
        usernameMessage: null,
      ));
      return;
    }

    Username.create(cleaned).fold(
      (failure) {
        _usernameDebounce?.cancel();
        _set(s.copyWith(
          username: cleaned,
          usernameStatus: UsernameStatus.invalid,
          usernameMessage: failure.message,
        ));
      },
      (_) {
        _set(s.copyWith(
          username: cleaned,
          usernameStatus: UsernameStatus.checking,
          usernameMessage: null,
        ));
        _scheduleAvailabilityCheck(cleaned);
      },
    );
  }

  void _scheduleAvailabilityCheck(String username) {
    _usernameDebounce?.cancel();
    _usernameDebounce = Timer(const Duration(milliseconds: 500), () async {
      // Re-validate format before hitting the network — caller already did,
      // but the contract is "valid Username → repo lookup".
      final usernameRes = Username.create(username);
      final result = await usernameRes.fold(
        (failure) async => Left<Failure, bool>(failure),
        (vo) async =>
            ref.read(profileRepositoryProvider).isUsernameAvailable(vo.value),
      );
      // Bail if the user kept typing while we were checking.
      final s = _s;
      if (s == null || s.username != username) return;

      result.fold(
        (failure) {
          if (failure is ValidationFailure) {
            _set(s.copyWith(
              usernameStatus: UsernameStatus.invalid,
              usernameMessage: failure.message,
            ), persist: false);
          } else {
            // Couldn't reach the backend — let the user retry by editing.
            _set(s.copyWith(
              usernameStatus: UsernameStatus.idle,
              usernameMessage: "Couldn't check — check your connection",
            ), persist: false);
          }
        },
        (available) => _set(s.copyWith(
          usernameStatus:
              available ? UsernameStatus.available : UsernameStatus.taken,
          usernameMessage: available ? null : 'That username is taken',
        ), persist: false),
      );
    });
  }

  /// Advance to the player step. Enforces the "every profile has coordinates"
  /// rule here (rather than gating the button): if the user typed a city
  /// without picking a suggestion or using GPS, resolve it permission-free by
  /// forward-geocoding the text. An unfindable place blocks with guidance.
  Future<void> continueToPlayer() async {
    final s = _s;
    if (s == null || !s.canContinueProfile || s.resolvingLocation) return;

    if (s.hasResolvedLocation) {
      _set(s.copyWith(step: OnboardingStep.player));
      return;
    }

    _set(s.copyWith(resolvingLocation: true, cityError: null), persist: false);
    final locale = ui.PlatformDispatcher.instance.locale;
    final result = await ref.read(locationRepositoryProvider).geocode(
          s.city,
          languageCode:
              locale.languageCode.isEmpty ? null : locale.languageCode,
          regionCode: locale.countryCode,
        );
    final cur = _s;
    if (cur == null) return;
    result.fold(
      (f) => _set(
        cur.copyWith(
          resolvingLocation: false,
          cityError: f is NotFoundFailure
              ? "We couldn't locate that place — pick a suggestion or use your current location"
              : f.message,
        ),
        persist: false,
      ),
      (place) => _set(cur.copyWith(
        resolvingLocation: false,
        city: place.label.isEmpty ? cur.city : place.label,
        placeId: place.placeId,
        lat: place.latitude,
        lng: place.longitude,
        countryCode: place.countryCode,
        step: OnboardingStep.player,
        cityError: null,
      )),
    );
  }

  // ─── Player step ──────────────────────────────────────────────────────────

  void setRole(PlayerRole role) =>
      _toggle((s) => s.copyWith(role: s.role == role ? null : role));
  void setBatting(BattingStyle b) => _toggle(
      (s) => s.copyWith(battingStyle: s.battingStyle == b ? null : b));
  void setBowling(BowlingStyle b) => _toggle(
      (s) => s.copyWith(bowlingStyle: s.bowlingStyle == b ? null : b));
  void setPreferredBall(BallType b) => _toggle(
      (s) => s.copyWith(preferredBall: s.preferredBall == b ? null : b));

  void _toggle(OnboardingState Function(OnboardingState) f) {
    final s = _s;
    if (s == null) return;
    _set(f(s));
  }

  void back() {
    final s = _s;
    if (s == null) return;
    if (s.step == OnboardingStep.player) {
      _set(s.copyWith(step: OnboardingStep.profile));
    }
  }

  /// Persist the profile to the backend. Called by both "Save profile"
  /// ([asPlayer] true) and "Skip — I just watch" ([asPlayer] false). On success
  /// advances to the welcome step (but does NOT yet open the gate — see
  /// [finish]).
  Future<void> submit({required bool asPlayer}) async {
    final s = _s;
    if (s == null || s.submitting) return;
    _set(s.copyWith(submitting: true, submitError: null, isPlayer: asPlayer),
        persist: false);

    // Validate inputs via value objects; the first failure short-circuits and
    // is surfaced as the submitError so the form can render it.
    final displayNameRes = DisplayName.create(s.displayName);
    final usernameRes = Username.create(s.username);
    final cityRes = City.create(s.city);
    Failure? failure;
    for (final e in <Either<Failure, Object>>[displayNameRes, usernameRes, cityRes]) {
      final f = e.getLeft().toNullable();
      if (f != null) {
        failure = f;
        break;
      }
    }
    if (failure != null) {
      final current = _s;
      if (current == null) return;
      _set(
        current.copyWith(submitting: false, submitError: failure.message),
        persist: false,
      );
      return;
    }

    final player = (s.playerProfile.hasAny && asPlayer) ? s.playerProfile : null;
    final result = await ref.read(profileRepositoryProvider).completeOnboarding(
          displayName: displayNameRes.getRight().toNullable()!,
          username: usernameRes.getRight().toNullable()!,
          city: cityRes.getRight().toNullable()!,
          placeId: s.placeId,
          latitude: s.lat,
          longitude: s.lng,
          countryCode: s.countryCode,
          playerProfile: player,
        );

    final current = _s;
    if (current == null) return;
    result.fold(
      (failure) => _set(
        current.copyWith(submitting: false, submitError: failure.message),
        persist: false,
      ),
      (_) => _set(
        current.copyWith(submitting: false, step: OnboardingStep.welcome),
        persist: false,
      ),
    );
  }

  // ─── Welcome step ───────────────────────────────────────────────────────────

  /// Tapped "Open feed". Clears the draft and invalidates the onboarding-status
  /// provider so the router gate now lets the user into /home, then flips
  /// [OnboardingState.completed] for the screen to navigate on.
  Future<void> finish() async {
    final s = _s;
    if (s == null) return;
    await ref.read(wizardDraftStoreProvider).clear(_draftKey);
    ref.invalidate(onboardingStatusProvider);
    _set(s.copyWith(completed: true), persist: false);
  }

  // ─── Draft (de)serialization ──────────────────────────────────────────────

  void _persistDraft(OnboardingState s) {
    // Fire-and-forget; the store swallows failures.
    ref.read(wizardDraftStoreProvider).save(_draftKey, _toDraft(s));
  }

  Map<String, dynamic> _toDraft(OnboardingState s) => {
        'step': s.step.name,
        'displayName': s.displayName,
        'username': s.username,
        'city': s.city,
        'placeId': s.placeId,
        'lat': s.lat,
        'lng': s.lng,
        'countryCode': s.countryCode,
        'isPlayer': s.isPlayer,
        'role': s.role?.wire,
        'battingStyle': s.battingStyle?.wire,
        'bowlingStyle': s.bowlingStyle?.wire,
        'preferredBall': s.preferredBall?.wire,
      };

  OnboardingState _fromDraft(Map<String, dynamic> m) => OnboardingState(
        step: OnboardingStep.values.firstWhere(
          (e) => e.name == m['step'],
          orElse: () => OnboardingStep.profile,
        ),
        displayName: m['displayName'] as String? ?? '',
        username: m['username'] as String? ?? '',
        city: m['city'] as String? ?? '',
        placeId: m['placeId'] as String?,
        lat: (m['lat'] as num?)?.toDouble(),
        lng: (m['lng'] as num?)?.toDouble(),
        countryCode: m['countryCode'] as String?,
        isPlayer: m['isPlayer'] as bool? ?? false,
        role: PlayerRole.fromWire(m['role'] as String?),
        battingStyle: BattingStyle.fromWire(m['battingStyle'] as String?),
        bowlingStyle: BowlingStyle.fromWire(m['bowlingStyle'] as String?),
        preferredBall: BallType.fromWire(m['preferredBall'] as String?),
      );
}
