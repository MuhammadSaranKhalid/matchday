import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';

/// The name of an unclaimed player added to a roster: non-empty, max 100 chars
/// after trimming.
class PlayerDisplayName {
  const PlayerDisplayName._(this.value);
  final String value;

  static Either<ValidationFailure, PlayerDisplayName> create(String input) {
    final v = input.trim();
    if (v.isEmpty) {
      return const Left(ValidationFailure('Player name is required'));
    }
    if (v.length > 100) {
      return const Left(ValidationFailure('Player name is too long'));
    }
    return Right(PlayerDisplayName._(v));
  }

  @override
  bool operator ==(Object other) =>
      other is PlayerDisplayName && other.value == value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => value;
}
