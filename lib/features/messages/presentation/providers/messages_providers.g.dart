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
    r'eff85e04cdcfe0a5b202875489a7c6133d43741a';

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

/// Single universal inbox provider. The legacy myChatsProvider is removed.

@ProviderFor(myChatChannels)
final myChatChannelsProvider = MyChatChannelsProvider._();

/// Single universal inbox provider. The legacy myChatsProvider is removed.

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
  /// Single universal inbox provider. The legacy myChatsProvider is removed.
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

String _$myChatChannelsHash() => r'59d3f0bef95396062ab807b19189749260950bc5';

@ProviderFor(unreadMessagesCount)
final unreadMessagesCountProvider = UnreadMessagesCountProvider._();

final class UnreadMessagesCountProvider
    extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
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
    r'cea979985828b67fa00907751d55af4056f319fa';

@ProviderFor(chatParticipants)
final chatParticipantsProvider = ChatParticipantsFamily._();

final class ChatParticipantsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ChatParticipant>>,
          List<ChatParticipant>,
          Stream<List<ChatParticipant>>
        >
    with
        $FutureModifier<List<ChatParticipant>>,
        $StreamProvider<List<ChatParticipant>> {
  ChatParticipantsProvider._({
    required ChatParticipantsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'chatParticipantsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$chatParticipantsHash();

  @override
  String toString() {
    return r'chatParticipantsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<ChatParticipant>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ChatParticipant>> create(Ref ref) {
    final argument = this.argument as String;
    return chatParticipants(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ChatParticipantsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$chatParticipantsHash() => r'b7f40753090591262ca6940b50930254fca3de03';

final class ChatParticipantsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<ChatParticipant>>, String> {
  ChatParticipantsFamily._()
    : super(
        retry: null,
        name: r'chatParticipantsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ChatParticipantsProvider call(String chatId) =>
      ChatParticipantsProvider._(argument: chatId, from: this);

  @override
  String toString() => r'chatParticipantsProvider';
}

@ProviderFor(chatSyncState)
final chatSyncStateProvider = ChatSyncStateFamily._();

final class ChatSyncStateProvider
    extends
        $FunctionalProvider<
          AsyncValue<ChatSyncState>,
          ChatSyncState,
          Stream<ChatSyncState>
        >
    with $FutureModifier<ChatSyncState>, $StreamProvider<ChatSyncState> {
  ChatSyncStateProvider._({
    required ChatSyncStateFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'chatSyncStateProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$chatSyncStateHash();

  @override
  String toString() {
    return r'chatSyncStateProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<ChatSyncState> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<ChatSyncState> create(Ref ref) {
    final argument = this.argument as String;
    return chatSyncState(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ChatSyncStateProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$chatSyncStateHash() => r'ab0e6fce5728ed2e75641bbf7c8db5f68c36ebeb';

final class ChatSyncStateFamily extends $Family
    with $FunctionalFamilyOverride<Stream<ChatSyncState>, String> {
  ChatSyncStateFamily._()
    : super(
        retry: null,
        name: r'chatSyncStateProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ChatSyncStateProvider call(String chatId) =>
      ChatSyncStateProvider._(argument: chatId, from: this);

  @override
  String toString() => r'chatSyncStateProvider';
}

@ProviderFor(chatMediaUrl)
final chatMediaUrlProvider = ChatMediaUrlFamily._();

final class ChatMediaUrlProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  ChatMediaUrlProvider._({
    required ChatMediaUrlFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'chatMediaUrlProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$chatMediaUrlHash();

  @override
  String toString() {
    return r'chatMediaUrlProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    final argument = this.argument as String;
    return chatMediaUrl(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ChatMediaUrlProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$chatMediaUrlHash() => r'f7ff446d6b3a1b55f9ccd70825be34bcdf2c2c46';

final class ChatMediaUrlFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String>, String> {
  ChatMediaUrlFamily._()
    : super(
        retry: null,
        name: r'chatMediaUrlProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ChatMediaUrlProvider call(String storagePath) =>
      ChatMediaUrlProvider._(argument: storagePath, from: this);

  @override
  String toString() => r'chatMediaUrlProvider';
}

@ProviderFor(chatTypingUsers)
final chatTypingUsersProvider = ChatTypingUsersFamily._();

final class ChatTypingUsersProvider
    extends
        $FunctionalProvider<
          AsyncValue<Set<String>>,
          Set<String>,
          Stream<Set<String>>
        >
    with $FutureModifier<Set<String>>, $StreamProvider<Set<String>> {
  ChatTypingUsersProvider._({
    required ChatTypingUsersFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'chatTypingUsersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$chatTypingUsersHash();

  @override
  String toString() {
    return r'chatTypingUsersProvider'
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
    return chatTypingUsers(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ChatTypingUsersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$chatTypingUsersHash() => r'ae4ae73424f50f0537dbbc590455d27d7dbe9807';

final class ChatTypingUsersFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Set<String>>, String> {
  ChatTypingUsersFamily._()
    : super(
        retry: null,
        name: r'chatTypingUsersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ChatTypingUsersProvider call(String chatId) =>
      ChatTypingUsersProvider._(argument: chatId, from: this);

  @override
  String toString() => r'chatTypingUsersProvider';
}

@ProviderFor(chatPresence)
final chatPresenceProvider = ChatPresenceFamily._();

final class ChatPresenceProvider
    extends
        $FunctionalProvider<
          AsyncValue<Set<String>>,
          Set<String>,
          Stream<Set<String>>
        >
    with $FutureModifier<Set<String>>, $StreamProvider<Set<String>> {
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

String _$chatPresenceHash() => r'1071f5ef0119cfa8b6a91497aa337748cd60f3f3';

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

  ChatPresenceProvider call(String chatId) =>
      ChatPresenceProvider._(argument: chatId, from: this);

  @override
  String toString() => r'chatPresenceProvider';
}

@ProviderFor(isUserOnlineInChat)
final isUserOnlineInChatProvider = IsUserOnlineInChatFamily._();

final class IsUserOnlineInChatProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
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
    r'65a3700cb11deb7a24cd58cfdddf1a9107714c61';

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
