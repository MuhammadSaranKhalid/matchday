// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_room_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MatchRoomController)
final matchRoomControllerProvider = MatchRoomControllerFamily._();

final class MatchRoomControllerProvider
    extends $AsyncNotifierProvider<MatchRoomController, MatchRoomState> {
  MatchRoomControllerProvider._({
    required MatchRoomControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'matchRoomControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$matchRoomControllerHash();

  @override
  String toString() {
    return r'matchRoomControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  MatchRoomController create() => MatchRoomController();

  @override
  bool operator ==(Object other) {
    return other is MatchRoomControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$matchRoomControllerHash() =>
    r'b1d335fba76022cde50a3500e8ca1fc6e7f37e26';

final class MatchRoomControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          MatchRoomController,
          AsyncValue<MatchRoomState>,
          MatchRoomState,
          FutureOr<MatchRoomState>,
          String
        > {
  MatchRoomControllerFamily._()
    : super(
        retry: null,
        name: r'matchRoomControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  MatchRoomControllerProvider call(String matchId) =>
      MatchRoomControllerProvider._(argument: matchId, from: this);

  @override
  String toString() => r'matchRoomControllerProvider';
}

abstract class _$MatchRoomController extends $AsyncNotifier<MatchRoomState> {
  late final _$args = ref.$arg as String;
  String get matchId => _$args;

  FutureOr<MatchRoomState> build(String matchId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<MatchRoomState>, MatchRoomState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<MatchRoomState>, MatchRoomState>,
              AsyncValue<MatchRoomState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
