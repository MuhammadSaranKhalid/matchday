import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';

/// A message body that's guaranteed non-empty (after trim) and ≤ 2000 chars,
/// matching the `messages.body` Postgres check constraint
/// `length(body) between 1 and 2000` from migration 0802.
///
/// Only [create] produces instances; once you hold a [MessageBody] it's
/// guaranteed valid and safe to hand to the repository.
class MessageBody {
  const MessageBody._(this.value);
  final String value;

  static const int maxLength = 2000;

  static Either<ValidationFailure, MessageBody> create(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return const Left(ValidationFailure('Message cannot be empty'));
    }
    if (trimmed.length > maxLength) {
      return const Left(
        ValidationFailure('Message is too long (max $maxLength)'),
      );
    }
    return Right(MessageBody._(trimmed));
  }

  @override
  bool operator ==(Object other) =>
      other is MessageBody && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
