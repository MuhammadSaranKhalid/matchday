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

String _$realtimeIngestorHash() => r'75d7c774f92ae64209aff514ed062a70283372fa';

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
    r'e78370fe450e456a2d46f0b8f6a16330804281c5';
