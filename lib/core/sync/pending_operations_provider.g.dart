// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_operations_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Shared across all offline features (the queue is feature-agnostic).

@ProviderFor(pendingOperationsDataSource)
final pendingOperationsDataSourceProvider =
    PendingOperationsDataSourceProvider._();

/// Shared across all offline features (the queue is feature-agnostic).

final class PendingOperationsDataSourceProvider
    extends
        $FunctionalProvider<
          PendingOperationsDataSource,
          PendingOperationsDataSource,
          PendingOperationsDataSource
        >
    with $Provider<PendingOperationsDataSource> {
  /// Shared across all offline features (the queue is feature-agnostic).
  PendingOperationsDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingOperationsDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingOperationsDataSourceHash();

  @$internal
  @override
  $ProviderElement<PendingOperationsDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PendingOperationsDataSource create(Ref ref) {
    return pendingOperationsDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PendingOperationsDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PendingOperationsDataSource>(value),
    );
  }
}

String _$pendingOperationsDataSourceHash() =>
    r'dbfba8b2c80dc58d4c344d2a9dda8876441b79fd';
