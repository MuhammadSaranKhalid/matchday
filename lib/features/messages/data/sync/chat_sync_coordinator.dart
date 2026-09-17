import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/realtime/ably_service.dart';
import '../datasources/chat_local_data_source.dart';
import '../datasources/chat_remote_data_source.dart';
import 'outbox_processor.dart';
import 'realtime_ingestor.dart';

/// Coordinates offline cache, network fetches, Ably subscriptions, and outbox draining.
class ChatSyncCoordinator {
  ChatSyncCoordinator({
    required this.local,
    required this.remote,
    required this.outbox,
    required this.ingestor,
    required this.db,
    this.ablyService,
  }) {
    ingestor.onMessageDelivered = (channelId, throughSeq) {
      unawaited(remote.markChannelDelivered(
        channelId: channelId,
        throughSeq: throughSeq,
      ));
    };

    ablyService?.addResumeListener(_onResume);
  }

  final ChatLocalDataSource local;
  final ChatRemoteDataSource remote;
  final OutboxProcessor outbox;
  final RealtimeIngestor ingestor;
  final AppDatabase db;
  final AblyService? ablyService;

  bool _isSyncingInbox = false;
  String? _activeChannelId;
  String? _activeUserId;

  void _onResume() {
    debugPrint('[ChatSyncCoordinator] App resumed; draining outbox and reconciling deltas.');
    outbox.drain();
    if (_activeUserId != null) {
      unawaited(syncInbox(_activeUserId!));
      if (_activeChannelId != null) {
        unawaited(openChannel(_activeChannelId!, _activeUserId!));
      }
    }
  }

  /// Synchronizes the user's inbox list from Supabase into Drift.
  Future<void> syncInbox(String currentUserId) async {
    _activeUserId = currentUserId;
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

  /// Open-channel sequence (Spec §8.1):
  /// 1. Drift already streams to UI (0ms instant cold paint).
  /// 2. Subscribe to Ably `chat:<channelId>`.
  /// 3. Fetch delta messages where `message_seq > newest_local_seq`.
  /// 4. Upsert deltas to Drift.
  /// 5. Advance delivered horizon for freshly received messages.
  /// 6. Drain pending outbox operations.
  Future<void> openChannel(String channelId, String currentUserId) async {
    _activeChannelId = channelId;
    _activeUserId = currentUserId;

    try {
      // 1. Subscribe to Ably real-time channel
      ingestor.subscribeToChannel(channelId, currentUserId);

      // 2. Determine highest synced messageSeq in Drift
      final latestLocalMsg = await (db.select(db.localMessages)
            ..where((m) =>
                m.channelId.equals(channelId) &
                m.messageSeq.isNotNull())
            ..orderBy([(m) => OrderingTerm.desc(m.messageSeq)])
            ..limit(1))
          .getSingleOrNull();

      final highestSeq = latestLocalMsg?.messageSeq ?? 0;

      // 3. Fetch deltas from network
      final deltas = await remote.fetchDeltaMessages(channelId, highestSeq);
      if (deltas.isNotEmpty) {
        await local.upsertMessagesFromDto(deltas, currentUserId);
      }

      // 4. Mark channel delivered (not read) up to current highest sequence in thread
      final currentHighest = await (db.select(db.localMessages)
            ..where((m) =>
                m.channelId.equals(channelId) &
                m.messageSeq.isNotNull())
            ..orderBy([(m) => OrderingTerm.desc(m.messageSeq)])
            ..limit(1))
          .getSingleOrNull();

      if (currentHighest?.messageSeq != null) {
        final seq = currentHighest!.messageSeq!;
        await local.updateMemberHorizons(
          channelId,
          currentUserId,
          deliveredSeq: seq,
        );
      }

      // 5. Drain any pending outbox sends
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

  /// Loads the next page of older message history before oldest cached seq.
  Future<int> loadOlderMessages(String channelId, String currentUserId) async {
    try {
      final oldestLocalMsg = await (db.select(db.localMessages)
            ..where((m) =>
                m.channelId.equals(channelId) &
                m.messageSeq.isNotNull())
            ..orderBy([(m) => OrderingTerm.asc(m.messageSeq)])
            ..limit(1))
          .getSingleOrNull();

      if (oldestLocalMsg == null || oldestLocalMsg.messageSeq == null) {
        return 0;
      }

      final olderDtos = await remote.fetchOlderMessages(
        channelId,
        oldestLocalMsg.messageSeq!,
        limit: 50,
      );

      if (olderDtos.isEmpty) {
        return 0;
      }

      await local.upsertMessagesFromDto(olderDtos, currentUserId);
      return olderDtos.length;
    } catch (e, st) {
      debugPrint('[ChatSyncCoordinator] Error loading older messages: $e\n$st');
      return 0;
    }
  }
}
