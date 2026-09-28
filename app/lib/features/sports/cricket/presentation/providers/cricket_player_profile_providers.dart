import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../core/error/failures.dart';
import '../../data/repositories/cricket_player_profile_repository_impl.dart';
import '../../domain/entities/cricket_player_profile.dart';

part 'cricket_player_profile_providers.g.dart';

/// Fetches the [CricketPlayerProfile] for [userId].
///
/// Returns `null` when the user has no Cricket-specific profile attributes.
/// Player identity itself is represented by `player_sports`.
/// Throws [FailureWrapper] on network/server errors so the UI can pattern-match
/// `AsyncError` normally.
@riverpod
Future<CricketPlayerProfile?> cricketPlayerProfile(
  Ref ref,
  String userId,
) async {
  final result = await ref
      .read(cricketPlayerProfileRepositoryProvider)
      .getByUserId(CricketPlayerUserId(userId));

  return result.fold(
    (failure) => throw FailureWrapper(failure),
    (profile) => profile,
  );
}
