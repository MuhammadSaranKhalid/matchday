import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/database/app_database.dart';
import '../datasources/chat_local_data_source.dart';
import '../datasources/chat_remote_data_source.dart';
import 'catch_up_scheduler.dart';
import 'outbox_processor.dart';
import 'receipt_coordinator.dart';
import 'realtime_ingestor.dart';

/// Coordinates offline cache, network fetches, Ably subscriptions, and outbox draining.
class ChatSyncCoordinator {
  ChatSyncCoordinator({
    required this.local,
    required this.remote,
    required this.outbox,
    required this.ingestor,
    required this.catchUpScheduler,
    required this.receiptCoordinator,
    required this.db,
  });

  final ChatLocalDataSource local;
  final ChatRemoteDataSource remote;
  final OutboxProcessor outbox;
  final RealtimeIngestor ingestor;
  final CatchUpScheduler catchUpScheduler;
  final ReceiptCoordinator receiptCoordinator;
  final AppDatabase db;

  bool _isSyncingInbox = false;
  String? _activeChannelId;

  /// Synchronizes the user's inbox list from Supabase into Drift.
  Future<void> syncInbox(String currentUserId) async {
    if (_isSyncingInbox) return;
    _isSyncingInbox = true;

    try {
      final dtos = await remote.listMyChats();
      await local.upsertChannelsFromDto(dtos, currentUserId);
    } catch (e, st) {
      debugPrint('[ChatSyncCoordinator] Error syncing inbox: $e\n$st');
    } finally {
      _isSyncingInbox = false;
    }
  }

  /// Open-channel sequence (Spec §8.1 & §12):
  /// 1. Drift already streams to UI (0ms instant cold paint).
  /// 2. Subscribe to Ably `chat:<channelId>`.
  /// 3. Synchronize channel deltas via common CatchUpScheduler primitive.
  /// 4. Drain pending outbox operations.
  Future<void> openChannel(String channelId, String currentUserId) async {
    _activeChannelId = channelId;

    try {
      // 1. Subscribe to Ably real-time channel
      ingestor.subscribeToChannel(channelId, currentUserId);

      // 2. Synchronize forward via common primitive (Spec §12)
      await catchUpScheduler.syncChannel(channelId, currentUserId);

      // 3. Drain any pending outbox sends
      await outbox.drain();
    } catch (e, st) {
      debugPrint('[ChatSyncCoordinator] Error in openChannel: $e\n$st');
    }
  }

  /// Closes channel subscription to free Ably CCU.
  void closeChannel(String channelId) {
    if (_activeChannelId == channelId) {
      _activeChannelId = null;
    }
    ingestor.unsubscribeFromChannel(channelId);
  }

  /// Loads older message history before oldest cached seq (Spec §22).
  Future<int> loadOlderMessages(String channelId, String currentUserId) {
    return catchUpScheduler.loadOlderMessages(channelId, currentUserId);
  }
}
