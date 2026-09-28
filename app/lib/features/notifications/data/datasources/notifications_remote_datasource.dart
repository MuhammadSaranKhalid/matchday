import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../models/notification_dto.dart';

/// Talks to Supabase for the `notifications` + `device_tokens` tables.
/// Returns DTOs / primitives; throws raw exceptions for the repository to
/// translate into [Failure]s.
class NotificationsRemoteDataSource {
  NotificationsRemoteDataSource(this._supabase);
  final SupabaseClient _supabase;

  static const _notifications = 'notifications';
  static const _deviceTokens = 'device_tokens';

  String _requireUid() {
    final id = _supabase.auth.currentUser?.id;
    if (id == null) throw const UnauthorizedException('Must be signed in');
    return id;
  }

  // ─── Reads ────────────────────────────────────────────────────────────

  String? iconUrl(String? path) {
    if (path == null || !RegExp(r'^v[0-9]+/[a-z0-9-]+[.]svg$').hasMatch(path)) {
      return null;
    }
    return _supabase.storage.from('notification-icons').getPublicUrl(path);
  }

  Future<List<Map<String, dynamic>>> settings() async {
    final rows = await _supabase.rpc<List<dynamic>>('notification_settings');
    return rows.map((r) => Map<String, dynamic>.from(r as Map)).toList();
  }

  Future<void> setPreference(
    String category,
    String channel,
    bool enabled,
  ) async {
    await _supabase.from('notification_preferences').upsert({
      'user_id': _requireUid(),
      'category': category,
      'channel': channel,
      'enabled': enabled,
    });
  }

  static const pageSize = 40;
  Future<void> Function()? _loadMore;

  Future<List<NotificationDto>> listMine({NotificationDto? before}) async {
    final rows = await _supabase.rpc<List<dynamic>>(
      'list_notifications',
      params: {
        'p_limit': pageSize,
        if (before != null) 'p_before_created': before.createdAt,
        if (before != null) 'p_before_id': before.notificationId,
      },
    );
    return rows
        .map(
          (row) =>
              NotificationDto.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  Future<void> loadMore() async => await _loadMore?.call();

  /// Subscribe before hydration. Events invalidate a bounded, paginated window;
  /// a dirty flag guarantees an event during a fetch triggers another fetch.
  /// Reconciliation also handles deletions and reconnects without partial DTOs.
  Stream<NotificationFeedDto> watchMine() {
    final uid = _requireUid();
    late StreamController<NotificationFeedDto> controller;
    late RealtimeChannel channel;
    var disposed = false;
    var dirty = false;
    var fetching = false;
    var pages = 1;
    var feed = const NotificationFeedDto();
    Timer? debounce;

    Future<void> refresh() async {
      dirty = true;
      if (fetching || disposed) return;
      fetching = true;
      try {
        while (dirty && !disposed) {
          dirty = false;
          final rows = <NotificationDto>[];
          var hasMore = false;
          for (var page = 0; page < pages; page++) {
            final batch = await listMine(before: rows.lastOrNull);
            rows.addAll(batch);
            hasMore = batch.length == pageSize;
            if (!hasMore) break;
          }
          final count = await unreadCount();
          if (disposed) return;
          feed = NotificationFeedDto(
            items: rows,
            unreadCount: count,
            hasMore: hasMore,
          );
          controller.add(feed);
        }
      } catch (e, st) {
        if (!disposed) controller.addError(e, st);
      } finally {
        fetching = false;
      }
    }

    void invalidate(Map<String, dynamic> _) {
      if (disposed) return;
      dirty = true;
      debounce?.cancel();
      debounce = Timer(const Duration(milliseconds: 60), refresh);
    }

    Future<void> more() async {
      if (disposed || fetching || !feed.hasMore) return;
      pages++;
      controller.add(
        NotificationFeedDto(
          items: feed.items,
          unreadCount: feed.unreadCount,
          hasMore: feed.hasMore,
          loadingMore: true,
        ),
      );
      await refresh();
    }

    controller = StreamController<NotificationFeedDto>(
      onListen: () {
        _loadMore = more;

        // HYDRATE FIRST, INDEPENDENTLY OF REALTIME. The inbox is a plain HTTP
        // read; realtime only makes it *live*. This used to be called solely
        // from the subscribe() callback below, which meant no WebSocket => no
        // fetch => an infinite spinner on a screen whose data was one request
        // away. That is not a rare edge: it happens on a flaky network, behind
        // a proxy that blocks WebSockets, and every time the Realtime service
        // restarts under a running client.
        unawaited(refresh());

        channel = _supabase.channel(
          'user:$uid:notifications',
          opts: const RealtimeChannelConfig(private: true),
        );
        for (final event in [
          'notification',
          'notification_updated',
          'notification_deleted',
        ]) {
          channel.onBroadcast(event: event, callback: invalidate);
        }
        channel.subscribe((status, error) {
          if (disposed) return;
          if (status == RealtimeSubscribeStatus.subscribed) {
            // Still refresh on (re)connect: anything broadcast while the socket
            // was down was missed, and reconciliation is cheap.
            unawaited(refresh());
          } else if (status == RealtimeSubscribeStatus.channelError ||
              status == RealtimeSubscribeStatus.timedOut) {
            // Only fail the stream if we have nothing to show. Once a feed has
            // loaded, losing live updates must degrade to "not live" — tearing
            // a populated inbox down to an error screen because a socket
            // dropped is strictly worse than showing slightly stale rows.
            if (feed.items.isEmpty) {
              controller.addError(
                const ServerException('Notification connection interrupted'),
              );
            }
          }
        });
      },
      onCancel: () async {
        disposed = true;
        debounce?.cancel();
        if (_loadMore == more) _loadMore = null;
        await _supabase.removeChannel(channel);
      },
    );
    return controller.stream;
  }

  // ─── Writes (RLS-scoped, no RPC required) ──────────────────────────────

  Future<void> markRead(String notificationId) async {
    try {
      await _supabase
          .from(_notifications)
          .update({'is_read': true})
          .eq('notification_id', notificationId)
          .eq('recipient_id', _requireUid());
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<void> markAllRead() async {
    try {
      await _supabase
          .from(_notifications)
          .update({'is_read': true})
          .eq('recipient_id', _requireUid())
          .eq('is_read', false);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  /// Upserts the device-token row keyed by (user_id, fcm_token). The
  /// deployed schema lets the client write its own row directly under RLS.
  Future<void> registerDeviceToken({
    required String fcmToken,
    required String platform,
    String? appVersion,
  }) async {
    try {
      final uid = _requireUid();
      // Try insert; if a row already exists with the same fcm_token, bump
      // last_seen_at via update. Two round-trips kept simple — happens
      // once per app boot.
      try {
        await _supabase.from(_deviceTokens).insert({
          'user_id': uid,
          'fcm_token': fcmToken,
          'platform': platform,
          if (appVersion != null) 'app_version': appVersion,
        });
      } on PostgrestException catch (e) {
        // 23505 = unique_violation — the (user_id, fcm_token) pair already
        // exists. Bump last_seen_at instead.
        if (e.code != '23505') rethrow;
        await _supabase
            .from(_deviceTokens)
            .update({
              'last_seen_at': DateTime.now().toUtc().toIso8601String(),
              if (appVersion != null) 'app_version': appVersion,
            })
            .eq('user_id', uid)
            .eq('fcm_token', fcmToken);
      }
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<void> revokeDeviceToken(String fcmToken) async {
    try {
      await _supabase
          .from(_deviceTokens)
          .delete()
          .eq('user_id', _requireUid())
          .eq('fcm_token', fcmToken);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  /// One-shot count for badge hydration before the broadcast stream's first
  /// emission. Cheap server-side (`count(*)`).
  Future<int> unreadCount() async {
    try {
      return await _supabase
          .from(_notifications)
          .count()
          .eq('recipient_id', _requireUid())
          .eq('is_read', false);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }
}
