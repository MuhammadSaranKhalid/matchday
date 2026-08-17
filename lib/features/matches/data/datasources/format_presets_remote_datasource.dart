import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/exceptions.dart';
import '../models/format_preset_dto.dart';

/// Talks to the `format_presets` reference catalog — the match-setup format
/// picker's source of truth. Read-only reference data, NOT part of the match
/// aggregate, so it lives in its own data source rather than the match
/// lifecycle one. Returns DTOs; throws raw exceptions (translated to Failures
/// in the repository).
class FormatPresetsRemoteDataSource {
  FormatPresetsRemoteDataSource(this._supabase);
  final SupabaseClient _supabase;

  static const _table = 'match_format_presets';

  /// The active format presets, in display order.
  Future<List<FormatPresetDto>> listFormatPresets() async {
    try {
      final rows = await _supabase
          .from(_table)
          .select()
          .eq('is_active', true)
          .order('sort_order');
      return rows.map(FormatPresetDto.fromJson).toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }
}
