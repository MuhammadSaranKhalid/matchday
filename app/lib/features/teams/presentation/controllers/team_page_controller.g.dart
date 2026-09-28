// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_page_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TeamPageController)
final teamPageControllerProvider = TeamPageControllerFamily._();

final class TeamPageControllerProvider
    extends $AsyncNotifierProvider<TeamPageController, TeamPageState?> {
  TeamPageControllerProvider._({
    required TeamPageControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'teamPageControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$teamPageControllerHash();

  @override
  String toString() {
    return r'teamPageControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  TeamPageController create() => TeamPageController();

  @override
  bool operator ==(Object other) {
    return other is TeamPageControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$teamPageControllerHash() =>
    r'24bc32a3417fa9257029fa523a7bcd47b784a706';

final class TeamPageControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          TeamPageController,
          AsyncValue<TeamPageState?>,
          TeamPageState?,
          FutureOr<TeamPageState?>,
          String
        > {
  TeamPageControllerFamily._()
    : super(
        retry: null,
        name: r'teamPageControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TeamPageControllerProvider call(String teamId) =>
      TeamPageControllerProvider._(argument: teamId, from: this);

  @override
  String toString() => r'teamPageControllerProvider';
}

abstract class _$TeamPageController extends $AsyncNotifier<TeamPageState?> {
  late final _$args = ref.$arg as String;
  String get teamId => _$args;

  FutureOr<TeamPageState?> build(String teamId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<TeamPageState?>, TeamPageState?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<TeamPageState?>, TeamPageState?>,
              AsyncValue<TeamPageState?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
