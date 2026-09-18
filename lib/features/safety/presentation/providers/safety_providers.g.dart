// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'safety_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(safetyRepository)
final safetyRepositoryProvider = SafetyRepositoryProvider._();

final class SafetyRepositoryProvider
    extends
        $FunctionalProvider<
          SafetyRepository,
          SafetyRepository,
          SafetyRepository
        >
    with $Provider<SafetyRepository> {
  SafetyRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'safetyRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$safetyRepositoryHash();

  @$internal
  @override
  $ProviderElement<SafetyRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SafetyRepository create(Ref ref) {
    return safetyRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SafetyRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SafetyRepository>(value),
    );
  }
}

String _$safetyRepositoryHash() => r'0b98e11517b8d1066ed9b46a1a261b4f71646da5';

@ProviderFor(blockedAccounts)
final blockedAccountsProvider = BlockedAccountsProvider._();

final class BlockedAccountsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<BlockedAccount>>,
          List<BlockedAccount>,
          FutureOr<List<BlockedAccount>>
        >
    with
        $FutureModifier<List<BlockedAccount>>,
        $FutureProvider<List<BlockedAccount>> {
  BlockedAccountsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'blockedAccountsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$blockedAccountsHash();

  @$internal
  @override
  $FutureProviderElement<List<BlockedAccount>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<BlockedAccount>> create(Ref ref) {
    return blockedAccounts(ref);
  }
}

String _$blockedAccountsHash() => r'2722cfc0372b81ef2579606386194120d2090fea';
