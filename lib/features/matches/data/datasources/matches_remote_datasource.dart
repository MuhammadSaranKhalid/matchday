import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/exceptions.dart';
import '../models/innings_dto.dart';
import '../models/match_dto.dart';

/// Talks to Supabase for the `matches` table. Returns DTOs, throws raw
/// exceptions. RLS scopes reads/writes.
class MatchesRemoteDataSource {
  MatchesRemoteDataSource(this._supabase);
  final SupabaseClient _supabase;

  static const _table = 'matches';

  String _requireUid() {
    final id = _supabase.auth.currentUser?.id;
    if (id == null) throw UnauthorizedException('Must be signed in');
    return id;
  }

  Future<MatchDto> create(Map<String, dynamic> payload) async {
    try {
      final row = await _supabase
          .from(_table)
          .insert({...payload, 'created_by': _requireUid()})
          .select()
          .single();
      return MatchDto.fromJson(row);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<MatchDto> update(String id, Map<String, dynamic> changes) async {
    try {
      final row = await _supabase
          .from(_table)
          .update(changes)
          .eq('match_id', id)
          .select()
          .single();
      return MatchDto.fromJson(row);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw NotFoundException('Match $id not found or already responded');
      }
      throw ServerException(e.message);
    }
  }

  Future<MatchDto?> getById(String id) async {
    try {
      final row =
          await _supabase.from(_table).select().eq('match_id', id).maybeSingle();
      return row == null ? null : MatchDto.fromJson(row);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<InningsDto> createInnings(Map<String, dynamic> payload) async {
    try {
      final row =
          await _supabase.from('innings').insert(payload).select().single();
      return InningsDto.fromJson(row);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  /// All matches visible to the user (RLS-scoped), newest first.
  Future<List<MatchDto>> list() async {
    try {
      final rows =
          await _supabase.from(_table).select().order('created_at', ascending: false);
      return rows.map(MatchDto.fromJson).toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }
}
