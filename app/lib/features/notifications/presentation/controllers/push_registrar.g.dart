// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'push_registrar.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Application-scoped FCM token lifecycle + notification navigation.
///
/// Activated once from app.dart and kept alive for the session.
///
/// Responsibilities:
/// - initialize foreground notification presentation
/// - register the signed-in user's FCM token
/// - re-register token rotations
/// - route foreground/background/cold-start notification taps
/// - revoke the device token before sign-out
///
/// This controller intentionally does NOT decide whether a particular chat
/// notification should be suppressed. That visibility policy belongs to
/// PushMessagingService + MessageThreadScreen.

@ProviderFor(PushRegistrar)
final pushRegistrarProvider = PushRegistrarProvider._();

/// Application-scoped FCM token lifecycle + notification navigation.
///
/// Activated once from app.dart and kept alive for the session.
///
/// Responsibilities:
/// - initialize foreground notification presentation
/// - register the signed-in user's FCM token
/// - re-register token rotations
/// - route foreground/background/cold-start notification taps
/// - revoke the device token before sign-out
///
/// This controller intentionally does NOT decide whether a particular chat
/// notification should be suppressed. That visibility policy belongs to
/// PushMessagingService + MessageThreadScreen.
final class PushRegistrarProvider
    extends $NotifierProvider<PushRegistrar, void> {
  /// Application-scoped FCM token lifecycle + notification navigation.
  ///
  /// Activated once from app.dart and kept alive for the session.
  ///
  /// Responsibilities:
  /// - initialize foreground notification presentation
  /// - register the signed-in user's FCM token
  /// - re-register token rotations
  /// - route foreground/background/cold-start notification taps
  /// - revoke the device token before sign-out
  ///
  /// This controller intentionally does NOT decide whether a particular chat
  /// notification should be suppressed. That visibility policy belongs to
  /// PushMessagingService + MessageThreadScreen.
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

String _$pushRegistrarHash() => r'8303f495d8c4800bdcd0760a60f9a4e845b8dc4c';

/// Application-scoped FCM token lifecycle + notification navigation.
///
/// Activated once from app.dart and kept alive for the session.
///
/// Responsibilities:
/// - initialize foreground notification presentation
/// - register the signed-in user's FCM token
/// - re-register token rotations
/// - route foreground/background/cold-start notification taps
/// - revoke the device token before sign-out
///
/// This controller intentionally does NOT decide whether a particular chat
/// notification should be suppressed. That visibility policy belongs to
/// PushMessagingService + MessageThreadScreen.

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
