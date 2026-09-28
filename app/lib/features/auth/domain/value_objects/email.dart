import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';

/// An email address that is guaranteed valid because the only way to
/// construct one is through [create], which returns Either.
///
/// This is the core idea of value objects: invalid states become
/// unrepresentable, so downstream code doesn't need defensive checks.
class Email {
  const Email._(this.value);
  final String value;

  static final _re = RegExp(r'^[\w.+\-]+@[\w-]+\.[\w.-]+$');

  static Either<ValidationFailure, Email> create(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return const Left(ValidationFailure('Email is required'));
    }
    if (!_re.hasMatch(trimmed)) {
      return const Left(ValidationFailure('Email format is invalid'));
    }
    return Right(Email._(trimmed.toLowerCase()));
  }

  @override
  bool operator ==(Object other) =>
      other is Email && other.value == value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => value;
}
