import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/blocked_account_dto.dart';
class SafetyRemoteDataSource {
  SafetyRemoteDataSource(this.client);
  final SupabaseClient client;
  String get _uid => client.auth.currentUser?.id ?? (throw const AuthException('Sign in to continue'));
  Future<List<BlockedAccountDto>> blockedAccounts() async {
    final rows = await client.from('user_blocks').select('blocked_id, profile:profiles!user_blocks_blocked_id_fkey(display_name)').eq('blocker_id', _uid);
    return rows.map(BlockedAccountDto.fromJson).toList();
  }
  Future<void> block(String id) async {
    await client.from('user_blocks').upsert({'blocker_id': _uid, 'blocked_id': id}, onConflict: 'blocker_id,blocked_id', ignoreDuplicates: true);
  }
  Future<void> unblock(String id) async {
    await client.from('user_blocks').delete().eq('blocker_id', _uid).eq('blocked_id', id);
  }
  Future<void> report({required String kind, required String targetId, required String reason, required String details}) async {
    await client.from('content_reports').insert({'reporter_id': _uid, 'target_kind': kind, 'target_id': targetId, 'reason': reason, 'details': details});
  }
}
