import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';

/// A user's display name: 2–50 characters after trimming. Free-form otherwise
/// (names contain spaces, dots, scripts beyond ASCII), so we only bound length.
class DisplayName {
  const DisplayName._(this.value);
  final String value;

  static Either<ValidationFailure, DisplayName> create(String input) {
    final v = input.trim();
    if (v.isEmpty) {
      return const Left(ValidationFailure('Display name is required'));
    }
    if (v.length < 2) {
      return const Left(ValidationFailure('At least 2 characters'));
    }
    if (v.length > 50) {
      return const Left(ValidationFailure('At most 50 characters'));
    }
    return Right(DisplayName._(v));
  }

  @override
  bool operator ==(Object other) =>
      other is DisplayName && other.value == value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => value;
}
