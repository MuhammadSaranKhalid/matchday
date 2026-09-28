import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/connectivity/connectivity_provider.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/realtime/ably_provider.dart';
import '../../../../core/supabase/supabase_auth_state_provider.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../../safety/presentation/providers/safety_providers.dart';
import '../../data/datasources/messages_datasource_providers.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../data/sync/chat_local_first_engine.dart';
import '../../domain/entities/chat_channel.dart';
import '../../domain/entities/chat_participant.dart';
import '../../domain/entities/chat_sync_state.dart';
import '../../domain/repositories/chat_repository.dart';

part 'messages_providers.g.dart';

@Riverpod(keepAlive: true)
ChatLocalFirstEngine chatLocalFirstEngine(Ref ref) {
  final engine = ChatLocalFirstEngine(
    local: ref.watch(chatLocalDataSourceProvider),
    remote: ref.watch(chatRemoteDataSourceProvider),
    outbox: ref.watch(outboxProcessorProvider),
    ingestor: ref.watch(realtimeIngestorProvider),
    catchUp: ref.watch(catchUpSchedulerProvider),
    ablyService: ref.watch(ablyServiceProvider),
  );

  ref.onDispose(engine.dispose);

  ref.listen<AsyncValue<bool>>(
    isOnlineProvider,
    (previous, next) {
      final wasOnline = previous?.value ?? true;
      final isOnline = next.value ?? true;
      if (!wasOnline && isOnline) {
        unawaited(engine.reconcile('connectivity_restored'));
      }
    },
  );

  ref.listen<String?>(
    currentUserIdProvider,
    (previous, next) {
      if (previous == next) return;
      if (next == null) {
        engine.endSession();
      } else {
        unawaited(engine.startSession(next));
      }
    },
    fireImmediately: true,
  );

  return engine;
}

@Riverpod(keepAlive: true)
ChatRepository chatRepository(Ref ref) => ChatRepositoryImpl(
      localDataSource: ref.watch(chatLocalDataSourceProvider),
      remoteDataSource: ref.watch(chatRemoteDataSourceProvider),
      outboxProcessor: ref.watch(outboxProcessorProvider),
      realtimeIngestor: ref.watch(realtimeIngestorProvider),
      syncCoordinator: ref.watch(chatSyncCoordinatorProvider),
      receiptCoordinator: ref.watch(receiptCoordinatorProvider),
      supabase: ref.watch(supabaseClientProvider),
    );

/// Single universal inbox provider. The legacy myChatsProvider is removed.
@riverpod
Stream<List<ChatChannel>> myChatChannels(Ref ref) {
  // Make the user boundary an explicit reactive dependency. The repository
  // reads the current Supabase user synchronously when the stream is built;
  // watching this provider guarantees the stream is rebuilt on account switch
  // even if unrelated providers do not change.
  final currentUserId = ref.watch(currentUserIdProvider);
  if (currentUserId == null) return Stream.value(const <ChatChannel>[]);

  final blocked = ref.watch(blockedAccountsProvider).value ?? const [];
  return ref.watch(chatRepositoryProvider).watchInbox().map(
        (channels) => channels
            .where(
              (channel) => !blocked.any(
                (user) => user.id == channel.dmOtherUserId,
              ),
            )
            .toList(),
      );
}

@Riverpod(keepAlive: true)
int unreadMessagesCount(Ref ref) {
  final channels = ref.watch(myChatChannelsProvider).value ?? const [];
  return channels.fold<int>(0, (sum, channel) => sum + channel.unreadCount);
}

@riverpod
Stream<List<ChatParticipant>> chatParticipants(Ref ref, String chatId) =>
    ref.watch(chatRepositoryProvider).watchParticipants(chatId);

@riverpod
Stream<ChatSyncState> chatSyncState(Ref ref, String chatId) =>
    ref.watch(chatRepositoryProvider).watchSyncState(chatId);

@riverpod
Future<String> chatMediaUrl(Ref ref, String storagePath) async {
  final result = await ref
      .watch(chatRepositoryProvider)
      .resolveMediaUrl(storagePath);
  return result.fold(
    (failure) => throw FailureWrapper(failure),
    (url) => url,
  );
}

@riverpod
Stream<Set<String>> chatTypingUsers(Ref ref, String chatId) =>
    ref.watch(chatRepositoryProvider).watchTypingUsers(chatId);

@riverpod
Stream<Set<String>> chatPresence(Ref ref, String chatId) =>
    ref.watch(chatRepositoryProvider).watchPresence(chatId);

@riverpod
Stream<bool> isUserOnlineInChat(
  Ref ref, {
  required String chatId,
  required String userId,
}) =>
    ref
        .watch(chatRepositoryProvider)
        .watchPresence(chatId)
        .map((users) => users.contains(userId))
        .distinct();
