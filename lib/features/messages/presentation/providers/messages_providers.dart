import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/datasources/messages_datasource_providers.dart';
import '../../data/repositories/messages_repository_impl.dart';
import '../../domain/entities/chat.dart';
import '../../domain/repositories/messages_repository.dart';

part 'messages_providers.g.dart';

@Riverpod(keepAlive: true)
MessagesRepository messagesRepository(Ref ref) => MessagesRepositoryImpl(
      ref.watch(messagesRemoteDataSourceProvider),
      ref.watch(messagesLocalDataSourceProvider),
    );

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
@riverpod
Stream<List<Chat>> myChats(Ref ref) =>
    ref.watch(messagesRepositoryProvider).watchMyChats();

/// Derived total unread messages count across all active conversations.
@Riverpod(keepAlive: true)
int unreadMessagesCount(Ref ref) {
  final list = ref.watch(myChatsProvider).value ?? const [];
  return list.fold<int>(0, (acc, c) => acc + c.unreadCount);
}

