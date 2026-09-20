import 'dart:async';
import 'dart:convert';

import 'package:ably_flutter/ably_flutter.dart' as ably;
import 'package:flutter/foundation.dart';

import '../../../../core/realtime/ably_service.dart';
import '../datasources/chat_local_data_source.dart';
import '../models/chat_message_dto.dart';

/// Converts Ably events into the local Drift projection.
///
/// Lifecycle invariants:
/// 1. One message subscription per chat channel.
/// 2. The first attachment is explicitly configured with all channel modes
///    allowed by the token BEFORE subscribe() can implicitly attach it.
/// 3. A pending DM request may be attached in a Presence-capable mode without
///    actually entering Presence.
/// 4. Accepting that request only enters Presence; it does not rebuild the
///    message subscription.
/// 5. Close waits for an in-flight first attach before detaching, preventing a
///    stale async detach from tearing down a newer subscription.
class RealtimeIngestor {
  RealtimeIngestor(this._ablyService, this._local);

  final AblyService _ablyService;
  final ChatLocalDataSource _local;

  final Map<String, ably.RealtimeChannel> _channelsById = {};
  final Map<String, StreamSubscription<ably.Message>> _channelSubscriptions = {};
  final Map<String, Future<void>> _channelSubscribeFlights = {};
  final Set<String> _desiredChannels = {};

  final Map<String, StreamSubscription<ably.PresenceMessage>>
      _presenceSubscriptions = {};
  final Map<String, Future<void>> _presenceEnableFlights = {};
  final Set<String> _presenceEnabledChannels = {};
  final Map<String, StreamController<Set<String>>> _presenceControllers = {};
  final Map<String, Set<String>> _onlineUsersByChannel = {};

  // Typing is per-user, not a channel boolean. This prevents one person
  // stopping from incorrectly clearing another person's typing indicator.
  final Map<String, StreamController<Set<String>>> _typingControllers = {};
  final Map<String, Set<String>> _typingUsersByChannel = {};
  final Map<String, Map<String, Timer>> _typingTimers = {};

  StreamSubscription<ably.Message>? _userInboxSubscription;
  String? _subscribedUserId;

  VoidCallback? onInboxUpdated;
  void Function(String channelId, int throughSeq)? onMessageDelivered;
  void Function(String channelId)? onTargetedCatchUpRequested;

  void subscribeToUserInbox(String userId, {VoidCallback? onUpdated}) {
    if (_subscribedUserId == userId && _userInboxSubscription != null) return;
    if (_subscribedUserId != null && _subscribedUserId != userId) {
      unsubscribeFromUserInbox();
    }

    _subscribedUserId = userId;
    if (onUpdated != null) onInboxUpdated = onUpdated;

    try {
      final channel = _ablyService.getChannel('user:$userId:chat');
      _userInboxSubscription = channel.subscribe().listen(
        (event) async {
          try {
            final data = _parseData(event.data);
            final eventName = event.name ?? data['type'] as String?;
            if (eventName == 'channel.updated') {
              final inner = data['data'] is Map
                  ? _deepCastMap(data['data'] as Map)
                  : data;
              final channelId =
                  (data['channel_id'] ?? inner['channel_id']) as String?;
              final seq = (inner['last_message_seq'] ?? data['last_message_seq'])
                  as int?;
              if (channelId != null && seq != null) {
                final date =
                    (inner['created_at'] ?? data['created_at']) as String?;
                final updated = await _local.updateChannelSummaryFromRealtime(
                  channelId: channelId,
                  lastMessageSeq: seq,
                  lastMessageAt: date == null
                      ? DateTime.now().toUtc()
                      : DateTime.tryParse(date) ?? DateTime.now().toUtc(),
                  bodyPreview:
                      (inner['body_preview'] ?? inner['body']) as String?,
                  senderId: inner['sender_id'] as String?,
                  senderDisplayName: inner['sender_display_name'] as String?,
                  currentUserId: userId,
                  unreadCount: (inner['unread_count'] as num?)?.toInt(),
                  countsAsUnread: inner['counts_as_unread'] as bool?,
                );
                if (updated) onTargetedCatchUpRequested?.call(channelId);
              }
            }
          } catch (e, st) {
            debugPrint('[RealtimeIngestor] inbox event failed: $e\n$st');
          }
          onInboxUpdated?.call();
        },
        onError: (Object e) =>
            debugPrint('[RealtimeIngestor] inbox stream error: $e'),
      );
    } catch (e) {
      debugPrint('[RealtimeIngestor] inbox subscribe failed: $e');
    }
  }

  void unsubscribeFromUserInbox() {
    _userInboxSubscription?.cancel();
    _userInboxSubscription = null;
    final userId = _subscribedUserId;
    _subscribedUserId = null;
    if (userId != null) {
      unawaited(_ablyService.releaseChannel('user:$userId:chat'));
    }
  }

  /// Creates exactly one message subscription for a chat channel.
  ///
  /// [enterPresence] controls whether this client becomes visible in Presence;
  /// it does NOT control the channel attachment modes. Even a request preview
  /// is attached as Presence-capable so a later Accept can enter Presence
  /// without a detach/re-attach cycle.
  Future<void> subscribeToChannel(
    String channelId,
    String currentUserId, {
    bool enterPresence = true,
  }) async {
    _desiredChannels.add(channelId);

    if (_channelSubscriptions.containsKey(channelId)) {
      if (enterPresence) await enablePresence(channelId);
      return;
    }

    final existingFlight = _channelSubscribeFlights[channelId];
    if (existingFlight != null) {
      await existingFlight;
      if (enterPresence && _desiredChannels.contains(channelId)) {
        await enablePresence(channelId);
      }
      return;
    }

    final flight = _subscribeToChannelInternal(channelId, currentUserId);
    _channelSubscribeFlights[channelId] = flight;

    try {
      await flight;
      if (enterPresence && _desiredChannels.contains(channelId)) {
        await enablePresence(channelId);
      }
    } finally {
      if (identical(_channelSubscribeFlights[channelId], flight)) {
        _channelSubscribeFlights.remove(channelId);
      }
    }
  }

  Future<void> _subscribeToChannelInternal(
    String channelId,
    String currentUserId,
  ) async {
    final channelName = 'chat:$channelId';

    try {
      final channel = _ablyService.getChannel(channelName);
      _channelsById[channelId] = channel;

      // Ably channel modes are fixed at attachment time. subscribe() can cause
      // an implicit attach, so configure modes FIRST. ChannelMode.values is
      // intentionally used instead of hard-coding enum members: Ably assigns
      // the intersection between requested modes and the token capabilities.
      // Your ably-auth token already limits chat:<id> to subscribe/publish/
      // presence, so this cannot grant capabilities the token does not have.
      await channel.setOptions(
        const ably.RealtimeChannelOptions(
          modes: ably.ChannelMode.values,
        ),
      );

      if (!_desiredChannels.contains(channelId)) return;

      _channelSubscriptions[channelId] = channel.subscribe().listen(
        (event) => _handleChannelMessage(channelId, currentUserId, event),
        onError: (Object e) => debugPrint(
          '[RealtimeIngestor] channel $channelId error: $e',
        ),
      );
    } catch (e, st) {
      debugPrint(
        '[RealtimeIngestor] subscribe $channelId failed: $e\n$st',
      );
      rethrow;
    }
  }

  /// Enters and subscribes to Presence on an already-open chat channel.
  ///
  /// This is safe after a request is accepted because subscribeToChannel()
  /// configured the original Ably attachment with Presence mode before the
  /// first message subscription.
  Future<void> enablePresence(String channelId) async {
    if (_presenceEnabledChannels.contains(channelId)) return;
    if (!_desiredChannels.contains(channelId)) return;
    if (!_channelSubscriptions.containsKey(channelId)) return;

    final existingFlight = _presenceEnableFlights[channelId];
    if (existingFlight != null) {
      await existingFlight;
      return;
    }

    final channel = _channelsById[channelId];
    if (channel == null) return;

    final flight = _enablePresenceInternal(channelId, channel);
    _presenceEnableFlights[channelId] = flight;

    try {
      await flight;
    } finally {
      if (identical(_presenceEnableFlights[channelId], flight)) {
        _presenceEnableFlights.remove(channelId);
      }
    }
  }

  Future<void> _enablePresenceInternal(
    String channelId,
    ably.RealtimeChannel channel,
  ) async {
    final controller = _presenceControllers.putIfAbsent(
      channelId,
      () => StreamController<Set<String>>.broadcast(),
    );
    final online = _onlineUsersByChannel.putIfAbsent(
      channelId,
      () => <String>{},
    );

    // Subscribe to presence events only once. The attachment is already
    // Presence-capable, so this does not need to rebuild the message stream.
    _presenceSubscriptions[channelId] ??=
        channel.presence.subscribe().listen(
      (event) {
        final id = event.clientId;
        if (id == null || id.isEmpty) return;

        switch (event.action) {
          case ably.PresenceAction.enter:
          case ably.PresenceAction.present:
          case ably.PresenceAction.update:
            online.add(id);
            break;
          case ably.PresenceAction.leave:
            online.remove(id);
            break;
          default:
            break;
        }

        if (!controller.isClosed) {
          controller.add(Set<String>.from(online));
        }
      },
      onError: (Object e) =>
          debugPrint('[RealtimeIngestor] presence stream failed: $e'),
    );

    try {
      await channel.presence.enter({'status': 'online'});

      // The screen may have closed while enter() was awaiting the network.
      if (!_desiredChannels.contains(channelId)) {
        try {
          await channel.presence.leave();
        } catch (_) {}
        return;
      }

      final members = await channel.presence.get();
      online.clear();
      for (final member in members) {
        final id = member.clientId;
        if (id != null && id.isNotEmpty) online.add(id);
      }

      _presenceEnabledChannels.add(channelId);

      if (!controller.isClosed) {
        controller.add(Set<String>.from(online));
      }
    } catch (e) {
      _presenceEnabledChannels.remove(channelId);
      debugPrint('[RealtimeIngestor] presence enter failed: $e');
    }
  }

  /// Tears down a channel exactly once.
  ///
  /// If first attachment is still in flight, wait for it before cancelling and
  /// detaching. This removes the old race where an async release from a stale
  /// provider build could detach a newly-created subscription.
  Future<void> unsubscribeFromChannel(String channelId) async {
    _desiredChannels.remove(channelId);

    final subscribeFlight = _channelSubscribeFlights[channelId];
    if (subscribeFlight != null) {
      try {
        await subscribeFlight;
      } catch (_) {
        // Cleanup still needs to continue after a failed attach.
      }
    }

    final presenceFlight = _presenceEnableFlights[channelId];
    if (presenceFlight != null) {
      try {
        await presenceFlight;
      } catch (_) {}
    }

    await _channelSubscriptions.remove(channelId)?.cancel();
    await _presenceSubscriptions.remove(channelId)?.cancel();

    final channel = _channelsById.remove(channelId);
    final hadPresence = _presenceEnabledChannels.remove(channelId);

    if (hadPresence && channel != null) {
      try {
        await channel.presence.leave();
      } catch (e) {
        // Leaving a channel that disconnected between the state check and the
        // network call is non-fatal. Detach below is still the final cleanup.
        debugPrint('[RealtimeIngestor] leave presence skipped/failed: $e');
      }
    }

    _onlineUsersByChannel.remove(channelId);
    final presenceController = _presenceControllers.remove(channelId);
    if (presenceController != null && !presenceController.isClosed) {
      await presenceController.close();
    }

    final timers = _typingTimers.remove(channelId);
    for (final timer in timers?.values ?? const <Timer>[]) {
      timer.cancel();
    }
    _typingUsersByChannel.remove(channelId);
    final typingController = _typingControllers.remove(channelId);
    if (typingController != null && !typingController.isClosed) {
      await typingController.close();
    }

    // releaseChannel owns the actual Ably detach and active-channel bookkeeping.
    await _ablyService.releaseChannel('chat:$channelId');
  }

  Stream<Set<String>> watchPresence(String channelId) {
    final controller = _presenceControllers.putIfAbsent(
      channelId,
      () => StreamController<Set<String>>.broadcast(),
    );
    scheduleMicrotask(() {
      if (!controller.isClosed) {
        controller.add(
          Set<String>.from(_onlineUsersByChannel[channelId] ?? const {}),
        );
      }
    });
    return controller.stream;
  }

  Stream<Set<String>> watchTypingUsers(String channelId) {
    final controller = _typingControllers.putIfAbsent(
      channelId,
      () => StreamController<Set<String>>.broadcast(),
    );
    scheduleMicrotask(() {
      if (!controller.isClosed) {
        controller.add(
          Set<String>.from(_typingUsersByChannel[channelId] ?? const {}),
        );
      }
    });
    return controller.stream;
  }

  Future<void> publishTyping(
    String channelId,
    String currentUserId,
    bool isTyping,
  ) async {
    // Typing is only meaningful for an already-open thread. Do not create a
    // new Ably channel merely because a delayed composer timer fired after the
    // screen closed.
    final channel = _channelsById[channelId];
    if (channel == null || !_desiredChannels.contains(channelId)) return;

    try {
      await channel.publish(
        name: 'typing',
        data: jsonEncode({
          'user_id': currentUserId,
          'is_typing': isTyping,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        }),
      );
    } catch (e) {
      debugPrint('[RealtimeIngestor] typing publish failed: $e');
    }
  }

  Future<void> _handleChannelMessage(
    String channelId,
    String currentUserId,
    ably.Message event,
  ) async {
    try {
      final data = _parseData(event.data);
      final eventName = event.name ??
          data['event_type'] as String? ??
          data['type'] as String?;

      switch (eventName) {
        case 'message.created':
          final dto = ChatMessageDto.fromJson(_extractMessagePayload(data));
          final existing = await _local.getMessage(dto.messageId);
          if (existing != null && existing.version >= dto.version) break;

          if (dto.senderId == currentUserId && existing != null) {
            await _local.updateMessageSyncStatus(
              dto.messageId,
              syncStatus: 'sent',
              messageSeq: dto.messageSeq,
              version: dto.version,
            );
            break;
          }

          await _local.upsertMessagesFromDto([dto], currentUserId);
          if (dto.senderId != currentUserId && dto.messageSeq != null) {
            // Pending DM request recipients may preview the request message,
            // but that preview is not an accepted-chat delivered receipt.
            if (await _local.isActiveMembership(channelId, currentUserId)) {
              await _local.updateMemberHorizons(
                channelId,
                currentUserId,
                deliveredSeq: dto.messageSeq,
              );
              onMessageDelivered?.call(channelId, dto.messageSeq!);
            }
          }
          break;

        case 'message.edited':
          final dto = ChatMessageDto.fromJson(_extractMessagePayload(data));
          final existing = await _local.getMessage(dto.messageId);
          if (existing != null && existing.version >= dto.version) break;
          await _local.upsertMessagesFromDto([dto], currentUserId);
          break;

        case 'message.deleted':
          final payload = _extractMessagePayload(data);
          final messageId = payload['message_id'] as String? ??
              data['entity_id'] as String?;
          final version = (payload['version'] as num?)?.toInt() ??
              (data['entity_version'] as num?)?.toInt();
          if (messageId != null) {
            final existing = await _local.getMessage(messageId);
            if (existing != null &&
                version != null &&
                existing.version > version) {
              break;
            }
            await _local.softDeleteMessageLocally(messageId, version: version);
          }
          break;

        case 'horizon.read':
        case 'receipt.read':
          final payload = _extractMessagePayload(data);
          final userId = payload['user_id'] as String? ??
              data['entity_id'] as String?;
          final seq = (payload['through_seq'] ??
                  payload['through_message_seq']) as int?;
          if (userId != null && seq != null) {
            await _local.updateMemberHorizons(channelId, userId, readSeq: seq);
          }
          break;

        case 'horizon.delivered':
        case 'receipt.delivered':
          final payload = _extractMessagePayload(data);
          final userId = payload['user_id'] as String? ??
              data['entity_id'] as String?;
          final seq = (payload['through_seq'] ??
                  payload['through_message_seq']) as int?;
          if (userId != null && seq != null) {
            await _local.updateMemberHorizons(
              channelId,
              userId,
              deliveredSeq: seq,
            );
          }
          break;

        case 'reaction.updated':
          final payload = _extractMessagePayload(data);
          final messageId = payload['message_id'] as String? ??
              data['entity_id'] as String?;
          final userId = payload['user_id'] as String?;
          final reaction = payload['reaction'] as String?;
          final removed = payload['is_removed'] as bool? ?? false;
          final rawTime = payload['created_at'] as String? ??
              payload['occurred_at'] as String?;
          final time = rawTime == null
              ? DateTime.now().toUtc()
              : DateTime.tryParse(rawTime) ?? DateTime.now().toUtc();
          if (messageId != null && userId != null && reaction != null) {
            await _local.upsertReaction(
              messageId: messageId,
              userId: userId,
              reaction: reaction,
              createdAt: time,
              removedAt: removed ? time : null,
            );
          }
          break;

        case 'typing':
          _applyTypingEvent(channelId, currentUserId, data);
          break;

        default:
          debugPrint('[RealtimeIngestor] unhandled event: $eventName');
      }
    } catch (e, st) {
      debugPrint('[RealtimeIngestor] event handling failed: $e\n$st');
    }
  }

  void _applyTypingEvent(
    String channelId,
    String currentUserId,
    Map<String, dynamic> envelope,
  ) {
    final payload = _extractMessagePayload(envelope);
    final userId = payload['user_id'] as String?;
    final isTyping = payload['is_typing'] as bool? ?? false;
    if (userId == null || userId == currentUserId) return;

    final users = _typingUsersByChannel.putIfAbsent(
      channelId,
      () => <String>{},
    );
    final timers = _typingTimers.putIfAbsent(
      channelId,
      () => <String, Timer>{},
    );
    timers[userId]?.cancel();

    if (isTyping) {
      users.add(userId);
      timers[userId] = Timer(const Duration(seconds: 3), () {
        users.remove(userId);
        timers.remove(userId);
        _emitTyping(channelId);
      });
    } else {
      users.remove(userId);
      timers.remove(userId);
    }
    _emitTyping(channelId);
  }

  void _emitTyping(String channelId) {
    final controller = _typingControllers[channelId];
    if (controller != null && !controller.isClosed) {
      controller.add(
        Set<String>.from(_typingUsersByChannel[channelId] ?? const {}),
      );
    }
  }

  Map<String, dynamic> _extractMessagePayload(Map<String, dynamic> envelope) {
    final payload = envelope['data'] is Map
        ? _deepCastMap(envelope['data'] as Map)
        : envelope['message'] is Map
            ? _deepCastMap(envelope['message'] as Map)
            : _deepCastMap(envelope);

    payload['message_id'] ??= envelope['entity_id'];
    payload['channel_id'] ??= envelope['channel_id'];
    payload['created_at'] ??= envelope['occurred_at'];
    return payload;
  }

  Map<String, dynamic> _parseData(Object? raw) {
    if (raw is Map) return _deepCastMap(raw);
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) return _deepCastMap(decoded);
      } catch (_) {}
    }
    return {};
  }

  Map<String, dynamic> _deepCastMap(Map<dynamic, dynamic> raw) =>
      raw.map<String, dynamic>(
        (key, value) => MapEntry(
          key.toString(),
          value is Map
              ? _deepCastMap(value)
              : value is List
                  ? value
                      .map((e) => e is Map ? _deepCastMap(e) : e)
                      .toList()
                  : value,
        ),
      );

  void dispose() {
    unsubscribeFromUserInbox();

    // Provider disposal cannot await, so serialize async channel cleanup in the
    // background. Each channel cleanup is internally safe against in-flight
    // first attach / Presence-enter operations.
    for (final channelId in <String>{
      ..._desiredChannels,
      ..._channelsById.keys,
      ..._channelSubscriptions.keys,
    }) {
      unawaited(unsubscribeFromChannel(channelId));
    }

    // Controllers that were watched before a channel ever opened are not part
    // of the sets above; close those leftovers here.
    for (final entry in _presenceControllers.entries.toList()) {
      if (!_channelsById.containsKey(entry.key) && !entry.value.isClosed) {
        unawaited(entry.value.close());
      }
    }
    for (final entry in _typingControllers.entries.toList()) {
      if (!_channelsById.containsKey(entry.key) && !entry.value.isClosed) {
        unawaited(entry.value.close());
      }
    }

    for (final channelTimers in _typingTimers.values) {
      for (final timer in channelTimers.values) {
        timer.cancel();
      }
    }
  }
}
