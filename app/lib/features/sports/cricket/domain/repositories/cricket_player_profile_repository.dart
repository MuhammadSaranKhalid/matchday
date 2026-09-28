import 'package:fpdart/fpdart.dart';

import '../../../../../core/error/failures.dart';
import '../entities/cricket_player_profile.dart';

/// Contract for reading Cricket player profile data.
///
/// Read-only for now: the UX for editing sport-specific player attributes has
/// not yet been designed. Writes will be added in a future feature.
abstract class CricketPlayerProfileRepository {
  /// Fetch the cricket player profile for [userId].
  ///
  /// Returns [Right(null)] when the user has no Cricket player identity yet.
  Future<Either<Failure, CricketPlayerProfile?>> getByUserId(
    CricketPlayerUserId userId,
  );
}
