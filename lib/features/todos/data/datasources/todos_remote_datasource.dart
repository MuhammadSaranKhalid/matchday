import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/exceptions.dart';
import '../models/todo_dto.dart';

/// Talks to Supabase Postgrest. Returns DTOs. Throws raw exceptions.
///
/// Required schema (see README):
///   - todos table has updated_at timestamptz with a trigger that
///     updates it on every row mutation
///   - RLS policy scopes queries to auth.uid() = user_id
class TodosRemoteDataSource {
  TodosRemoteDataSource(this._supabase);
  final SupabaseClient _supabase;

  static const _table = 'todos';

  Future<List<TodoDto>> list({DateTime? modifiedAfter}) async {
    try {
      var query = _supabase.from(_table).select();
      if (modifiedAfter != null) {
        query = query.gt('updated_at', modifiedAfter.toIso8601String());
      }
      final rows = await query.order('updated_at', ascending: false);
      return rows.map((row) => TodoDto.fromJson(row)).toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  /// Push a locally-created todo (with client-generated UUID).
  /// Returns the canonical server row (with server's updated_at).
  Future<TodoDto> create({
    required String id,
    required String title,
    required DateTime createdAt,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw UnauthorizedException('Must be signed in to add todos');
      }
      final row = await _supabase
          .from(_table)
          .insert({
            'id': id,
            'user_id': userId,
            'title': title,
            'created_at': createdAt.toIso8601String(),
          })
          .select()
          .single();
      return TodoDto.fromJson(row);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<TodoDto> setCompleted({
    required String id,
    required bool completed,
  }) async {
    try {
      final row = await _supabase
          .from(_table)
          .update({'completed': completed})
          .eq('id', id)
          .select()
          .single();
      return TodoDto.fromJson(row);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw NotFoundException('Todo $id not found');
      }
      throw ServerException(e.message);
    }
  }

  Future<TodoDto> updateTitle({
    required String id,
    required String title,
  }) async {
    try {
      final row = await _supabase
          .from(_table)
          .update({'title': title})
          .eq('id', id)
          .select()
          .single();
      return TodoDto.fromJson(row);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw NotFoundException('Todo $id not found');
      }
      throw ServerException(e.message);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _supabase.from(_table).delete().eq('id', id);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  /// Real-time channel for push-based updates.
  /// The sync service subscribes and writes incoming rows into the
  /// local DB; the UI watches the local DB stream and re-renders.
  Stream<List<TodoDto>> watchStream() {
    return _supabase
        .from(_table)
        .stream(primaryKey: ['id'])
        .map((rows) => rows.map(TodoDto.fromJson).toList());
  }
}
