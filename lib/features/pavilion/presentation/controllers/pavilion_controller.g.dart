// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pavilion_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Action coordinator for the Pavilion v2 workspace.
///
/// Pavilion is a presentation-only aggregation feature (CLAUDE.md §6.6) — it
/// owns no domain/data layer. This controller hosts the few cross-feature
/// write actions the workspace dispatches (currently: withdrawing an outbound
/// match challenge) so the screen stays a pure renderer. View state
/// (segment, open match, toast) remains in the screen — it's local to one
/// route and not worth promoting.
///
/// Actions return `Either<Failure, T>` so the screen can show per-action
/// snackbars without polluting controller state.

@ProviderFor(PavilionController)
final pavilionControllerProvider = PavilionControllerProvider._();

/// Action coordinator for the Pavilion v2 workspace.
///
/// Pavilion is a presentation-only aggregation feature (CLAUDE.md §6.6) — it
/// owns no domain/data layer. This controller hosts the few cross-feature
/// write actions the workspace dispatches (currently: withdrawing an outbound
/// match challenge) so the screen stays a pure renderer. View state
/// (segment, open match, toast) remains in the screen — it's local to one
/// route and not worth promoting.
///
/// Actions return `Either<Failure, T>` so the screen can show per-action
/// snackbars without polluting controller state.
final class PavilionControllerProvider
    extends $NotifierProvider<PavilionController, void> {
  /// Action coordinator for the Pavilion v2 workspace.
  ///
  /// Pavilion is a presentation-only aggregation feature (CLAUDE.md §6.6) — it
  /// owns no domain/data layer. This controller hosts the few cross-feature
  /// write actions the workspace dispatches (currently: withdrawing an outbound
  /// match challenge) so the screen stays a pure renderer. View state
  /// (segment, open match, toast) remains in the screen — it's local to one
  /// route and not worth promoting.
  ///
  /// Actions return `Either<Failure, T>` so the screen can show per-action
  /// snackbars without polluting controller state.
  PavilionControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pavilionControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pavilionControllerHash();

  @$internal
  @override
  PavilionController create() => PavilionController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$pavilionControllerHash() =>
    r'fd20b05e6ce6929ee385e8dba0cb877e171c8abb';

/// Action coordinator for the Pavilion v2 workspace.
///
/// Pavilion is a presentation-only aggregation feature (CLAUDE.md §6.6) — it
/// owns no domain/data layer. This controller hosts the few cross-feature
/// write actions the workspace dispatches (currently: withdrawing an outbound
/// match challenge) so the screen stays a pure renderer. View state
/// (segment, open match, toast) remains in the screen — it's local to one
/// route and not worth promoting.
///
/// Actions return `Either<Failure, T>` so the screen can show per-action
/// snackbars without polluting controller state.

abstract class _$PavilionController extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
