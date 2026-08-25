// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_detail_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(matchDetail)
final matchDetailProvider = MatchDetailFamily._();

final class MatchDetailProvider
    extends
        $FunctionalProvider<AsyncValue<PvMatch?>, PvMatch?, FutureOr<PvMatch?>>
    with $FutureModifier<PvMatch?>, $FutureProvider<PvMatch?> {
  MatchDetailProvider._({
    required MatchDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'matchDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$matchDetailHash();

  @override
  String toString() {
    return r'matchDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<PvMatch?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<PvMatch?> create(Ref ref) {
    final argument = this.argument as String;
    return matchDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MatchDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$matchDetailHash() => r'57f36b498f8ac4d074537e581aac60baf3278f0d';

final class MatchDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<PvMatch?>, String> {
  MatchDetailFamily._()
    : super(
        retry: null,
        name: r'matchDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  MatchDetailProvider call(String matchId) =>
      MatchDetailProvider._(argument: matchId, from: this);

  @override
  String toString() => r'matchDetailProvider';
}
