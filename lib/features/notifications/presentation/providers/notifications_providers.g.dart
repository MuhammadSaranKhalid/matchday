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
          AsyncValue<NotificationFeed>,
          NotificationFeed,
          Stream<NotificationFeed>
        >
    with $FutureModifier<NotificationFeed>, $StreamProvider<NotificationFeed> {
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
  $StreamProviderElement<NotificationFeed> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<NotificationFeed> create(Ref ref) {
    return liveNotifications(ref);
  }
}

String _$liveNotificationsHash() => r'08c6ecfd64b3ec5d001650a9c8f012f7edd467d0';

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

String _$notificationsViewHash() => r'5233e0b6542160013de23e613901c131d58f416b';

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

@ProviderFor(notificationSettings)
final notificationSettingsProvider = NotificationSettingsProvider._();

final class NotificationSettingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<NotificationSetting>>,
          List<NotificationSetting>,
          FutureOr<List<NotificationSetting>>
        >
    with
        $FutureModifier<List<NotificationSetting>>,
        $FutureProvider<List<NotificationSetting>> {
  NotificationSettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationSettingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationSettingsHash();

  @$internal
  @override
  $FutureProviderElement<List<NotificationSetting>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<NotificationSetting>> create(Ref ref) {
    return notificationSettings(ref);
  }
}

String _$notificationSettingsHash() =>
    r'578c17e514c147b5ca8920cf25cf858fc4cf0df0';
