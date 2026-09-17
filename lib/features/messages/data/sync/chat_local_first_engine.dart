import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../../../core/realtime/ably_service.dart';
import '../datasources/chat_local_data_source.dart';
import '../datasources/chat_remote_data_source.dart';
import 'catch_up_scheduler.dart';
import 'outbox_processor.dart';
import 'realtime_ingestor.dart';

/// Application-scoped coordinator managing the local-first chat runtime (Spec §8, §9, §16, §17, §28).
///
/// Ensures single-flight reconciliation, durable Outbox recovery, proactive background
/// catch-up, and clean multi-user session boundaries.
class ChatLocalFirstEngine {
  ChatLocalFirstEngine({
    required this.local,
    required this.remote,
    required this.outbox,
    required this.ingestor,
    required this.catchUp,
    this.ablyService,
  }) {
    ablyService?.addResumeListener(_onResume);
  }

  final ChatLocalDataSource local;
  final ChatRemoteDataSource remote;
  final OutboxProcessor outbox;
  final RealtimeIngestor ingestor;
  final CatchUpScheduler catchUp;
  final AblyService? ablyService;

  String? _activeUserId;
  int _sessionGeneration = 0;
  bool _isReconciling = false;
  bool _reconciliationPending = false;
  bool _isDisposed = false;

  /// Returns the current active session user ID.
  String? get activeUserId => _activeUserId;

  /// Starts a session for [userId], attaching realtime subscription and reconciling (Spec §8).
  Future<void> startSession(String userId) async {
    if (_isDisposed) return;
    if (_activeUserId != null && _activeUserId != userId) {
      endSession();
    }
    _sessionGeneration++;
    _activeUserId = userId;
    catchUp.setSessionUser(userId);

    debugPrint('[ChatLocalFirstEngine] User signed in: $userId (generation $_sessionGeneration)');

    // Spec §8 Ordering note: Attach user-level realtime subscription BEFORE network reconciliation
    ingestor.subscribeToUserInbox(
      userId,
      onUpdated: () {
        // Realtime notification of activity on inbox
      },
    );

    await reconcile('user_signed_in');
  }

  /// Ends the active user session, unsubscribing from user inbox (Spec §28).
  void endSession() {
    debugPrint('[ChatLocalFirstEngine] User signed out (previous: $_activeUserId).');
    _sessionGeneration++;
    _activeUserId = null;
    catchUp.setSessionUser(null);
    ingestor.unsubscribeFromUserInbox();
    _reconciliationPending = false;
  }

  void _onResume() {
    debugPrint('[ChatLocalFirstEngine] App resumed into foreground.');
    unawaited(reconcile('app_resumed'));
  }

  /// Single-flight reconciliation pipeline (Spec §8, §16, §17).
  ///
  /// Collapses simultaneous triggers (e.g. auth + resume + connectivity return)
  /// into a single sequential pass.
  Future<void> reconcile(String reason) async {
    final userId = _activeUserId;
    if (userId == null || _isDisposed) return;

    if (_isReconciling) {
      _reconciliationPending = true;
      return;
    }

    _isReconciling = true;
    final currentGen = _sessionGeneration;

    try {
      do {
        _reconciliationPending = false;

        debugPrint('[ChatLocalFirstEngine] Starting reconciliation pass (reason: $reason, user: $userId)');

        // Step 1: Ensure user Ably subscription is active (Spec §8)
        ingestor.subscribeToUserInbox(userId);

        // Step 2: Recover stale processing operations left behind by crashes/kills (Spec §15)
        final recovered = await local.recoverStaleProcessingOperations();
        if (recovered > 0) {
          debugPrint('[ChatLocalFirstEngine] Recovered $recovered stale processing outbox operation(s).');
        }

        if (_sessionGeneration != currentGen) break;

        // Step 3: Synchronize inbox projection from Supabase list_my_chats (Spec §7)
        await syncInbox(userId);

        if (_sessionGeneration != currentGen) break;

        // Step 4: Proactively schedule background catch-up for conversations (Spec §4)
        await catchUp.run(userId);

        if (_sessionGeneration != currentGen) break;

        // Step 5: Drain pending Outbox operations (Spec §8, §16, §17)
        await outbox.drain();
      } while (_reconciliationPending && _sessionGeneration == currentGen && !_isDisposed);
    } catch (e, st) {
      debugPrint('[ChatLocalFirstEngine] Error during reconciliation: $e\n$st');
    } finally {
      _isReconciling = false;
    }
  }

  /// Synchronizes authoritative inbox channel projection from Supabase list_my_chats (Spec §7).
  Future<void> syncInbox(String currentUserId) async {
    try {
      final dtos = await remote.listMyChats();
      await local.upsertChannelsFromDto(dtos, currentUserId);
    } catch (e, st) {
      debugPrint('[ChatLocalFirstEngine] Error syncing inbox: $e\n$st');
    }
  }

  /// Disposes listeners and cleans up subscriptions.
  void dispose() {
    _isDisposed = true;
    _sessionGeneration++;
    ablyService?.removeResumeListener(_onResume);
    ingestor.unsubscribeFromUserInbox();
  }
}
