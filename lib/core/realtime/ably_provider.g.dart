// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ably_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the singleton [AblyService] across the application.

@ProviderFor(ablyService)
final ablyServiceProvider = AblyServiceProvider._();

/// Provides the singleton [AblyService] across the application.

final class AblyServiceProvider
    extends $FunctionalProvider<AblyService, AblyService, AblyService>
    with $Provider<AblyService> {
  /// Provides the singleton [AblyService] across the application.
  AblyServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ablyServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ablyServiceHash();

  @$internal
  @override
  $ProviderElement<AblyService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AblyService create(Ref ref) {
    return ablyService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AblyService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AblyService>(value),
    );
  }
}

String _$ablyServiceHash() => r'e61defabd190ae3bce521124174c41adb15be4f5';
