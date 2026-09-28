import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../datasources/chat_local_data_source.dart';
import 'outbox_processor.dart';

/// Coordinates durable delivered/read horizons through Drift + the Outbox.
class ReceiptCoordinator {
  ReceiptCoordinator({
    required this.local,
    required this.outbox,
  });

  final ChatLocalDataSource local;
  final OutboxProcessor outbox;
  static const _uuid = Uuid();

  Future<void> markDelivered(
    String channelId,
    String userId,
    int throughSeq,
  ) async {
    if (throughSeq <= 0) return;

    final now = DateTime.now().toUtc();
    await local.updateMemberHorizons(
      channelId,
      userId,
      deliveredSeq: throughSeq,
    );

    await local.enqueueOperation(
      OutboxOperationsCompanion.insert(
        operationId: _uuid.v4(),
        ownerUserId: Value(userId),
        channelId: channelId,
        operationType: 'mark_delivered',
        coalesceKey: Value('delivered:$userId:$channelId'),
        payloadJson: jsonEncode({'through_seq': throughSeq}),
        createdAt: now,
        updatedAt: now,
      ),
    );
    outbox.notify();
  }

  Future<void> markRead(
    String channelId,
    String userId,
    int throughSeq,
  ) async {
    if (throughSeq <= 0) return;

    final now = DateTime.now().toUtc();
    await local.updateMemberHorizons(
      channelId,
      userId,
      readSeq: throughSeq,
      deliveredSeq: throughSeq,
    );

    await local.enqueueOperation(
      OutboxOperationsCompanion.insert(
        operationId: _uuid.v4(),
        ownerUserId: Value(userId),
        channelId: channelId,
        operationType: 'mark_read',
        coalesceKey: Value('read:$userId:$channelId'),
        payloadJson: jsonEncode({'through_seq': throughSeq}),
        createdAt: now,
        updatedAt: now,
      ),
    );
    outbox.notify();
  }
}
