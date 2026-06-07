// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'messages_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(messagesRepository)
final messagesRepositoryProvider = MessagesRepositoryProvider._();

final class MessagesRepositoryProvider
    extends
        $FunctionalProvider<
          MessagesRepository,
          MessagesRepository,
          MessagesRepository
        >
    with $Provider<MessagesRepository> {
  MessagesRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'messagesRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$messagesRepositoryHash();

  @$internal
  @override
  $ProviderElement<MessagesRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MessagesRepository create(Ref ref) {
    return messagesRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MessagesRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MessagesRepository>(value),
    );
  }
}

String _$messagesRepositoryHash() =>
    r'ef7d27ea2acef487f4bb31f3deaa894e8ccc960d';

/// The chat inbox as a fan-out stream: one upstream subscription, many UI
/// consumers. Per CLAUDE.md §5.3, intermediate `@riverpod Stream` providers
/// belong here rather than in a controller — the inbox screen has no write
/// path in part 1 of the rollout.
///
/// `keepAlive: true` is load-bearing: `MessageThreadController.markRead()`
/// invalidates this provider after a successful read-receipt stamp so the
/// inbox's unread badges re-emit reactively. If this provider were
/// autodispose and the user was only on the thread screen (inbox unmounted),
/// the provider would have already disposed by the time `markRead` runs —
/// `invalidate` against a disposed provider is a no-op, the badges would
/// stay stale. Mirrors the repository provider's posture.

@ProviderFor(myChats)
final myChatsProvider = MyChatsProvider._();

/// The chat inbox as a fan-out stream: one upstream subscription, many UI
/// consumers. Per CLAUDE.md §5.3, intermediate `@riverpod Stream` providers
/// belong here rather than in a controller — the inbox screen has no write
/// path in part 1 of the rollout.
///
/// `keepAlive: true` is load-bearing: `MessageThreadController.markRead()`
/// invalidates this provider after a successful read-receipt stamp so the
/// inbox's unread badges re-emit reactively. If this provider were
/// autodispose and the user was only on the thread screen (inbox unmounted),
/// the provider would have already disposed by the time `markRead` runs —
/// `invalidate` against a disposed provider is a no-op, the badges would
/// stay stale. Mirrors the repository provider's posture.

final class MyChatsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Chat>>,
          List<Chat>,
          Stream<List<Chat>>
        >
    with $FutureModifier<List<Chat>>, $StreamProvider<List<Chat>> {
  /// The chat inbox as a fan-out stream: one upstream subscription, many UI
  /// consumers. Per CLAUDE.md §5.3, intermediate `@riverpod Stream` providers
  /// belong here rather than in a controller — the inbox screen has no write
  /// path in part 1 of the rollout.
  ///
  /// `keepAlive: true` is load-bearing: `MessageThreadController.markRead()`
  /// invalidates this provider after a successful read-receipt stamp so the
  /// inbox's unread badges re-emit reactively. If this provider were
  /// autodispose and the user was only on the thread screen (inbox unmounted),
  /// the provider would have already disposed by the time `markRead` runs —
  /// `invalidate` against a disposed provider is a no-op, the badges would
  /// stay stale. Mirrors the repository provider's posture.
  MyChatsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myChatsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myChatsHash();

  @$internal
  @override
  $StreamProviderElement<List<Chat>> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<Chat>> create(Ref ref) {
    return myChats(ref);
  }
}

String _$myChatsHash() => r'68a811b37eb30ae02d6d9f89c48717aebeb231a0';
