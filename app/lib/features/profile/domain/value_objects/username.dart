import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';

/// A syntactically valid username. Uniqueness is a separate, async concern
/// (checked against the backend via `check_username_available`) — this value
/// object only guarantees the format rules.
///
/// Rules: 3–20 chars, lowercase letters / digits / underscore only, must start
/// with a letter, and must not be a reserved handle.
class Username {
  const Username._(this.value);
  final String value;

  static const _reserved = {
    'admin',
    'support',
    'help',
    'circk',
    'official',
    'system',
  };

  static final _re = RegExp(r'^[a-z][a-z0-9_]{2,19}$');

  static Either<ValidationFailure, Username> create(String input) {
    final v = input.trim().toLowerCase();
    if (v.isEmpty) {
      return const Left(ValidationFailure('Username is required'));
    }
    if (v.length < 3) {
      return const Left(ValidationFailure('At least 3 characters'));
    }
    if (v.length > 20) {
      return const Left(ValidationFailure('At most 20 characters'));
    }
    if (!_re.hasMatch(v)) {
      // Distinguish the most common cause for a friendlier message.
      if (RegExp(r'^[0-9_]').hasMatch(v)) {
        return const Left(ValidationFailure('Must start with a letter'));
      }
      return const Left(
        ValidationFailure('Only lowercase letters, numbers, and underscores'),
      );
    }
    if (_reserved.contains(v)) {
      return const Left(ValidationFailure('That username is reserved'));
    }
    return Right(Username._(v));
  }

  @override
  bool operator ==(Object other) => other is Username && other.value == value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => value;
}
