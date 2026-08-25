// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_detail_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MatchDetailController)
final matchDetailControllerProvider = MatchDetailControllerProvider._();

final class MatchDetailControllerProvider
    extends $NotifierProvider<MatchDetailController, void> {
  MatchDetailControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'matchDetailControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$matchDetailControllerHash();

  @$internal
  @override
  MatchDetailController create() => MatchDetailController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$matchDetailControllerHash() =>
    r'461fff2b8adb45bd582061ce75421365ca64e42d';

abstract class _$MatchDetailController extends $Notifier<void> {
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
