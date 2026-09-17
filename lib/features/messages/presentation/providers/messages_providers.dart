import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/supabase/supabase_client_provider.dart';
import '../../../safety/presentation/providers/safety_providers.dart';
import '../../data/datasources/messages_datasource_providers.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../data/repositories/messages_repository_impl.dart';
import '../../domain/entities/chat.dart';
import '../../domain/entities/chat_channel.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/repositories/messages_repository.dart';

part 'messages_providers.g.dart';

@Riverpod(keepAlive: true)
ChatRepository chatRepository(Ref ref) => ChatRepositoryImpl(
      localDataSource: ref.watch(chatLocalDataSourceProvider),
      remoteDataSource: ref.watch(chatRemoteDataSourceProvider),
      outboxProcessor: ref.watch(outboxProcessorProvider),
      realtimeIngestor: ref.watch(realtimeIngestorProvider),
      syncCoordinator: ref.watch(chatSyncCoordinatorProvider),
      supabase: ref.watch(supabaseClientProvider),
    );

@Riverpod(keepAlive: true)
MessagesRepository messagesRepository(Ref ref) => MessagesRepositoryImpl(
      ref.watch(chatRepositoryProvider),
    );

/// The chat inbox as a fan-out stream: one upstream subscription, many UI consumers.
@riverpod
Stream<List<Chat>> myChats(Ref ref) {
  final blocked = ref.watch(blockedAccountsProvider).value ?? [];
  return ref
      .watch(messagesRepositoryProvider)
      .watchMyChats()
      .map((chats) => chats.where((c) => !blocked.any((u) => u.id == c.dmOtherUserId)).toList());
}

/// Universal channel inbox stream returning new [ChatChannel] entities.
@riverpod
Stream<List<ChatChannel>> myChatChannels(Ref ref) {
  final blocked = ref.watch(blockedAccountsProvider).value ?? [];
  return ref
      .watch(chatRepositoryProvider)
      .watchInbox()
      .map((channels) => channels.where((c) => !blocked.any((u) => u.id == c.dmOtherUserId)).toList());
}

/// Derived total unread messages count across all active conversations.
@Riverpod(keepAlive: true)
int unreadMessagesCount(Ref ref) {
  final list = ref.watch(myChatsProvider).value ?? const [];
  return list.fold<int>(0, (acc, c) => acc + c.unreadCount);
}

/// Streams real-time typing indicators for a specific chat thread.
@riverpod
Stream<bool> chatTyping(Ref ref, String chatId) {
  return ref.watch(chatRepositoryProvider).watchTyping(chatId);
}
