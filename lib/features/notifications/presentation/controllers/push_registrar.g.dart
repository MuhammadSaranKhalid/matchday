// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'push_registrar.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Drives the FCM token lifecycle + notification-tap deep links for the
/// signed-in user. Activated once (app.dart watches it); keepAlive for the
/// session.
///
/// - On sign-in (or app start while already signed in): request permission →
///   fetch the FCM token → register it via the notifications repository.
/// - On token rotation: re-register.
/// - On a notification tap: deep-link via the router.
/// - On sign-out: [unregister] is invoked from the auth controller *before* the
///   session ends, because the RLS delete on `device_tokens` needs
///   `auth.uid()`.

@ProviderFor(PushRegistrar)
final pushRegistrarProvider = PushRegistrarProvider._();

/// Drives the FCM token lifecycle + notification-tap deep links for the
/// signed-in user. Activated once (app.dart watches it); keepAlive for the
/// session.
///
/// - On sign-in (or app start while already signed in): request permission →
///   fetch the FCM token → register it via the notifications repository.
/// - On token rotation: re-register.
/// - On a notification tap: deep-link via the router.
/// - On sign-out: [unregister] is invoked from the auth controller *before* the
///   session ends, because the RLS delete on `device_tokens` needs
///   `auth.uid()`.
final class PushRegistrarProvider
    extends $NotifierProvider<PushRegistrar, void> {
  /// Drives the FCM token lifecycle + notification-tap deep links for the
  /// signed-in user. Activated once (app.dart watches it); keepAlive for the
  /// session.
  ///
  /// - On sign-in (or app start while already signed in): request permission →
  ///   fetch the FCM token → register it via the notifications repository.
  /// - On token rotation: re-register.
  /// - On a notification tap: deep-link via the router.
  /// - On sign-out: [unregister] is invoked from the auth controller *before* the
  ///   session ends, because the RLS delete on `device_tokens` needs
  ///   `auth.uid()`.
  PushRegistrarProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pushRegistrarProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pushRegistrarHash();

  @$internal
  @override
  PushRegistrar create() => PushRegistrar();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$pushRegistrarHash() => r'9f4ce05a8827b325486b74a019c9301e811949ff';

/// Drives the FCM token lifecycle + notification-tap deep links for the
/// signed-in user. Activated once (app.dart watches it); keepAlive for the
/// session.
///
/// - On sign-in (or app start while already signed in): request permission →
///   fetch the FCM token → register it via the notifications repository.
/// - On token rotation: re-register.
/// - On a notification tap: deep-link via the router.
/// - On sign-out: [unregister] is invoked from the auth controller *before* the
///   session ends, because the RLS delete on `device_tokens` needs
///   `auth.uid()`.

abstract class _$PushRegistrar extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
