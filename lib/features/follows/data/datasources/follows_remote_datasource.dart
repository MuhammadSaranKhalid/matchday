import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/follow.dart';
import '../models/follow_dto.dart';

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

  String _requireUid() {
    final id = _supabase.auth.currentUser?.id;
    if (id == null) throw UnauthorizedException('Must be signed in');
    return id;
  }

  /// Insert a follow row and return the created [FollowDto].
  ///
  /// [follower_id] is set client-side from the current session UID; RLS
  /// verifies it matches `auth.uid()` server-side.
  Future<FollowDto> follow(FollowTarget target) async {
    try {
      final uid = _requireUid();
      final row = await _supabase
          .from(_table)
          .insert({
            'follower_id': uid,
            'target_type': target.targetTypeWire,
            'target_id': target.targetId,
          })
          .select()
          .single();
      return FollowDto.fromJson(row);
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
      final row = await _supabase
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
}
