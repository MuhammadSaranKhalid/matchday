// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tournaments_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TournamentsController)
final tournamentsControllerProvider = TournamentsControllerProvider._();

final class TournamentsControllerProvider
    extends $AsyncNotifierProvider<TournamentsController, void> {
  TournamentsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tournamentsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tournamentsControllerHash();

  @$internal
  @override
  TournamentsController create() => TournamentsController();
}

String _$tournamentsControllerHash() =>
    r'2a351f929a2a2befe07fdc34d080c2b5449e5840';

abstract class _$TournamentsController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
