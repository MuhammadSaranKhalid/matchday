// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pavilion_match_detail_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(pavilionMatchDetail)
final pavilionMatchDetailProvider = PavilionMatchDetailFamily._();

final class PavilionMatchDetailProvider
    extends
        $FunctionalProvider<AsyncValue<PvMatch?>, PvMatch?, FutureOr<PvMatch?>>
    with $FutureModifier<PvMatch?>, $FutureProvider<PvMatch?> {
  PavilionMatchDetailProvider._({
    required PavilionMatchDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'pavilionMatchDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pavilionMatchDetailHash();

  @override
  String toString() {
    return r'pavilionMatchDetailProvider'
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
    return pavilionMatchDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PavilionMatchDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pavilionMatchDetailHash() =>
    r'db4e02cbedfe212720e90100af6b112fcb34ed6d';

final class PavilionMatchDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<PvMatch?>, String> {
  PavilionMatchDetailFamily._()
    : super(
        retry: null,
        name: r'pavilionMatchDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PavilionMatchDetailProvider call(String matchId) =>
      PavilionMatchDetailProvider._(argument: matchId, from: this);

  @override
  String toString() => r'pavilionMatchDetailProvider';
}
