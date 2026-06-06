// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'push_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App-lifetime FCM wrapper. keepAlive — one instance for the whole session.

@ProviderFor(pushMessagingService)
final pushMessagingServiceProvider = PushMessagingServiceProvider._();

/// App-lifetime FCM wrapper. keepAlive — one instance for the whole session.

final class PushMessagingServiceProvider
    extends
        $FunctionalProvider<
          PushMessagingService,
          PushMessagingService,
          PushMessagingService
        >
    with $Provider<PushMessagingService> {
  /// App-lifetime FCM wrapper. keepAlive — one instance for the whole session.
  PushMessagingServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pushMessagingServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pushMessagingServiceHash();

  @$internal
  @override
  $ProviderElement<PushMessagingService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PushMessagingService create(Ref ref) {
    return pushMessagingService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PushMessagingService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PushMessagingService>(value),
    );
  }
}

String _$pushMessagingServiceHash() =>
    r'de1e3b02e9a4845a20ecdde96b195c51a6fd864b';
