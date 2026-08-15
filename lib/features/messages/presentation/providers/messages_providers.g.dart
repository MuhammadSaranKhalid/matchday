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
    r'53befdbb609313134ef711a751f46abe7d5822ff';

/// The chat inbox as a fan-out stream: one upstream subscription, many UI
/// consumers. Per CLAUDE.md §5.3, intermediate `@riverpod Stream` providers
/// belong here rather than in a controller — the inbox screen has no write
/// path on the inbox itself; writes happen in the thread.
///
/// Autodispose (bare `@riverpod`), matching the codebase-wide convention for
/// free-function `Stream` providers (compare `liveMatch`, `myTeams`,
/// `roster`, etc.). The inbox tab is the parent screen and stays mounted
/// throughout the session via `StatefulShellRoute`, so listeners are always
/// present and the provider is never actually disposed in practice. The
/// `markRead` → `ref.invalidate(myChatsProvider)` cascade therefore always
/// finds a live provider to re-trigger.

@ProviderFor(myChats)
final myChatsProvider = MyChatsProvider._();

/// The chat inbox as a fan-out stream: one upstream subscription, many UI
/// consumers. Per CLAUDE.md §5.3, intermediate `@riverpod Stream` providers
/// belong here rather than in a controller — the inbox screen has no write
/// path on the inbox itself; writes happen in the thread.
///
/// Autodispose (bare `@riverpod`), matching the codebase-wide convention for
/// free-function `Stream` providers (compare `liveMatch`, `myTeams`,
/// `roster`, etc.). The inbox tab is the parent screen and stays mounted
/// throughout the session via `StatefulShellRoute`, so listeners are always
/// present and the provider is never actually disposed in practice. The
/// `markRead` → `ref.invalidate(myChatsProvider)` cascade therefore always
/// finds a live provider to re-trigger.

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
  /// path on the inbox itself; writes happen in the thread.
  ///
  /// Autodispose (bare `@riverpod`), matching the codebase-wide convention for
  /// free-function `Stream` providers (compare `liveMatch`, `myTeams`,
  /// `roster`, etc.). The inbox tab is the parent screen and stays mounted
  /// throughout the session via `StatefulShellRoute`, so listeners are always
  /// present and the provider is never actually disposed in practice. The
  /// `markRead` → `ref.invalidate(myChatsProvider)` cascade therefore always
  /// finds a live provider to re-trigger.
  MyChatsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myChatsProvider',
        isAutoDispose: true,
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

String _$myChatsHash() => r'64705df418e5974228836f9c8cd5d5c47482f3fe';

/// Derived total unread messages count across all active conversations.

@ProviderFor(unreadMessagesCount)
final unreadMessagesCountProvider = UnreadMessagesCountProvider._();

/// Derived total unread messages count across all active conversations.

final class UnreadMessagesCountProvider
    extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// Derived total unread messages count across all active conversations.
  UnreadMessagesCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'unreadMessagesCountProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$unreadMessagesCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return unreadMessagesCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$unreadMessagesCountHash() =>
    r'45ae1d166f4d05d9d1d6fc958e86f804d4f4ac7a';
