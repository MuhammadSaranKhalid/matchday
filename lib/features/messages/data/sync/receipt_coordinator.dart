import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../datasources/chat_local_data_source.dart';
import 'outbox_processor.dart';

/// Coordinates durable delivered and read receipts via local SQLite horizons
/// and the offline Outbox (Spec §13, §14, §20).
class ReceiptCoordinator {
  ReceiptCoordinator({
    required this.local,
    required this.outbox,
  });

  final ChatLocalDataSource local;
  final OutboxProcessor outbox;
  static const _uuid = Uuid();

  /// Monotonically records a delivery receipt into local Drift storage and
  /// enqueues an Outbox operation without relying on immediate network availability (Spec §13).
  Future<void> markDelivered(
    String channelId,
    String userId,
    int throughSeq,
  ) async {
    if (throughSeq <= 0) return;

    final now = DateTime.now().toUtc();

    // 1. Monotonically update LocalChannelMembers.lastDeliveredMessageSeq
    await local.updateMemberHorizons(
      channelId,
      userId,
      deliveredSeq: throughSeq,
    );

    // 2. Enqueue coalesced Outbox operation
    final op = OutboxOperationsCompanion.insert(
      operationId: _uuid.v4(),
      channelId: channelId,
      operationType: 'mark_delivered',
      coalesceKey: Value('delivered:$channelId'),
      payloadJson: jsonEncode({'through_seq': throughSeq}),
      createdAt: now,
      updatedAt: now,
    );

    await local.enqueueOperation(op);

    // 3. Notify outbox processor
    outbox.notify();
  }

  /// Monotonically records a read receipt into local Drift storage, guarantees
  /// delivered horizon >= read horizon, and enqueues an Outbox operation (Spec §14).
  Future<void> markRead(
    String channelId,
    String userId,
    int throughSeq,
  ) async {
    if (throughSeq <= 0) return;

    final now = DateTime.now().toUtc();

    // 1. Monotonically update LocalChannelMembers (delivered guaranteed >= read)
    await local.updateMemberHorizons(
      channelId,
      userId,
      readSeq: throughSeq,
      deliveredSeq: throughSeq,
    );

    // 2. Enqueue coalesced Outbox operation
    final op = OutboxOperationsCompanion.insert(
      operationId: _uuid.v4(),
      channelId: channelId,
      operationType: 'mark_read',
      coalesceKey: Value('read:$channelId'),
      payloadJson: jsonEncode({'through_seq': throughSeq}),
      createdAt: now,
      updatedAt: now,
    );

    await local.enqueueOperation(op);

    // 3. Notify outbox processor
    outbox.notify();
  }
}
