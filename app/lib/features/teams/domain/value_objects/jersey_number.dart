import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';

class JerseyNumber {
  const JerseyNumber._(this.value);
  final int value;

  static Either<ValidationFailure, JerseyNumber> create(int input) {
    if (input < 0) {
      return const Left(ValidationFailure('Jersey number cannot be negative'));
    }
    if (input > 999) {
      return const Left(ValidationFailure('Jersey number is too large'));
    }
    return Right(JerseyNumber._(input));
  }

  @override
  bool operator ==(Object other) =>
      other is JerseyNumber && other.value == value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => '$value';
}
