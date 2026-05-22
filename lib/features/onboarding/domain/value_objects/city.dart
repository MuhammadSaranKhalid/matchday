import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';

/// The user's "City / village" as a single free-text field (e.g.
/// "Lahore, Punjab"). The only rule is non-empty after trimming; the value is
/// otherwise unconstrained (Phase 1 has no geocoding).
class City {
  const City._(this.value);
  final String value;

  static Either<ValidationFailure, City> create(String input) {
    final v = input.trim();
    if (v.isEmpty) {
      return const Left(ValidationFailure('City is required'));
    }
    return Right(City._(v));
  }

  @override
  bool operator ==(Object other) => other is City && other.value == value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => value;
}
