import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/exceptions.dart';
import '../models/profile_dto.dart';

/// Speaks Supabase for the `profiles` + `player_profiles` tables. Returns DTOs,
/// throws raw exceptions. The profiles row already exists (created by the
/// `handle_new_auth_user` trigger), so onboarding UPDATEs it — never INSERTs.
/// Cricketing attributes live in `player_profiles` and are upserted separately.
class OnboardingRemoteDataSource {
  OnboardingRemoteDataSource(this._supabase);
  final SupabaseClient _supabase;

  static const _profiles = 'profiles';
  static const _playerProfiles = 'player_profiles';

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
          .from(_profiles)
          .select()
          .eq('user_id', uid)
          .maybeSingle();
      if (row == null) return null;

      // player_profiles is a separate 1:1 table; fold it into the profile map
      // under the key ProfileDto expects so a single fromJson assembles both.
      final player = await _supabase
          .from(_playerProfiles)
          .select()
          .eq('user_id', uid)
          .maybeSingle();
      row['player_profile'] = player;
      return ProfileDto.fromJson(row);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  /// `profiles` is publicly readable; a username is free when no row holds it
  /// (excluding the caller's own row). The DB also guards uniqueness + cooldown
  /// via constraint/trigger — this is just the pre-flight UX check.
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final uid = _supabase.auth.currentUser?.id;
      final row = await _supabase
          .from(_profiles)
          .select('user_id')
          .eq('username', username)
          .maybeSingle();
      if (row == null) return true;
      return row['user_id'] == uid; // already mine → still "available" to me
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  /// Persists onboarding: updates the profiles row (stamping `onboarded_at`)
  /// and, when the user supplied cricketing attributes, upserts player_profiles.
  /// Returns the freshly assembled profile.
  Future<ProfileDto> completeOnboarding({
    required String username,
    required String displayName,
    required String city,
    String? placeId,
    double? latitude,
    double? longitude,
    String? countryCode,
    Map<String, dynamic>? playerProfile,
  }) async {
    try {
      final uid = _requireUid();
      final now = DateTime.now().toIso8601String();
      await _supabase
          .from(_profiles)
          .update({
            'username': username,
            'display_name': displayName,
            'location': {
              'city': city,
              if (placeId != null) 'place_id': placeId,
              if (latitude != null) 'lat': latitude,
              if (longitude != null) 'lng': longitude,
              if (countryCode != null) 'country_code': countryCode,
            },
            'onboarded_at': now,
            'last_active_at': now,
          })
          .eq('user_id', uid);

      if (playerProfile != null) {
        await _supabase.from(_playerProfiles).upsert(
          {'user_id': uid, ...playerProfile},
          onConflict: 'user_id',
        );
      }

      final fresh = await fetchMyProfile();
      if (fresh == null) {
        throw ServerException('Profile vanished after onboarding');
      }
      return fresh;
    } on PostgrestException catch (e) {
      // 23505 = unique_violation: the username got taken between the
      // availability check and this write (a race). Surface a clear message.
      if (e.code == '23505') {
        throw ServerException('That username was just taken — try another');
      }
      throw ServerException(e.message);
    }
  }

  /// Update the profiles row with the supplied [changes], stamp last_active_at,
  /// and return the freshly assembled profile. Maps a unique-username clash to
  /// a clear message; the 30-day username-cooldown trigger's message is passed
  /// through as-is.
  Future<ProfileDto> updateProfile(Map<String, dynamic> changes) async {
    try {
      final uid = _requireUid();
      await _supabase
          .from(_profiles)
          .update({...changes, 'last_active_at': DateTime.now().toIso8601String()})
          .eq('user_id', uid);
      final fresh = await fetchMyProfile();
      if (fresh == null) throw ServerException('Profile not found');
      return fresh;
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw ServerException('That username is taken — try another');
      }
      throw ServerException(e.message);
    }
  }

  /// Upload an avatar to `avatars/<uid>/avatar_<ts>.jpg` and return its public
  /// URL. The timestamped path doubles as a cache-buster on the CDN.
  Future<String> uploadAvatar(File file) async {
    try {
      final uid = _requireUid();
      final path = '$uid/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await _supabase.storage.from('avatars').upload(
            path,
            file,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );
      return _supabase.storage.from('avatars').getPublicUrl(path);
    } on StorageException catch (e) {
      throw ServerException(e.message);
    }
  }
}
