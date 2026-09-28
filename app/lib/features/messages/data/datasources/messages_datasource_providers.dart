import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/database/database_provider.dart';
import '../../../../core/realtime/ably_provider.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../sync/catch_up_scheduler.dart';
import '../sync/chat_sync_coordinator.dart';
import '../sync/outbox_processor.dart';
import '../sync/receipt_coordinator.dart';
import '../sync/realtime_ingestor.dart';
import 'chat_local_data_source.dart';
import 'chat_remote_data_source.dart';

part 'messages_datasource_providers.g.dart';

@Riverpod(keepAlive: true)
ChatLocalDataSource chatLocalDataSource(Ref ref) =>
    ChatLocalDataSource(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
ChatRemoteDataSource chatRemoteDataSource(Ref ref) =>
    ChatRemoteDataSource(ref.watch(supabaseClientProvider));

@Riverpod(keepAlive: true)
OutboxProcessor outboxProcessor(Ref ref) {
  final processor = OutboxProcessor(
    ref.watch(chatLocalDataSourceProvider),
    ref.watch(chatRemoteDataSourceProvider),
    currentUserId: () =>
        ref.read(supabaseClientProvider).auth.currentUser?.id,
  );
  ref.onDispose(processor.dispose);
  return processor;
}

@Riverpod(keepAlive: true)
ReceiptCoordinator receiptCoordinator(Ref ref) => ReceiptCoordinator(
      local: ref.watch(chatLocalDataSourceProvider),
      outbox: ref.watch(outboxProcessorProvider),
    );

@Riverpod(keepAlive: true)
RealtimeIngestor realtimeIngestor(Ref ref) {
  final ingestor = RealtimeIngestor(
    ref.watch(ablyServiceProvider),
    ref.watch(chatLocalDataSourceProvider),
  );
  final receipts = ref.watch(receiptCoordinatorProvider);
  final scheduler = ref.watch(catchUpSchedulerProvider);

  ingestor.onMessageDelivered = (channelId, throughSeq) {
    final user = ref.read(supabaseClientProvider).auth.currentUser;
    if (user != null) {
      unawaited(() async {
        final local = ref.read(chatLocalDataSourceProvider);
        if (await local.isActiveMembership(channelId, user.id)) {
          await receipts.markDelivered(channelId, user.id, throughSeq);
        }
      }());
    }
  };
  ingestor.onTargetedCatchUpRequested = (channelId) {
    scheduler.enqueue(channelId, highPriority: true);
  };

  ref.onDispose(ingestor.dispose);
  return ingestor;
}

@Riverpod(keepAlive: true)
CatchUpScheduler catchUpScheduler(Ref ref) {
  final scheduler = CatchUpScheduler(
    local: ref.watch(chatLocalDataSourceProvider),
    remote: ref.watch(chatRemoteDataSourceProvider),
    db: ref.watch(appDatabaseProvider),
  );
  final receipts = ref.watch(receiptCoordinatorProvider);
  scheduler.onMessagesDelivered = (channelId, throughSeq) {
    final user = ref.read(supabaseClientProvider).auth.currentUser;
    if (user != null) {
      unawaited(() async {
        final local = ref.read(chatLocalDataSourceProvider);
        if (await local.isActiveMembership(channelId, user.id)) {
          await receipts.markDelivered(channelId, user.id, throughSeq);
        }
      }());
    }
  };
  return scheduler;
}

@Riverpod(keepAlive: true)
ChatSyncCoordinator chatSyncCoordinator(Ref ref) => ChatSyncCoordinator(
      local: ref.watch(chatLocalDataSourceProvider),
      remote: ref.watch(chatRemoteDataSourceProvider),
      outbox: ref.watch(outboxProcessorProvider),
      ingestor: ref.watch(realtimeIngestorProvider),
      catchUpScheduler: ref.watch(catchUpSchedulerProvider),
      receiptCoordinator: ref.watch(receiptCoordinatorProvider),
      db: ref.watch(appDatabaseProvider),
    );
