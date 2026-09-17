import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/database/database_provider.dart';
import '../../../../core/realtime/ably_provider.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../sync/chat_sync_coordinator.dart';
import '../sync/outbox_processor.dart';
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
OutboxProcessor outboxProcessor(Ref ref) => OutboxProcessor(
      ref.watch(chatLocalDataSourceProvider),
      ref.watch(chatRemoteDataSourceProvider),
    );

@Riverpod(keepAlive: true)
RealtimeIngestor realtimeIngestor(Ref ref) => RealtimeIngestor(
      ref.watch(ablyServiceProvider),
      ref.watch(chatLocalDataSourceProvider),
    );

@Riverpod(keepAlive: true)
ChatSyncCoordinator chatSyncCoordinator(Ref ref) => ChatSyncCoordinator(
      local: ref.watch(chatLocalDataSourceProvider),
      remote: ref.watch(chatRemoteDataSourceProvider),
      outbox: ref.watch(outboxProcessorProvider),
      ingestor: ref.watch(realtimeIngestorProvider),
      db: ref.watch(appDatabaseProvider),
      ablyService: ref.watch(ablyServiceProvider),
    );
