import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/follow.dart';
import '../../domain/entities/follow_counts.dart';
import '../models/follow_dto.dart';
import '../models/follow_list_entry_dto.dart';

/// Talks to Supabase for the `public.follows` table.
///
/// Throws raw [ServerException] / [UnauthorizedException] — never [Failure]s.
/// The repository implementation is the only place exceptions are translated.
///
/// RLS notes (from migration 0560):
///   - SELECT is public (follower lists are visible to anyone).
///   - INSERT is authenticated-only; `follower_id` must equal `auth.uid()`.
///   - DELETE is authenticated-only; `follower_id` must equal `auth.uid()`.
class FollowsRemoteDataSource {
  FollowsRemoteDataSource(this._supabase);
  final SupabaseClient _supabase;

  static const _table = 'follows';

  /// Ids of the teams the signed-in user follows.
  ///
  /// `follows` is polymorphic — target_type ∈ {user, team, tournament} — and
  /// the rest of this data source only ever asks about users, so this is the
  /// one read that filters on the team arm.
  Future<List<String>> listFollowedTeamIds() async {
    try {
      final rows = await _supabase
          .from(_table)
          .select('target_id')
          .eq('follower_id', _requireUid())
          .eq('target_type', 'team')
          .eq('status', 'active');
      return rows.map((r) => r['target_id'] as String).toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  String _requireUid() {
    final id = _supabase.auth.currentUser?.id;
    if (id == null) throw const UnauthorizedException('Must be signed in');
    return id;
  }

  /// Insert a follow row and return the created [FollowDto].
  ///
  /// [follower_id] is set client-side from the current session UID; RLS
  /// verifies it matches `auth.uid()` server-side.
  Future<FollowDto> follow(FollowTarget target) async {
    try {
      final uid = _requireUid();
      final row =
          await _supabase
              .from(_table)
              .insert({
                'follower_id': uid,
                'target_type': target.targetTypeWire,
                'target_id': target.targetId,
              })
              .select()
              .single();
      return FollowDto.fromJson(
        row,
      ).copyWith(notificationsEnabled: await areNotificationsEnabled(target));
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  /// Delete the follow row matching the current user + target.
  ///
  /// If the row doesn't exist (already unfollowed), the DELETE is a silent
  /// no-op — RLS deletes nothing and Supabase returns 200 with 0 affected rows.
  Future<void> unfollow(FollowTarget target) async {
    try {
      final uid = _requireUid();
      await _supabase
          .from(_table)
          .delete()
          .eq('follower_id', uid)
          .eq('target_type', target.targetTypeWire)
          .eq('target_id', target.targetId);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  /// Returns `true` if the current user has an active follow row for [target].
  ///
  /// Uses `maybeSingle()` so it returns null (not an error) when no row exists.
  Future<bool> isFollowing(FollowTarget target) async {
    try {
      final uid = _requireUid();
      final row =
          await _supabase
              .from(_table)
              .select('follow_id')
              .eq('follower_id', uid)
              .eq('target_type', target.targetTypeWire)
              .eq('target_id', target.targetId)
              .maybeSingle();
      return row != null;
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  /// The follow bell reads/writes the shared notification mute registry.
  Future<bool> areNotificationsEnabled(FollowTarget target) async {
    if (!await isFollowing(target)) return false;
    final row =
        await _supabase
            .from('notification_mutes')
            .select('muted_until')
            .eq('user_id', _requireUid())
            .eq('scope', target.targetTypeWire)
            .eq('entity_id', target.targetId)
            .maybeSingle();
    if (row == null) return true;
    final until = row['muted_until'] as String?;
    return until != null && !DateTime.parse(until).isAfter(DateTime.now());
  }

  Future<void> setNotificationsEnabled(
    FollowTarget target, {
    required bool enabled,
  }) async {
    try {
      await _supabase.rpc<void>(
        'set_follow_notifications',
        params: {
          'p_scope': target.targetTypeWire,
          'p_entity_id': target.targetId,
          'p_enabled': enabled,
        },
      );
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  // -------------------------------------------------------------------------
  // Follow list
  // -------------------------------------------------------------------------

  /// Fetches a paginated followers or following list by invoking the
  /// `list-follow-list` edge function.
  ///
  /// The function is public (no auth token required to view someone else's
  /// list), but an authenticated session is still passed through so the
  /// edge function can populate the `you_follow` / `they_follow_you` flags
  /// relative to the caller. The data source does NOT assert `_requireUid()`
  /// here — unauthenticated callers simply get false for both flags.
  ///
  /// Error-handling shape mirrors [MessagesRemoteDataSource.listMyChats]:
  /// [FunctionException] → [UnauthorizedException] (401/403) or
  ///                       [ServerException] (other status).
  Future<List<FollowListEntryDto>> listFollowList(
    String userId,
    String direction, {
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final res = await _supabase.rpc<dynamic>(
        'get_follow_list',
        params: {
          'p_user_id': userId,
          'p_direction': direction,
          'p_limit': limit,
          'p_offset': offset,
        },
      );
      final rows = res is List ? res : (res is Map ? res['entries'] : null);
      if (rows is! List) {
        throw const ServerException('get_follow_list returned an unexpected payload');
      }
      return rows
          .map(
            (row) => FollowListEntryDto.fromJson(
              Map<String, dynamic>.from(row as Map),
            ),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } on FunctionException catch (e) {
      throw _functionException(e);
    }
  }

  // -------------------------------------------------------------------------
  // Follow counts
  // -------------------------------------------------------------------------

  /// Returns the number of user-to-user followers and following accounts for
  /// [userId] via two PostgREST HEAD count queries.
  ///
  /// Only counts rows where `target_type = 'user'`, so team/tournament follows
  /// are excluded — matching what the profile header displays.
  ///
  /// The `count()` call in postgrest-dart 2.5.x returns a
  /// `PostgrestFilterBuilder<int>` which resolves directly to an [int]; the
  /// Prefer: count=exact header is set automatically.
  Future<FollowCounts> countFollows(String userId) async {
    try {
      final followersCount = await _supabase
          .from(_table)
          .count()
          .eq('target_type', 'user')
          .eq('target_id', userId);

      final followingCount = await _supabase
          .from(_table)
          .count()
          .eq('target_type', 'user')
          .eq('follower_id', userId);

      return FollowCounts(followers: followersCount, following: followingCount);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  // -------------------------------------------------------------------------
  // Private helpers
  // -------------------------------------------------------------------------

  /// Translates a [FunctionException] to either an [UnauthorizedException] or
  /// a [ServerException], extracting the server-side error message when the
  /// response body carries `{ ok: false, error: { message: "..." } }`.
  ///
  /// Mirrors [MessagesRemoteDataSource._functionException].
  Exception _functionException(FunctionException e) {
    String? msg;
    final d = e.details;
    if (d is Map && d['error'] is Map) {
      msg = (d['error'] as Map)['message']?.toString();
    }
    switch (e.status) {
      case 401:
      case 403:
        return UnauthorizedException(msg ?? 'Not authorised');
      default:
        return ServerException(msg ?? 'list-follow-list failed');
    }
  }
}
