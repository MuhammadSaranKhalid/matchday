import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/core/database/app_database.dart';
import 'package:matchday/features/messages/data/datasources/chat_local_data_source.dart';
import 'package:matchday/features/messages/data/models/chat_channel_dto.dart';
import 'package:matchday/features/messages/data/sync/outbox_processor.dart';
import 'package:matchday/features/messages/data/sync/receipt_coordinator.dart';
import 'package:mocktail/mocktail.dart';

class _MockOutboxProcessor extends Mock implements OutboxProcessor {}

void main() {
  late AppDatabase db;
  late ChatLocalDataSource local;
  late _MockOutboxProcessor outbox;
  late ReceiptCoordinator receipts;

  const channelId = 'ch-receipt-1';
  const userId = 'user-1';

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    local = ChatLocalDataSource(db);
    outbox = _MockOutboxProcessor();
    when(() => outbox.notify()).thenReturn(null);

    receipts = ReceiptCoordinator(local: local, outbox: outbox);

    // Insert dummy channel and member via DTO
    final now = DateTime.now().toUtc();
    await local.upsertChannelsFromDto([
      ChatChannelDto(
        channelId: channelId,
        channelKey: 'direct:1:2',
        kind: 'direct',
        contextType: 'none',
        title: 'Direct Chat',
        createdAt: now.toIso8601String(),
        updatedAt: now.toIso8601String(),
      ),
    ], userId);
  });

  tearDown(() async {
    await db.close();
  });

  group('ReceiptCoordinator (Spec §13, §14, §20)', () {
    test('I. Delivered receipt creates coalesced Outbox op without immediate network', () async {
      await receipts.markDelivered(channelId, userId, 100);

      // Verify outbox was notified
      verify(() => outbox.notify()).called(1);

      // Verify member horizon updated in Drift
      final member = await (db.select(db.localChannelMembers)
            ..where((m) => m.channelId.equals(channelId) & m.userId.equals(userId)))
          .getSingle();
      expect(member.lastDeliveredMessageSeq, 100);

      // Verify Outbox operation row created with coalesce key
      final ops = await (db.select(db.outboxOperations)
            ..where((o) => o.channelId.equals(channelId)))
          .get();
      expect(ops, hasLength(1));
      expect(ops.first.operationType, 'mark_delivered');
      expect(ops.first.coalesceKey, 'delivered:$channelId');
      final payload = jsonDecode(ops.first.payloadJson) as Map<String, dynamic>;
      expect(payload['through_seq'], 100);
    });

    test('J. Receipt monotonicity: delivered 500 followed by delivered 450 keeps 500', () async {
      await receipts.markDelivered(channelId, userId, 500);
      await receipts.markDelivered(channelId, userId, 450);

      // Verify Drift member horizon is monotonically preserved at 500
      final member = await (db.select(db.localChannelMembers)
            ..where((m) => m.channelId.equals(channelId) & m.userId.equals(userId)))
          .getSingle();
      expect(member.lastDeliveredMessageSeq, 500);

      // Verify coalesced Outbox operation kept 500, not 450
      final ops = await (db.select(db.outboxOperations)
            ..where((o) => o.coalesceKey.equals('delivered:$channelId')))
          .get();
      expect(ops, hasLength(1));
      final payload = jsonDecode(ops.first.payloadJson) as Map<String, dynamic>;
      expect(payload['through_seq'], 500);
    });

    test('K. Read monotonicity: read horizon never decreases and ensures delivered >= read', () async {
      await receipts.markRead(channelId, userId, 600);
      await receipts.markRead(channelId, userId, 550);

      // Verify member horizons in Drift
      final member = await (db.select(db.localChannelMembers)
            ..where((m) => m.channelId.equals(channelId) & m.userId.equals(userId)))
          .getSingle();
      expect(member.lastReadMessageSeq, 600);
      expect(member.lastDeliveredMessageSeq, greaterThanOrEqualTo(600));

      // Verify coalesced Outbox operation kept 600
      final ops = await (db.select(db.outboxOperations)
            ..where((o) => o.coalesceKey.equals('read:$channelId')))
          .get();
      expect(ops, hasLength(1));
      final payload = jsonDecode(ops.first.payloadJson) as Map<String, dynamic>;
      expect(payload['through_seq'], 600);
    });
  });
}
