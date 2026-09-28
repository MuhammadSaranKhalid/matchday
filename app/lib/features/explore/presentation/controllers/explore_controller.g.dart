// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'explore_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(ExploreController)
final exploreControllerProvider = ExploreControllerProvider._();

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
final class ExploreControllerProvider
    extends $NotifierProvider<ExploreController, ExploreState> {
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
  ExploreControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exploreControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exploreControllerHash();

  @$internal
  @override
  ExploreController create() => ExploreController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExploreState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExploreState>(value),
    );
  }
}

String _$exploreControllerHash() => r'3a6bef5375cb4d8071be868623d87dbcb04bf306';

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

abstract class _$ExploreController extends $Notifier<ExploreState> {
  ExploreState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ExploreState, ExploreState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ExploreState, ExploreState>,
              ExploreState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
