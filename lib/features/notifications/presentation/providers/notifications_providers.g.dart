// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notifications_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(notificationsRepository)
final notificationsRepositoryProvider = NotificationsRepositoryProvider._();

final class NotificationsRepositoryProvider
    extends
        $FunctionalProvider<
          NotificationsRepository,
          NotificationsRepository,
          NotificationsRepository
        >
    with $Provider<NotificationsRepository> {
  NotificationsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationsRepositoryHash();

  @$internal
  @override
  $ProviderElement<NotificationsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NotificationsRepository create(Ref ref) {
    return notificationsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotificationsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotificationsRepository>(value),
    );
  }
}

String _$notificationsRepositoryHash() =>
    r'13fdea11b4df5e9dd45ce153d1fbb27dc9008776';

@ProviderFor(watchNotificationsUseCase)
final watchNotificationsUseCaseProvider = WatchNotificationsUseCaseProvider._();

final class WatchNotificationsUseCaseProvider
    extends
        $FunctionalProvider<
          WatchNotifications,
          WatchNotifications,
          WatchNotifications
        >
    with $Provider<WatchNotifications> {
  WatchNotificationsUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'watchNotificationsUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$watchNotificationsUseCaseHash();

  @$internal
  @override
  $ProviderElement<WatchNotifications> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WatchNotifications create(Ref ref) {
    return watchNotificationsUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WatchNotifications value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WatchNotifications>(value),
    );
  }
}

String _$watchNotificationsUseCaseHash() =>
    r'8f1241d53184ea1809fc894a383ef62b7210c2c7';

@ProviderFor(markNotificationReadUseCase)
final markNotificationReadUseCaseProvider =
    MarkNotificationReadUseCaseProvider._();

final class MarkNotificationReadUseCaseProvider
    extends
        $FunctionalProvider<
          MarkNotificationRead,
          MarkNotificationRead,
          MarkNotificationRead
        >
    with $Provider<MarkNotificationRead> {
  MarkNotificationReadUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'markNotificationReadUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$markNotificationReadUseCaseHash();

  @$internal
  @override
  $ProviderElement<MarkNotificationRead> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MarkNotificationRead create(Ref ref) {
    return markNotificationReadUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MarkNotificationRead value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MarkNotificationRead>(value),
    );
  }
}

String _$markNotificationReadUseCaseHash() =>
    r'ffdd381f45635aa2a3758ea81023ac83be4a0507';

@ProviderFor(markAllNotificationsReadUseCase)
final markAllNotificationsReadUseCaseProvider =
    MarkAllNotificationsReadUseCaseProvider._();

final class MarkAllNotificationsReadUseCaseProvider
    extends
        $FunctionalProvider<
          MarkAllNotificationsRead,
          MarkAllNotificationsRead,
          MarkAllNotificationsRead
        >
    with $Provider<MarkAllNotificationsRead> {
  MarkAllNotificationsReadUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'markAllNotificationsReadUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$markAllNotificationsReadUseCaseHash();

  @$internal
  @override
  $ProviderElement<MarkAllNotificationsRead> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MarkAllNotificationsRead create(Ref ref) {
    return markAllNotificationsReadUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MarkAllNotificationsRead value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MarkAllNotificationsRead>(value),
    );
  }
}

String _$markAllNotificationsReadUseCaseHash() =>
    r'0f0f5e73a8e4bba87cc931752769f1c1a0971971';

@ProviderFor(registerDeviceTokenUseCase)
final registerDeviceTokenUseCaseProvider =
    RegisterDeviceTokenUseCaseProvider._();

final class RegisterDeviceTokenUseCaseProvider
    extends
        $FunctionalProvider<
          RegisterDeviceToken,
          RegisterDeviceToken,
          RegisterDeviceToken
        >
    with $Provider<RegisterDeviceToken> {
  RegisterDeviceTokenUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'registerDeviceTokenUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$registerDeviceTokenUseCaseHash();

  @$internal
  @override
  $ProviderElement<RegisterDeviceToken> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RegisterDeviceToken create(Ref ref) {
    return registerDeviceTokenUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RegisterDeviceToken value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RegisterDeviceToken>(value),
    );
  }
}

String _$registerDeviceTokenUseCaseHash() =>
    r'ca8f364a1e1c72f5f80d9aee297c416009c24365';

@ProviderFor(revokeDeviceTokenUseCase)
final revokeDeviceTokenUseCaseProvider = RevokeDeviceTokenUseCaseProvider._();

final class RevokeDeviceTokenUseCaseProvider
    extends
        $FunctionalProvider<
          RevokeDeviceToken,
          RevokeDeviceToken,
          RevokeDeviceToken
        >
    with $Provider<RevokeDeviceToken> {
  RevokeDeviceTokenUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'revokeDeviceTokenUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$revokeDeviceTokenUseCaseHash();

  @$internal
  @override
  $ProviderElement<RevokeDeviceToken> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RevokeDeviceToken create(Ref ref) {
    return revokeDeviceTokenUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RevokeDeviceToken value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RevokeDeviceToken>(value),
    );
  }
}

String _$revokeDeviceTokenUseCaseHash() =>
    r'5f486283d0f058b21f0c5c375de3606c35c3a810';

/// Live notifications stream — the single source of truth driving the bell
/// badge and the inbox. keepAlive so the broadcast channel stays subscribed
/// across route changes.

@ProviderFor(liveNotifications)
final liveNotificationsProvider = LiveNotificationsProvider._();

/// Live notifications stream — the single source of truth driving the bell
/// badge and the inbox. keepAlive so the broadcast channel stays subscribed
/// across route changes.

final class LiveNotificationsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AppNotification>>,
          List<AppNotification>,
          Stream<List<AppNotification>>
        >
    with
        $FutureModifier<List<AppNotification>>,
        $StreamProvider<List<AppNotification>> {
  /// Live notifications stream — the single source of truth driving the bell
  /// badge and the inbox. keepAlive so the broadcast channel stays subscribed
  /// across route changes.
  LiveNotificationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'liveNotificationsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$liveNotificationsHash();

  @$internal
  @override
  $StreamProviderElement<List<AppNotification>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<AppNotification>> create(Ref ref) {
    return liveNotifications(ref);
  }
}

String _$liveNotificationsHash() => r'9da4f4e988ffb3e5321372770688f990740a1eca';

/// Tier-grouped view-model derived from [liveNotifications].

@ProviderFor(notificationsView)
final notificationsViewProvider = NotificationsViewProvider._();

/// Tier-grouped view-model derived from [liveNotifications].

final class NotificationsViewProvider
    extends
        $FunctionalProvider<
          NotificationsView,
          NotificationsView,
          NotificationsView
        >
    with $Provider<NotificationsView> {
  /// Tier-grouped view-model derived from [liveNotifications].
  NotificationsViewProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationsViewProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationsViewHash();

  @$internal
  @override
  $ProviderElement<NotificationsView> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NotificationsView create(Ref ref) {
    return notificationsView(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotificationsView value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotificationsView>(value),
    );
  }
}

String _$notificationsViewHash() => r'f41b09a504ee6fc7bbcb44381ecad9cd1825cece';

/// Unread count — the value the bell badge renders. Cheap derived view.

@ProviderFor(unreadNotificationsCount)
final unreadNotificationsCountProvider = UnreadNotificationsCountProvider._();

/// Unread count — the value the bell badge renders. Cheap derived view.

final class UnreadNotificationsCountProvider
    extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// Unread count — the value the bell badge renders. Cheap derived view.
  UnreadNotificationsCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'unreadNotificationsCountProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$unreadNotificationsCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return unreadNotificationsCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$unreadNotificationsCountHash() =>
    r'3cf391522f8fda6cf2c7d85ca966951f22c2aa6d';
