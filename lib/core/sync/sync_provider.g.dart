// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Owns the SyncService and wires it to connectivity.
///
/// Triggers a sync when:
///  - The service is first created (app startup, if online)
///  - Connectivity flips from offline → online
///
/// The repository also calls service.sync() after every local mutation
/// so writes propagate immediately when online.

@ProviderFor(syncService)
final syncServiceProvider = SyncServiceProvider._();

/// Owns the SyncService and wires it to connectivity.
///
/// Triggers a sync when:
///  - The service is first created (app startup, if online)
///  - Connectivity flips from offline → online
///
/// The repository also calls service.sync() after every local mutation
/// so writes propagate immediately when online.

final class SyncServiceProvider
    extends $FunctionalProvider<SyncService, SyncService, SyncService>
    with $Provider<SyncService> {
  /// Owns the SyncService and wires it to connectivity.
  ///
  /// Triggers a sync when:
  ///  - The service is first created (app startup, if online)
  ///  - Connectivity flips from offline → online
  ///
  /// The repository also calls service.sync() after every local mutation
  /// so writes propagate immediately when online.
  SyncServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncServiceHash();

  @$internal
  @override
  $ProviderElement<SyncService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SyncService create(Ref ref) {
    return syncService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncService>(value),
    );
  }
}

String _$syncServiceHash() => r'2e8600d556cb9dec326fcf2aae7f2fb0687bd00a';
