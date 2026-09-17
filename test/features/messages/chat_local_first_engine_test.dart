import 'package:ably_flutter/ably_flutter.dart' as ably;
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/core/database/app_database.dart';
import 'package:matchday/core/realtime/ably_service.dart';
import 'package:matchday/features/messages/data/datasources/chat_local_data_source.dart';
import 'package:matchday/features/messages/data/datasources/chat_remote_data_source.dart';
import 'package:matchday/features/messages/data/models/chat_channel_dto.dart';
import 'package:matchday/features/messages/data/repositories/chat_repository_impl.dart';
import 'package:matchday/features/messages/data/sync/catch_up_scheduler.dart';
import 'package:matchday/features/messages/data/sync/chat_local_first_engine.dart';
import 'package:matchday/features/messages/data/sync/chat_sync_coordinator.dart';
import 'package:matchday/features/messages/data/sync/outbox_processor.dart';
import 'package:matchday/features/messages/data/sync/receipt_coordinator.dart';
import 'package:matchday/features/messages/data/sync/realtime_ingestor.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockRemoteDataSource extends Mock implements ChatRemoteDataSource {}
class _MockRealtimeIngestor extends Mock implements RealtimeIngestor {}
class _MockOutboxProcessor extends Mock implements OutboxProcessor {}
class _MockCatchUpScheduler extends Mock implements CatchUpScheduler {}
class _MockSupabaseClient extends Mock implements SupabaseClient {}
class _MockGoTrueClient extends Mock implements GoTrueClient {}
class _MockAblyService extends Mock implements AblyService {}

void main() {
  late AppDatabase db;
  late ChatLocalDataSource local;
  late _MockRemoteDataSource remote;
  late _MockRealtimeIngestor ingestor;
  late _MockOutboxProcessor outbox;
  late _MockCatchUpScheduler catchUp;
  late ChatLocalFirstEngine engine;

  const userIdA = 'user-aaa';
  const userIdB = 'user-bbb';

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    local = ChatLocalDataSource(db);
    remote = _MockRemoteDataSource();
    ingestor = _MockRealtimeIngestor();
    outbox = _MockOutboxProcessor();
    catchUp = _MockCatchUpScheduler();

    when(() => ingestor.subscribeToUserInbox(any(), onUpdated: any(named: 'onUpdated')))
        .thenReturn(null);
    when(() => ingestor.unsubscribeFromUserInbox()).thenReturn(null);
    when(() => catchUp.setSessionUser(any())).thenReturn(null);
    when(() => catchUp.run(any())).thenAnswer((_) async {});
    when(() => outbox.drain()).thenAnswer((_) async {});
    when(() => remote.listMyChats()).thenAnswer((_) async => <ChatChannelDto>[]);

    engine = ChatLocalFirstEngine(
      local: local,
      remote: remote,
      outbox: outbox,
      ingestor: ingestor,
      catchUp: catchUp,
    );
  });

  tearDown(() async {
    engine.dispose();
    await db.close();
  });

  group('ChatLocalFirstEngine', () {
    test('Startup sequence executes in authoritative order (Spec §8)', () async {
      final executionLog = <String>[];

      when(() => ingestor.subscribeToUserInbox(userIdA, onUpdated: any(named: 'onUpdated')))
          .thenAnswer((_) {
        executionLog.add('ably_attach');
      });

      when(() => remote.listMyChats()).thenAnswer((_) async {
        executionLog.add('sync_inbox');
        return <ChatChannelDto>[];
      });

      when(() => catchUp.run(userIdA)).thenAnswer((_) async {
        executionLog.add('catch_up');
      });

      when(() => outbox.drain()).thenAnswer((_) async {
        executionLog.add('outbox_drain');
      });

      // Insert a stale processing operation to test recovery
      final staleDate = DateTime.now().toUtc().subtract(const Duration(minutes: 5));
      await db.into(db.outboxOperations).insert(
        OutboxOperationsCompanion.insert(
          operationId: 'stale-op-1',
          channelId: 'ch-1',
          operationType: 'send_message',
          payloadJson: '{}',
          status: const Value('processing'),
          createdAt: staleDate,
          updatedAt: staleDate,
        ),
      );

      // Simulate sign in
      await engine.startSession(userIdA);

      // Verify stale operation was recovered
      final op = await (db.select(db.outboxOperations)..where((o) => o.operationId.equals('stale-op-1'))).getSingle();
      expect(op.status, 'pending');

      // Verify ordering: ably attached, inbox synced, catch up executed, outbox drained
      expect(executionLog, containsAllInOrder(['ably_attach', 'sync_inbox', 'catch_up', 'outbox_drain']));
    });

    test('M. Multiple triggers collapse into single-flight reconciliation pass', () async {
      int listMyChatsCount = 0;
      when(() => remote.listMyChats()).thenAnswer((_) async {
        listMyChatsCount++;
        await Future<void>.delayed(const Duration(milliseconds: 30));
        return <ChatChannelDto>[];
      });

      await engine.startSession(userIdA);
      listMyChatsCount = 0; // reset after initial startSession reconciliation

      // Fire multiple simultaneous reconciliations
      final future1 = engine.reconcile('trigger_1');
      final future2 = engine.reconcile('trigger_2');
      final future3 = engine.reconcile('trigger_3');

      await Future.wait([future1, future2, future3]);

      // At most 2 passes occur (the in-flight one + one collapsed catch-up pass)
      expect(listMyChatsCount, inInclusiveRange(1, 2));
    });

    test('Q. Account switch: old user async work cannot commit after new user signs in', () async {
      when(() => remote.listMyChats()).thenAnswer((_) async {
        // Slow network response for user A
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return [
          ChatChannelDto(
            channelId: 'ch-user-a',
            channelKey: 'direct:1:2',
            kind: 'direct',
            contextType: 'none',
            title: 'User A Channel',
            createdAt: DateTime.now().toUtc().toIso8601String(),
            updatedAt: DateTime.now().toUtc().toIso8601String(),
          ),
        ];
      });

      final userAFuture = engine.startSession(userIdA);

      // User B immediately signs in before user A completes
      engine.dispose();
      final engineB = ChatLocalFirstEngine(
        local: local,
        remote: remote,
        outbox: outbox,
        ingestor: ingestor,
        catchUp: catchUp,
      );

      when(() => remote.listMyChats()).thenAnswer((_) async => []);
      await engineB.startSession(userIdB);

      await userAFuture;
      engineB.dispose();

      // Verify user A's slow response didn't write to DB after switch
      final userAChannels = await (db.select(db.localChannels)..where((c) => c.channelId.equals('ch-user-a'))).get();
      expect(userAChannels, isEmpty);
    });

    test('N. Repository watchInbox: local subscription does not trigger network call', () async {
      final mockSupabase = _MockSupabaseClient();
      final mockAuth = _MockGoTrueClient();
      when(() => mockSupabase.auth).thenReturn(mockAuth);
      when(() => mockAuth.currentUser).thenReturn(
        User(
          id: userIdA,
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: DateTime.now().toIso8601String(),
        ),
      );

      final receipts = ReceiptCoordinator(local: local, outbox: outbox);
      final syncCoord = ChatSyncCoordinator(
        local: local,
        remote: remote,
        outbox: outbox,
        ingestor: ingestor,
        catchUpScheduler: catchUp,
        receiptCoordinator: receipts,
        db: db,
      );

      final repo = ChatRepositoryImpl(
        localDataSource: local,
        remoteDataSource: remote,
        outboxProcessor: outbox,
        realtimeIngestor: ingestor,
        syncCoordinator: syncCoord,
        receiptCoordinator: receipts,
        supabase: mockSupabase,
      );

      // Listening to watchInbox
      final inboxStream = repo.watchInbox();
      final list = await inboxStream.first;
      expect(list, isEmpty);

      // Verify ZERO network calls were made to remote.listMyChats
      verifyNever(() => remote.listMyChats());
    });

    test('Ably connection recovery triggers reconciliation pass', () async {
      final mockAbly = _MockAblyService();
      void Function(ably.ConnectionStateChange)? connectionListener;

      when(() => mockAbly.addResumeListener(any())).thenReturn(null);
      when(() => mockAbly.removeResumeListener(any())).thenReturn(null);
      when(() => mockAbly.addConnectionStateListener(any())).thenAnswer((inv) {
        connectionListener = inv.positionalArguments.first as void Function(ably.ConnectionStateChange);
      });
      when(() => mockAbly.removeConnectionStateListener(any())).thenReturn(null);

      final testEngine = ChatLocalFirstEngine(
        local: local,
        remote: remote,
        outbox: outbox,
        ingestor: ingestor,
        catchUp: catchUp,
        ablyService: mockAbly,
      );

      await testEngine.startSession(userIdA);
      clearInteractions(remote);
      clearInteractions(outbox);

      expect(connectionListener, isNotNull);

      // Simulate connection recovered: disconnected -> connected
      final change = ably.ConnectionStateChange(
        current: ably.ConnectionState.connected,
        previous: ably.ConnectionState.disconnected,
        event: ably.ConnectionEvent.connected,
      );
      connectionListener!(change);

      // Allow async single-flight reconciliation pass to run
      await pumpEventQueue();

      verify(() => remote.listMyChats()).called(1);
      verify(() => outbox.drain()).called(1);

      testEngine.dispose();
      verify(() => mockAbly.removeConnectionStateListener(any())).called(1);
    });
  });
}
