import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/database/app_database.dart';
import '../datasources/chat_local_data_source.dart';
import '../datasources/chat_remote_data_source.dart';
import 'catch_up_scheduler.dart';
import 'outbox_processor.dart';
import 'receipt_coordinator.dart';
import 'realtime_ingestor.dart';

/// Coordinates local cache, network reconciliation and live thread transport.
///
/// Realtime lifecycle ownership lives here rather than in presentation. The UI
/// opens a channel once and closes it once; changes to read receipts, inbox
/// metadata, participants or request state must not detach the transport.
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

  // Kept on the coordinator because existing tests/providers construct this
  // application service with the full chat runtime. Receipt work still happens
  // through CatchUpScheduler/RealtimeIngestor callbacks; the fields are not a
  // second execution path.
  final ReceiptCoordinator receiptCoordinator;
  final AppDatabase db;

  bool _isSyncingInbox = false;

  /// Channels currently owned by an open thread route.
  final Set<String> _openChannels = <String>{};

  /// Prevents two callers from concurrently performing the first Ably attach
  /// for the same channel. Without single-flight protection both callers can
  /// observe "not subscribed yet" and create competing subscriptions.
  final Map<String, Future<void>> _openChannelFlights =
      <String, Future<void>>{};

  /// Explicit inbox refresh. Errors deliberately propagate so the repository
  /// can return a Failure to pull-to-refresh instead of reporting false success.
  Future<void> syncInbox(String currentUserId) async {
    if (_isSyncingInbox) return;
    _isSyncingInbox = true;

    try {
      final channels = await remote.listMyChats();
      await local.upsertChannelsFromDto(channels, currentUserId);
    } catch (e, st) {
      debugPrint('[ChatSyncCoordinator] inbox sync failed: $e\n$st');
      rethrow;
    } finally {
      _isSyncingInbox = false;
    }
  }

  /// Opens a conversation using Drift as the immediate UI source.
  ///
  /// Presence policy is decided from LocalChannelMembers:
  /// - active membership  -> subscribe + enter Presence
  /// - pending DM request -> subscribe, but DO NOT enter Presence
  ///
  /// RealtimeIngestor still configures the Ably attachment with Presence mode
  /// in both cases. That is crucial: after the user accepts a request we can
  /// enter Presence on the existing attachment without detaching/re-attaching.
  Future<void> openChannel(
    String channelId,
    String currentUserId,
  ) {
    _openChannels.add(channelId);

    final existingFlight = _openChannelFlights[channelId];
    if (existingFlight != null) return existingFlight;

    final flight = _openChannelInternal(channelId, currentUserId);
    _openChannelFlights[channelId] = flight;

    return flight.whenComplete(() {
      if (identical(_openChannelFlights[channelId], flight)) {
        _openChannelFlights.remove(channelId);
      }
    });
  }

  Future<void> _openChannelInternal(
    String channelId,
    String currentUserId,
  ) async {
    try {
      // This state is local and immediate. An incoming request is normally
      // pending here, while an accepted/group/team channel is active.
      final enterPresence =
          await local.isActiveMembership(channelId, currentUserId);

      if (!_openChannels.contains(channelId)) return;

      await ingestor.subscribeToChannel(
        channelId,
        currentUserId,
        enterPresence: enterPresence,
      );

      // The route may have closed while Ably was attaching.
      if (!_openChannels.contains(channelId)) {
        await ingestor.unsubscribeFromChannel(channelId);
        return;
      }

      // Member/profile identity is stored in LocalChannelMembers. Identity
      // failure must never prevent messages from opening; initials/fallback
      // names remain available.
      try {
        final participants = await remote.fetchChannelParticipants(channelId);
        await local.upsertParticipants(
          participants,
          currentUserId: currentUserId,
        );
      } catch (e, st) {
        debugPrint(
          '[ChatSyncCoordinator] participant sync failed for $channelId: '
          '$e\n$st',
        );
      }

      if (!_openChannels.contains(channelId)) return;

      await catchUpScheduler.syncChannel(channelId, currentUserId);

      if (!_openChannels.contains(channelId)) return;

      await outbox.drain();
    } catch (e, st) {
      debugPrint(
        '[ChatSyncCoordinator] openChannel($channelId) failed: $e\n$st',
      );
    }
  }

  /// Called after the user explicitly accepts an incoming request while its
  /// thread is already open. This does NOT recreate the message subscription;
  /// it only enters/subscribes to Presence on the existing presence-capable
  /// Ably attachment.
  Future<void> enablePresenceForOpenChannel(String channelId) async {
    if (!_openChannels.contains(channelId)) return;

    try {
      await ingestor.enablePresence(channelId);
    } catch (e, st) {
      debugPrint(
        '[ChatSyncCoordinator] enablePresence($channelId) failed: $e\n$st',
      );
    }
  }

  void closeChannel(String channelId) {
    if (!_openChannels.remove(channelId)) return;

    // RealtimeIngestor serializes this against any in-flight first attach, so
    // a late detach cannot tear down a newly-created replacement subscription.
    unawaited(ingestor.unsubscribeFromChannel(channelId));
  }

  Future<int> loadOlderMessages(String channelId, String currentUserId) =>
      catchUpScheduler.loadOlderMessages(channelId, currentUserId);
}
