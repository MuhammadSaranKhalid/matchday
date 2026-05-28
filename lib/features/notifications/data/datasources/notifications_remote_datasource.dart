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
    if (id == null) throw UnauthorizedException('Must be signed in');
    return id;
  }

  // ─── Reads ────────────────────────────────────────────────────────────

  Future<List<NotificationDto>> listMine() async {
    try {
      final rows = await _supabase
          .from(_notifications)
          .select()
          .order('created_at', ascending: false);
      return rows.map(NotificationDto.fromJson).toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  /// Subscribes to the `user:<uid>:notifications` private broadcast channel.
  /// Yields the running list newest-first after each event. Initial hydration
  /// via a one-shot SELECT.
  Stream<List<NotificationDto>> watchMine() async* {
    final uid = _requireUid();

    var current = await listMine();
    yield current;

    final controller = StreamController<List<NotificationDto>>();
    final channel = _supabase.channel(
      'user:$uid:notifications',
      opts: const RealtimeChannelConfig(self: true, private: true),
    );

    channel
        .onBroadcast(
          event: 'notification',
          callback: (payload) {
            final data =
                (payload['payload'] as Map<String, dynamic>?) ?? payload;
            try {
              final dto = NotificationDto.fromJson(data);
              // Prepend; the trigger sends new rows in row-shape.
              current = [
                dto,
                ...current.where((n) => n.notificationId != dto.notificationId),
              ];
              controller.add(List.unmodifiable(current));
            } catch (e) {
              controller.addError(ServerException(e.toString()));
            }
          },
        )
        .onBroadcast(
          event: 'notification_updated',
          callback: (payload) {
            final data =
                (payload['payload'] as Map<String, dynamic>?) ?? payload;
            final id = data['notification_id'] as String?;
            final isRead = data['is_read'] as bool? ?? false;
            if (id == null) return;
            current = [
              for (final n in current)
                if (n.notificationId == id)
                  n.copyWith(isRead: isRead)
                else
                  n,
            ];
            controller.add(List.unmodifiable(current));
          },
        )
        .subscribe();

    yield* controller.stream.asBroadcastStream(
      onCancel: (sub) async {
        await _supabase.removeChannel(channel);
        await controller.close();
      },
    );
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
      final rows = await _supabase
          .from(_notifications)
          .select('notification_id')
          .eq('recipient_id', _requireUid())
          .eq('is_read', false);
      return rows.length;
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }
}

