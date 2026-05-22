import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/exceptions.dart';
import '../models/profile_dto.dart';

/// Speaks Supabase for the `profiles` table. Returns DTOs, throws raw
/// exceptions. The profiles row already exists (created by the
/// `handle_new_user` trigger), so onboarding UPDATEs it — never INSERTs.
class OnboardingRemoteDataSource {
  OnboardingRemoteDataSource(this._supabase);
  final SupabaseClient _supabase;

  static const _table = 'profiles';

  String _requireUid() {
    final id = _supabase.auth.currentUser?.id;
    if (id == null) {
      throw UnauthorizedException('Must be signed in');
    }
    return id;
  }

  Future<ProfileDto?> fetchMyProfile() async {
    try {
      final uid = _requireUid();
      final row = await _supabase
          .from(_table)
          .select()
          .eq('user_id', uid)
          .maybeSingle();
      if (row == null) return null;
      return ProfileDto.fromJson(row);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<bool> isUsernameAvailable(String username) async {
    try {
      final result = await _supabase.rpc<dynamic>(
        'check_username_available',
        params: {'p_username': username},
      );
      return result == true;
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<ProfileDto> completeOnboarding({
    required String username,
    required String displayName,
    required String city,
    Map<String, dynamic>? playerProfile,
  }) async {
    try {
      final uid = _requireUid();
      final row = await _supabase
          .from(_table)
          .update({
            'username': username,
            'display_name': displayName,
            'location': {'city': city},
            'player_profile': playerProfile,
            'last_active_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', uid)
          .select()
          .single();
      return ProfileDto.fromJson(row);
    } on PostgrestException catch (e) {
      // 23505 = unique_violation: the username got taken between the
      // availability check and this write (a race). Surface a clear message.
      if (e.code == '23505') {
        throw ServerException('That username was just taken — try another');
      }
      throw ServerException(e.message);
    }
  }
}
