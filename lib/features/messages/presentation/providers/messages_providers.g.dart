// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'messages_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(chatLocalFirstEngine)
final chatLocalFirstEngineProvider = ChatLocalFirstEngineProvider._();

final class ChatLocalFirstEngineProvider
    extends
        $FunctionalProvider<
          ChatLocalFirstEngine,
          ChatLocalFirstEngine,
          ChatLocalFirstEngine
        >
    with $Provider<ChatLocalFirstEngine> {
  ChatLocalFirstEngineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatLocalFirstEngineProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatLocalFirstEngineHash();

  @$internal
  @override
  $ProviderElement<ChatLocalFirstEngine> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ChatLocalFirstEngine create(Ref ref) {
    return chatLocalFirstEngine(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatLocalFirstEngine value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatLocalFirstEngine>(value),
    );
  }
}

String _$chatLocalFirstEngineHash() =>
    r'd040f25540590bb2befcd5bd5afd00c29e6a6cab';

@ProviderFor(chatRepository)
final chatRepositoryProvider = ChatRepositoryProvider._();

final class ChatRepositoryProvider
    extends $FunctionalProvider<ChatRepository, ChatRepository, ChatRepository>
    with $Provider<ChatRepository> {
  ChatRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatRepositoryHash();

  @$internal
  @override
  $ProviderElement<ChatRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ChatRepository create(Ref ref) {
    return chatRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatRepository>(value),
    );
  }
}

String _$chatRepositoryHash() => r'67535e8f0ac9b7967dccecb24772d24cfbfc0061';

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
    r'57497331be3fb027df3c09ea9d4d89637661b539';

/// The chat inbox as a fan-out stream: one upstream subscription, many UI consumers.

@ProviderFor(myChats)
final myChatsProvider = MyChatsProvider._();

/// The chat inbox as a fan-out stream: one upstream subscription, many UI consumers.

final class MyChatsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Chat>>,
          List<Chat>,
          Stream<List<Chat>>
        >
    with $FutureModifier<List<Chat>>, $StreamProvider<List<Chat>> {
  /// The chat inbox as a fan-out stream: one upstream subscription, many UI consumers.
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

String _$myChatsHash() => r'e173b3d2d7b28a3b2122c3fadde510dc4c930996';

/// Universal channel inbox stream returning new [ChatChannel] entities.

@ProviderFor(myChatChannels)
final myChatChannelsProvider = MyChatChannelsProvider._();

/// Universal channel inbox stream returning new [ChatChannel] entities.

final class MyChatChannelsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ChatChannel>>,
          List<ChatChannel>,
          Stream<List<ChatChannel>>
        >
    with
        $FutureModifier<List<ChatChannel>>,
        $StreamProvider<List<ChatChannel>> {
  /// Universal channel inbox stream returning new [ChatChannel] entities.
  MyChatChannelsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myChatChannelsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myChatChannelsHash();

  @$internal
  @override
  $StreamProviderElement<List<ChatChannel>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ChatChannel>> create(Ref ref) {
    return myChatChannels(ref);
  }
}

String _$myChatChannelsHash() => r'2bb95007648159fd1705e096e95e551912524a72';

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

/// Streams real-time typing indicators for a specific chat thread.

@ProviderFor(chatTyping)
final chatTypingProvider = ChatTypingFamily._();

/// Streams real-time typing indicators for a specific chat thread.

final class ChatTypingProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  /// Streams real-time typing indicators for a specific chat thread.
  ChatTypingProvider._({
    required ChatTypingFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'chatTypingProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$chatTypingHash();

  @override
  String toString() {
    return r'chatTypingProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    final argument = this.argument as String;
    return chatTyping(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ChatTypingProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$chatTypingHash() => r'c46b92c47c838a0726651b5c96283ead05ec913d';

/// Streams real-time typing indicators for a specific chat thread.

final class ChatTypingFamily extends $Family
    with $FunctionalFamilyOverride<Stream<bool>, String> {
  ChatTypingFamily._()
    : super(
        retry: null,
        name: r'chatTypingProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Streams real-time typing indicators for a specific chat thread.

  ChatTypingProvider call(String chatId) =>
      ChatTypingProvider._(argument: chatId, from: this);

  @override
  String toString() => r'chatTypingProvider';
}

/// Streams the set of user IDs currently present (online) in [chatId].

@ProviderFor(chatPresence)
final chatPresenceProvider = ChatPresenceFamily._();

/// Streams the set of user IDs currently present (online) in [chatId].

final class ChatPresenceProvider
    extends
        $FunctionalProvider<
          AsyncValue<Set<String>>,
          Set<String>,
          Stream<Set<String>>
        >
    with $FutureModifier<Set<String>>, $StreamProvider<Set<String>> {
  /// Streams the set of user IDs currently present (online) in [chatId].
  ChatPresenceProvider._({
    required ChatPresenceFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'chatPresenceProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$chatPresenceHash();

  @override
  String toString() {
    return r'chatPresenceProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Set<String>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Set<String>> create(Ref ref) {
    final argument = this.argument as String;
    return chatPresence(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ChatPresenceProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$chatPresenceHash() => r'4c4cdf815b126c737a208e4f31db1b9d40dea168';

/// Streams the set of user IDs currently present (online) in [chatId].

final class ChatPresenceFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Set<String>>, String> {
  ChatPresenceFamily._()
    : super(
        retry: null,
        name: r'chatPresenceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Streams the set of user IDs currently present (online) in [chatId].

  ChatPresenceProvider call(String chatId) =>
      ChatPresenceProvider._(argument: chatId, from: this);

  @override
  String toString() => r'chatPresenceProvider';
}

/// Streams whether a specific user is currently online in [chatId].

@ProviderFor(isUserOnlineInChat)
final isUserOnlineInChatProvider = IsUserOnlineInChatFamily._();

/// Streams whether a specific user is currently online in [chatId].

final class IsUserOnlineInChatProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  /// Streams whether a specific user is currently online in [chatId].
  IsUserOnlineInChatProvider._({
    required IsUserOnlineInChatFamily super.from,
    required ({String chatId, String userId}) super.argument,
  }) : super(
         retry: null,
         name: r'isUserOnlineInChatProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$isUserOnlineInChatHash();

  @override
  String toString() {
    return r'isUserOnlineInChatProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    final argument = this.argument as ({String chatId, String userId});
    return isUserOnlineInChat(
      ref,
      chatId: argument.chatId,
      userId: argument.userId,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is IsUserOnlineInChatProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$isUserOnlineInChatHash() =>
    r'4513031f5bb05d20630401ca24435056e7988003';

/// Streams whether a specific user is currently online in [chatId].

final class IsUserOnlineInChatFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<bool>,
          ({String chatId, String userId})
        > {
  IsUserOnlineInChatFamily._()
    : super(
        retry: null,
        name: r'isUserOnlineInChatProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Streams whether a specific user is currently online in [chatId].

  IsUserOnlineInChatProvider call({
    required String chatId,
    required String userId,
  }) => IsUserOnlineInChatProvider._(
    argument: (chatId: chatId, userId: userId),
    from: this,
  );

  @override
  String toString() => r'isUserOnlineInChatProvider';
}
