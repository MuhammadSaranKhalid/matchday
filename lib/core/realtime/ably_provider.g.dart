// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ably_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the singleton [AblyService] across the application.
///
/// Watches [currentUserIdProvider] so the service is torn down and rebuilt
/// whenever the signed-in user changes (sign-out → sign-in, or account
/// switch). This ensures the Ably [clientId] always matches the current
/// Supabase identity and prevents a stale clientId/JWT mismatch.

@ProviderFor(ablyService)
final ablyServiceProvider = AblyServiceProvider._();

/// Provides the singleton [AblyService] across the application.
///
/// Watches [currentUserIdProvider] so the service is torn down and rebuilt
/// whenever the signed-in user changes (sign-out → sign-in, or account
/// switch). This ensures the Ably [clientId] always matches the current
/// Supabase identity and prevents a stale clientId/JWT mismatch.

final class AblyServiceProvider
    extends $FunctionalProvider<AblyService, AblyService, AblyService>
    with $Provider<AblyService> {
  /// Provides the singleton [AblyService] across the application.
  ///
  /// Watches [currentUserIdProvider] so the service is torn down and rebuilt
  /// whenever the signed-in user changes (sign-out → sign-in, or account
  /// switch). This ensures the Ably [clientId] always matches the current
  /// Supabase identity and prevents a stale clientId/JWT mismatch.
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

String _$ablyServiceHash() => r'c62787e32fca233ba4d310dbdcd10df93886d4a2';
