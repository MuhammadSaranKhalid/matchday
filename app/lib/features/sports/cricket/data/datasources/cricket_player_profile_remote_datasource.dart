import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/error/exceptions.dart';
import '../models/cricket_player_profile_dto.dart';

/// Speaks Supabase for the `cricket_player_profiles` table.
///
/// Read-only for now: editing sport-specific player attributes has not yet
/// been designed. Returns DTOs, throws raw exceptions.
class CricketPlayerProfileRemoteDataSource {
  CricketPlayerProfileRemoteDataSource(this._supabase);

  final SupabaseClient _supabase;

  static const _table = 'cricket_player_profiles';

  /// Fetch the cricket profile row for [userId].
  ///
  /// Returns `null` when the user has no Cricket-specific profile attributes.
  ///
  /// Player identity itself is represented by `player_sports`; a user may have
  /// `(user_id, cricket)` there without having filled batting/bowling/profile
  /// details in `cricket_player_profiles`.
  Future<CricketPlayerProfileDto?> fetchByUserId(String userId) async {
    try {
      final row = await _supabase
          .from(_table)
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (row == null) return null;

      return CricketPlayerProfileDto.fromJson(row);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }
}
