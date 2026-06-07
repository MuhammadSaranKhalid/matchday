// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'messages_datasource_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(messagesRemoteDataSource)
final messagesRemoteDataSourceProvider = MessagesRemoteDataSourceProvider._();

final class MessagesRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          MessagesRemoteDataSource,
          MessagesRemoteDataSource,
          MessagesRemoteDataSource
        >
    with $Provider<MessagesRemoteDataSource> {
  MessagesRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'messagesRemoteDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$messagesRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<MessagesRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MessagesRemoteDataSource create(Ref ref) {
    return messagesRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MessagesRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MessagesRemoteDataSource>(value),
    );
  }
}

String _$messagesRemoteDataSourceHash() =>
    r'1083a5437bce7ffaccd5928dd30dee1acd88d550';

@ProviderFor(messagesLocalDataSource)
final messagesLocalDataSourceProvider = MessagesLocalDataSourceProvider._();

final class MessagesLocalDataSourceProvider
    extends
        $FunctionalProvider<
          MessagesLocalDataSource,
          MessagesLocalDataSource,
          MessagesLocalDataSource
        >
    with $Provider<MessagesLocalDataSource> {
  MessagesLocalDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'messagesLocalDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$messagesLocalDataSourceHash();

  @$internal
  @override
  $ProviderElement<MessagesLocalDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MessagesLocalDataSource create(Ref ref) {
    return messagesLocalDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MessagesLocalDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MessagesLocalDataSource>(value),
    );
  }
}

String _$messagesLocalDataSourceHash() =>
    r'00dd2c66aa07cf3a11eadfd525ba0a82012bf968';
