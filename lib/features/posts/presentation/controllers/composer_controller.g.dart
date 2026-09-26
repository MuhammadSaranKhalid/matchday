// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'composer_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Composer draft state: staged (cropped+resized) photos + submit lifecycle.
/// The text is owned by the screen's TextEditingController and passed to submit.

@ProviderFor(ComposerController)
final composerControllerProvider = ComposerControllerProvider._();

/// Composer draft state: staged (cropped+resized) photos + submit lifecycle.
/// The text is owned by the screen's TextEditingController and passed to submit.
final class ComposerControllerProvider
    extends $NotifierProvider<ComposerController, ComposerState> {
  /// Composer draft state: staged (cropped+resized) photos + submit lifecycle.
  /// The text is owned by the screen's TextEditingController and passed to submit.
  ComposerControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'composerControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$composerControllerHash();

  @$internal
  @override
  ComposerController create() => ComposerController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ComposerState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ComposerState>(value),
    );
  }
}

String _$composerControllerHash() =>
    r'be8f38c0488a36eb9c269cda2fe965ebf6c98b36';

/// Composer draft state: staged (cropped+resized) photos + submit lifecycle.
/// The text is owned by the screen's TextEditingController and passed to submit.

abstract class _$ComposerController extends $Notifier<ComposerState> {
  ComposerState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ComposerState, ComposerState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ComposerState, ComposerState>,
              ComposerState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
