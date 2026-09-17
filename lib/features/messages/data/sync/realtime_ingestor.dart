import 'dart:async';
import 'dart:convert';

import 'package:ably_flutter/ably_flutter.dart' as ably;
import 'package:flutter/foundation.dart';

import '../../../../core/realtime/ably_service.dart';
import '../datasources/chat_local_data_source.dart';
import '../models/chat_message_dto.dart';

/// Ingests real-time events from Ably into the local Drift database per Spec §5 & §8.
class RealtimeIngestor {
  RealtimeIngestor(this._ablyService, this._local);

  final AblyService _ablyService;
  final ChatLocalDataSource _local;

  final Map<String, StreamSubscription<ably.Message>> _channelSubscriptions =
      {};
  final Map<String, StreamSubscription<ably.PresenceMessage>>
      _presenceSubscriptions = {};
  final Map<String, StreamController<Set<String>>> _presenceControllers = {};
  final Map<String, Set<String>> _onlineUsersByChannel = {};
  final Map<String, StreamController<bool>> _typingControllers = {};
  final Map<String, Timer> _typingTimers = {};
  StreamSubscription<ably.Message>? _userInboxSubscription;

  String? _subscribedUserId;
  VoidCallback? onInboxUpdated;
  void Function(String channelId, int throughSeq)? onMessageDelivered;
  void Function(String channelId)? onTargetedCatchUpRequested;

  /// Subscribes to the user's private inbox channel `user:<userId>:chat`.
  void subscribeToUserInbox(String userId, {VoidCallback? onUpdated}) {
    if (_subscribedUserId == userId && _userInboxSubscription != null) return;
    if (_subscribedUserId != null && _subscribedUserId != userId) {
      unsubscribeFromUserInbox();
    }
    _subscribedUserId = userId;
    if (onUpdated != null) onInboxUpdated = onUpdated;

    try {
      final channelName = 'user:$userId:chat';
      final channel = _ablyService.getChannel(channelName);
      _userInboxSubscription = channel.subscribe().listen(
        (ably.Message msg) async {
          debugPrint('[RealtimeIngestor] Received inbox event: ${msg.name}');
          try {
            final data = _parseData(msg.data);
            final eventName = msg.name ?? data['type'] as String?;
            if (eventName == 'channel.updated') {
              final innerData = data['data'] as Map<String, dynamic>? ?? data;
              final channelId = (data['channel_id'] ?? innerData['channel_id']) as String?;
              final seq = (innerData['last_message_seq'] ?? data['last_message_seq']) as int?;
              final dateStr = (innerData['created_at'] ?? data['created_at']) as String?;
              final senderId = (innerData['sender_id']) as String?;
              final senderName = (innerData['sender_display_name']) as String?;
              final preview = (innerData['body_preview'] ?? innerData['body']) as String?;
              final unreadCount = (innerData['unread_count']) as int?;
              final countsAsUnread = (innerData['counts_as_unread']) as bool?;

              if (channelId != null && seq != null) {
                final createdAt = dateStr != null
                    ? DateTime.tryParse(dateStr) ?? DateTime.now().toUtc()
                    : DateTime.now().toUtc();
                final updated = await _local.updateChannelSummaryFromRealtime(
                  channelId: channelId,
                  lastMessageSeq: seq,
                  lastMessageAt: createdAt,
                  bodyPreview: preview,
                  senderId: senderId,
                  senderDisplayName: senderName,
                  currentUserId: userId,
                  unreadCount: unreadCount,
                  countsAsUnread: countsAsUnread,
                );

                // Targeted catch-up for missing deltas (Spec §10, §11)
                if (updated) {
                  onTargetedCatchUpRequested?.call(channelId);
                }
              }
            }
          } catch (e) {
            debugPrint('[RealtimeIngestor] Error processing user inbox event: $e');
          }
          onInboxUpdated?.call();
        },
        onError: (Object e) {
          debugPrint('[RealtimeIngestor] Error on inbox stream: $e');
        },
      );
    } catch (e) {
      debugPrint('[RealtimeIngestor] Failed to subscribe to user inbox: $e');
    }
  }

  /// Unsubscribes from the user inbox channel and releases Ably channel resource.
  void unsubscribeFromUserInbox() {
    _userInboxSubscription?.cancel();
    _userInboxSubscription = null;
    if (_subscribedUserId != null) {
      _ablyService.releaseChannel('user:$_subscribedUserId:chat');
      _subscribedUserId = null;
    }
  }

  /// Subscribes to a channel's hot message stream and presence set `chat:<channelId>`.
  void subscribeToChannel(String channelId, String currentUserId) {
    if (_channelSubscriptions.containsKey(channelId)) return;

    try {
      final channelName = 'chat:$channelId';
      final channel = _ablyService.getChannel(channelName);

      final sub = channel.subscribe().listen(
        (ably.Message msg) async {
          await _handleChannelMessage(channelId, currentUserId, msg);
        },
        onError: (Object e) {
          debugPrint(
            '[RealtimeIngestor] Error on channel $channelId stream: $e',
          );
        },
      );

      _channelSubscriptions[channelId] = sub;

      // ─── Presence Management ───
      final presenceController = _presenceControllers.putIfAbsent(
        channelId,
        () => StreamController<Set<String>>.broadcast(),
      );
      final onlineSet =
          _onlineUsersByChannel.putIfAbsent(channelId, () => <String>{});

      // Announce entering presence and load initial active members
      unawaited(() async {
        try {
          await channel.presence.enter({'status': 'online'});
          final members = await channel.presence.get();
          for (final m in members) {
            if (m.clientId != null && m.clientId!.isNotEmpty) {
              onlineSet.add(m.clientId!);
            }
          }
          if (!presenceController.isClosed) {
            presenceController.add(Set<String>.from(onlineSet));
          }
        } catch (e) {
          debugPrint(
            '[RealtimeIngestor] Error entering/getting presence for $channelId: $e',
          );
        }
      }());

      // Listen for presence member transitions (enter, leave, present, update)
      final presenceSub = channel.presence.subscribe().listen(
        (ably.PresenceMessage msg) {
          final clientId = msg.clientId;
          if (clientId == null || clientId.isEmpty) return;

          switch (msg.action) {
            case ably.PresenceAction.enter:
            case ably.PresenceAction.present:
            case ably.PresenceAction.update:
              onlineSet.add(clientId);
              break;
            case ably.PresenceAction.leave:
              onlineSet.remove(clientId);
              break;
            default:
              break;
          }

          if (!presenceController.isClosed) {
            presenceController.add(Set<String>.from(onlineSet));
          }
        },
        onError: (Object e) {
          debugPrint(
            '[RealtimeIngestor] Error on presence stream for $channelId: $e',
          );
        },
      );
      _presenceSubscriptions[channelId] = presenceSub;
    } catch (e) {
      debugPrint(
        '[RealtimeIngestor] Failed to subscribe to channel $channelId: $e',
      );
    }
  }

  /// Unsubscribes from a channel when the user navigates away.
  void unsubscribeFromChannel(String channelId) {
    final sub = _channelSubscriptions.remove(channelId);
    sub?.cancel();

    final presenceSub = _presenceSubscriptions.remove(channelId);
    presenceSub?.cancel();

    unawaited(() async {
      try {
        final channelName = 'chat:$channelId';
        final channel = _ablyService.getChannel(channelName);
        await channel.presence.leave();
      } catch (e) {
        debugPrint(
          '[RealtimeIngestor] Error leaving presence for $channelId: $e',
        );
      } finally {
        await _ablyService.releaseChannel('chat:$channelId');
      }
    }());

    _onlineUsersByChannel.remove(channelId);
    _presenceControllers[channelId]?.close();
    _presenceControllers.remove(channelId);

    _typingTimers[channelId]?.cancel();
    _typingTimers.remove(channelId);
    _typingControllers[channelId]?.close();
    _typingControllers.remove(channelId);
  }

  /// Returns a stream of present (online) client IDs for [channelId].
  Stream<Set<String>> watchPresence(String channelId) {
    final controller = _presenceControllers.putIfAbsent(
      channelId,
      () => StreamController<Set<String>>.broadcast(),
    );
    final current = _onlineUsersByChannel[channelId];
    if (current != null && current.isNotEmpty) {
      scheduleMicrotask(() {
        if (!controller.isClosed) {
          controller.add(Set<String>.from(current));
        }
      });
    }
    return controller.stream;
  }

  /// Returns a stream of typing indicator booleans for [channelId].
  Stream<bool> watchTyping(String channelId) {
    return _typingControllers
        .putIfAbsent(channelId, () => StreamController<bool>.broadcast())
        .stream;
  }


  /// Publishes typing status for [currentUserId] on channel `chat:<channelId>`.
  Future<void> publishTyping(
    String channelId,
    String currentUserId,
    bool isTyping,
  ) async {
    try {
      final channelName = 'chat:$channelId';
      final channel = _ablyService.getChannel(channelName);
      await channel.publish(
        name: 'typing',
        data: jsonEncode({
          'user_id': currentUserId,
          'is_typing': isTyping,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        }),
      );
    } catch (e) {
      debugPrint('[RealtimeIngestor] Error publishing typing: $e');
    }
  }

  Future<void> _handleChannelMessage(
    String channelId,
    String currentUserId,
    ably.Message msg,
  ) async {
    try {
      debugPrint('[RealtimeIngestor] Received message: $msg');
      final data = _parseData(msg.data);
      final eventName =
          msg.name ?? data['event_type'] as String? ?? data['type'] as String?;

      switch (eventName) {
        case 'message.created':
          final msgData = _extractMessagePayload(data);
          final dto = ChatMessageDto.fromJson(msgData);
          final existingCreated = await _local.getMessage(dto.messageId);
          if (existingCreated != null && existingCreated.version >= dto.version) {
            // Stale or duplicate created event (e.g. already edited or deleted locally)
            break;
          }
          if (dto.senderId == currentUserId) {
            if (existingCreated != null) {
              await _local.updateMessageSyncStatus(
                dto.messageId,
                syncStatus: 'sent',
                messageSeq: dto.messageSeq,
                version: dto.version,
              );
              break;
            }
          }
          await _local.upsertMessagesFromDto([dto], currentUserId);
          if (dto.senderId != currentUserId && dto.messageSeq != null) {
            await _local.updateMemberHorizons(
              channelId,
              currentUserId,
              deliveredSeq: dto.messageSeq,
            );
            onMessageDelivered?.call(channelId, dto.messageSeq!);
          }
          break;

        case 'message.edited':
          final msgData = _extractMessagePayload(data);
          final dto = ChatMessageDto.fromJson(msgData);
          final existing = await _local.getMessage(dto.messageId);
          if (existing != null && existing.version >= dto.version) {
            // Drop stale or out-of-order edit event (Spec §30)
            break;
          }
          await _local.upsertMessagesFromDto([dto], currentUserId);
          break;

        case 'message.deleted':
          final payload = _extractMessagePayload(data);
          final messageId =
              payload['message_id'] as String? ?? data['entity_id'] as String?;
          final version = (payload['version'] as num?)?.toInt() ??
              (data['entity_version'] as num?)?.toInt();
          if (messageId != null) {
            final existing = await _local.getMessage(messageId);
            if (existing != null && version != null && existing.version > version) {
              // Stale delete event
              break;
            }
            await _local.softDeleteMessageLocally(messageId, version: version);
          }
          break;

        case 'horizon.read':
        case 'receipt.read':
          final payload = _extractMessagePayload(data);
          final userId =
              payload['user_id'] as String? ?? data['entity_id'] as String?;
          final throughSeq =
              (payload['through_seq'] ?? payload['through_message_seq'])
                  as int?;
          if (userId != null && throughSeq != null) {
            await _local.updateMemberHorizons(
              channelId,
              userId,
              readSeq: throughSeq,
            );
          }
          break;

        case 'horizon.delivered':
        case 'receipt.delivered':
          final payload = _extractMessagePayload(data);
          final userId =
              payload['user_id'] as String? ?? data['entity_id'] as String?;
          final throughSeq =
              (payload['through_seq'] ?? payload['through_message_seq'])
                  as int?;
          if (userId != null && throughSeq != null) {
            await _local.updateMemberHorizons(
              channelId,
              userId,
              deliveredSeq: throughSeq,
            );
          }
          break;

        case 'reaction.updated':
          final payload = _extractMessagePayload(data);
          final messageId = payload['message_id'] as String? ??
              data['entity_id'] as String?;
          final userId = payload['user_id'] as String?;
          final reaction = payload['reaction'] as String?;
          final isRemoved = payload['is_removed'] as bool? ?? false;
          final createdAtStr = payload['created_at'] as String? ??
              payload['occurred_at'] as String?;
          final createdAt = createdAtStr != null
              ? DateTime.tryParse(createdAtStr) ?? DateTime.now().toUtc()
              : DateTime.now().toUtc();

          if (messageId != null && userId != null && reaction != null) {
            await _local.upsertReaction(
              messageId: messageId,
              userId: userId,
              reaction: reaction,
              createdAt: createdAt,
              removedAt: isRemoved ? DateTime.now().toUtc() : null,
            );
          }
          break;

        case 'typing':
          final payload = _extractMessagePayload(data);
          final userId = payload['user_id'] as String?;
          final isTyping = payload['is_typing'] as bool? ?? false;
          if (userId != null && userId != currentUserId) {
            final controller = _typingControllers[channelId];
            if (controller != null && !controller.isClosed) {
              controller.add(isTyping);
              _typingTimers[channelId]?.cancel();
              if (isTyping) {
                // Auto-decay after 3 seconds
                _typingTimers[channelId] = Timer(
                  const Duration(seconds: 3),
                  () {
                    if (!controller.isClosed) {
                      controller.add(false);
                    }
                  },
                );
              }
            }
          }
          break;

        default:
          debugPrint('[RealtimeIngestor] Unhandled event: $eventName');
      }
    } catch (e, st) {
      debugPrint('[RealtimeIngestor] Error handling realtime message: $e\n$st');
    }
  }

  Map<String, dynamic> _extractMessagePayload(Map<String, dynamic> envelope) {
    Map<String, dynamic> payload;
    if (envelope['data'] is Map) {
      payload = _deepCastMap(envelope['data'] as Map);
    } else if (envelope['message'] is Map) {
      payload = _deepCastMap(envelope['message'] as Map);
    } else {
      payload = _deepCastMap(envelope);
    }

    // Fallbacks from envelope metadata if omitted in payload
    if (payload['message_id'] == null && envelope['entity_id'] != null) {
      payload['message_id'] = envelope['entity_id'];
    }
    if (payload['channel_id'] == null && envelope['channel_id'] != null) {
      payload['channel_id'] = envelope['channel_id'];
    }
    if (payload['created_at'] == null && envelope['occurred_at'] != null) {
      payload['created_at'] = envelope['occurred_at'];
    }
    return payload;
  }

  Map<String, dynamic> _parseData(dynamic raw) {
    if (raw is Map) return _deepCastMap(raw);
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) return _deepCastMap(decoded);
      } catch (_) {}
    }
    return {};
  }

  Map<String, dynamic> _deepCastMap(Map<dynamic, dynamic> raw) {
    return raw.map<String, dynamic>(
      (key, val) => MapEntry(
        key.toString(),
        val is Map
            ? _deepCastMap(val)
            : (val is List
                ? val.map((e) => e is Map ? _deepCastMap(e) : e).toList()
                : val),
      ),
    );
  }

  void dispose() {
    _userInboxSubscription?.cancel();
    for (final sub in _channelSubscriptions.values) {
      sub.cancel();
    }
    _channelSubscriptions.clear();
    for (final sub in _presenceSubscriptions.values) {
      sub.cancel();
    }
    _presenceSubscriptions.clear();
    for (final controller in _presenceControllers.values) {
      controller.close();
    }
    _presenceControllers.clear();
    _onlineUsersByChannel.clear();
    for (final timer in _typingTimers.values) {
      timer.cancel();
    }
    _typingTimers.clear();
    for (final controller in _typingControllers.values) {
      controller.close();
    }
    _typingControllers.clear();
  }
}

