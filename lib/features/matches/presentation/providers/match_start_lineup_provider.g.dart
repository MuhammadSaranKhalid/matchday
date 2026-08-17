// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_start_lineup_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(matchStartLineup)
final matchStartLineupProvider = MatchStartLineupFamily._();

final class MatchStartLineupProvider
    extends
        $FunctionalProvider<
          AsyncValue<MatchStartLineupState>,
          MatchStartLineupState,
          FutureOr<MatchStartLineupState>
        >
    with
        $FutureModifier<MatchStartLineupState>,
        $FutureProvider<MatchStartLineupState> {
  MatchStartLineupProvider._({
    required MatchStartLineupFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'matchStartLineupProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$matchStartLineupHash();

  @override
  String toString() {
    return r'matchStartLineupProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<MatchStartLineupState> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<MatchStartLineupState> create(Ref ref) {
    final argument = this.argument as String;
    return matchStartLineup(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MatchStartLineupProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$matchStartLineupHash() => r'29146fd2b341bebd4dc04ecec5ae26fcb023ee58';

final class MatchStartLineupFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<MatchStartLineupState>, String> {
  MatchStartLineupFamily._()
    : super(
        retry: null,
        name: r'matchStartLineupProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  MatchStartLineupProvider call(String matchId) =>
      MatchStartLineupProvider._(argument: matchId, from: this);

  @override
  String toString() => r'matchStartLineupProvider';
}
