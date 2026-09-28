// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_manage_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TeamManageController)
final teamManageControllerProvider = TeamManageControllerProvider._();

final class TeamManageControllerProvider
    extends $NotifierProvider<TeamManageController, AsyncValue<void>> {
  TeamManageControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'teamManageControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$teamManageControllerHash();

  @$internal
  @override
  TeamManageController create() => TeamManageController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$teamManageControllerHash() =>
    r'1e34bd5f26d875b893cbaeb100f13a94e8b69bb3';

abstract class _$TeamManageController extends $Notifier<AsyncValue<void>> {
  AsyncValue<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, AsyncValue<void>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, AsyncValue<void>>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
