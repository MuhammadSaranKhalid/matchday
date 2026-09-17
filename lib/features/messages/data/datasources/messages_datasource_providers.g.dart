// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'messages_datasource_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(chatLocalDataSource)
final chatLocalDataSourceProvider = ChatLocalDataSourceProvider._();

final class ChatLocalDataSourceProvider
    extends
        $FunctionalProvider<
          ChatLocalDataSource,
          ChatLocalDataSource,
          ChatLocalDataSource
        >
    with $Provider<ChatLocalDataSource> {
  ChatLocalDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatLocalDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatLocalDataSourceHash();

  @$internal
  @override
  $ProviderElement<ChatLocalDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ChatLocalDataSource create(Ref ref) {
    return chatLocalDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatLocalDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatLocalDataSource>(value),
    );
  }
}

String _$chatLocalDataSourceHash() =>
    r'd5d7518b8c22311f9e5ef052798bfcf3de5175f2';

@ProviderFor(chatRemoteDataSource)
final chatRemoteDataSourceProvider = ChatRemoteDataSourceProvider._();

final class ChatRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          ChatRemoteDataSource,
          ChatRemoteDataSource,
          ChatRemoteDataSource
        >
    with $Provider<ChatRemoteDataSource> {
  ChatRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatRemoteDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<ChatRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ChatRemoteDataSource create(Ref ref) {
    return chatRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatRemoteDataSource>(value),
    );
  }
}

String _$chatRemoteDataSourceHash() =>
    r'3d1ca931d01fc053654b2828db7ecb0c3af23186';

@ProviderFor(outboxProcessor)
final outboxProcessorProvider = OutboxProcessorProvider._();

final class OutboxProcessorProvider
    extends
        $FunctionalProvider<OutboxProcessor, OutboxProcessor, OutboxProcessor>
    with $Provider<OutboxProcessor> {
  OutboxProcessorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'outboxProcessorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$outboxProcessorHash();

  @$internal
  @override
  $ProviderElement<OutboxProcessor> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  OutboxProcessor create(Ref ref) {
    return outboxProcessor(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OutboxProcessor value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OutboxProcessor>(value),
    );
  }
}

String _$outboxProcessorHash() => r'4595bfee96b98685f010a7c4f764fd88ffa0aa42';

@ProviderFor(receiptCoordinator)
final receiptCoordinatorProvider = ReceiptCoordinatorProvider._();

final class ReceiptCoordinatorProvider
    extends
        $FunctionalProvider<
          ReceiptCoordinator,
          ReceiptCoordinator,
          ReceiptCoordinator
        >
    with $Provider<ReceiptCoordinator> {
  ReceiptCoordinatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'receiptCoordinatorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$receiptCoordinatorHash();

  @$internal
  @override
  $ProviderElement<ReceiptCoordinator> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReceiptCoordinator create(Ref ref) {
    return receiptCoordinator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReceiptCoordinator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReceiptCoordinator>(value),
    );
  }
}

String _$receiptCoordinatorHash() =>
    r'f7bec5c5bcba1986c6cf2591a6e7adcdd7d5b1a9';

@ProviderFor(realtimeIngestor)
final realtimeIngestorProvider = RealtimeIngestorProvider._();

final class RealtimeIngestorProvider
    extends
        $FunctionalProvider<
          RealtimeIngestor,
          RealtimeIngestor,
          RealtimeIngestor
        >
    with $Provider<RealtimeIngestor> {
  RealtimeIngestorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'realtimeIngestorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$realtimeIngestorHash();

  @$internal
  @override
  $ProviderElement<RealtimeIngestor> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RealtimeIngestor create(Ref ref) {
    return realtimeIngestor(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RealtimeIngestor value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RealtimeIngestor>(value),
    );
  }
}

String _$realtimeIngestorHash() => r'923ee95034e5283a79eb81f63b581226099a1bab';

@ProviderFor(catchUpScheduler)
final catchUpSchedulerProvider = CatchUpSchedulerProvider._();

final class CatchUpSchedulerProvider
    extends
        $FunctionalProvider<
          CatchUpScheduler,
          CatchUpScheduler,
          CatchUpScheduler
        >
    with $Provider<CatchUpScheduler> {
  CatchUpSchedulerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'catchUpSchedulerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$catchUpSchedulerHash();

  @$internal
  @override
  $ProviderElement<CatchUpScheduler> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CatchUpScheduler create(Ref ref) {
    return catchUpScheduler(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CatchUpScheduler value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CatchUpScheduler>(value),
    );
  }
}

String _$catchUpSchedulerHash() => r'1c091971771411874ce8610d4d7bed6416154412';

@ProviderFor(chatSyncCoordinator)
final chatSyncCoordinatorProvider = ChatSyncCoordinatorProvider._();

final class ChatSyncCoordinatorProvider
    extends
        $FunctionalProvider<
          ChatSyncCoordinator,
          ChatSyncCoordinator,
          ChatSyncCoordinator
        >
    with $Provider<ChatSyncCoordinator> {
  ChatSyncCoordinatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatSyncCoordinatorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatSyncCoordinatorHash();

  @$internal
  @override
  $ProviderElement<ChatSyncCoordinator> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ChatSyncCoordinator create(Ref ref) {
    return chatSyncCoordinator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatSyncCoordinator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatSyncCoordinator>(value),
    );
  }
}

String _$chatSyncCoordinatorHash() =>
    r'2c80355f27a731695cb759ce69d98d018385b47f';
