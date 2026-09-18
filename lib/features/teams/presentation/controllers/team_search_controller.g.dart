// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_search_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(TeamSearchController)
final teamSearchControllerProvider = TeamSearchControllerProvider._();

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
final class TeamSearchControllerProvider
    extends $NotifierProvider<TeamSearchController, TeamSearchState> {
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
  TeamSearchControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'teamSearchControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$teamSearchControllerHash();

  @$internal
  @override
  TeamSearchController create() => TeamSearchController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TeamSearchState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TeamSearchState>(value),
    );
  }
}

String _$teamSearchControllerHash() =>
    r'6b8acc5e337649d1c0b4e411650d4f024da1d075';

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

abstract class _$TeamSearchController extends $Notifier<TeamSearchState> {
  TeamSearchState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<TeamSearchState, TeamSearchState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TeamSearchState, TeamSearchState>,
              TeamSearchState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
