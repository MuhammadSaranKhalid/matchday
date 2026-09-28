import 'package:supabase_flutter/supabase_flutter.dart';

import '../error/exceptions.dart';

/// Shared auth helpers on [SupabaseClient] for the data layer.
///
/// Every feature's remote data source needs the signed-in user's id before it
/// can stamp `user_id`/`sender_id`, build a per-user realtime channel name, or
/// target a composite-PK row. Rather than each data source re-declaring a
/// private `_requireUid()` (the pattern duplicated across matches /
/// notifications / onboarding / teams / posts / messages), they all call
/// [requireUid] here.
///
/// Throws the raw [UnauthorizedException] — caught and translated to
/// `AuthFailure` in the repository per CLAUDE.md Rule 2 — so callers get a
/// non-null `String` and a single, consistent failure path.
extension CurrentUserX on SupabaseClient {
  /// The signed-in user's id, or throws [UnauthorizedException] when there is
  /// no authenticated session.
  String requireUid() {
    final id = auth.currentUser?.id;
    if (id == null) throw const UnauthorizedException('Must be signed in');
    return id;
  }
}
