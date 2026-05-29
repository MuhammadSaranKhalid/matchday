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

String _$liveNotificationsHash() => r'31a61e266e14088440ce52df73dbc059dc4da769';

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
