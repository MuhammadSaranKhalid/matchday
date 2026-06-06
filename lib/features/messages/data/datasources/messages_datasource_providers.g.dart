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
    r'bb84813b5fc6d0f733796bd7a6de1dcc0b0439ab';
