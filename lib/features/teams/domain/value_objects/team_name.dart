import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';

class TeamName {
  const TeamName._(this.value);
  final String value;

  static Either<ValidationFailure, TeamName> create(String input) {
    final v = input.trim();
    if (v.isEmpty) {
      return const Left(ValidationFailure('Team name is required'));
    }
    if (v.length < 3) {
      return const Left(ValidationFailure('At least 3 characters'));
    }
    if (v.length > 50) {
      return const Left(ValidationFailure('At most 50 characters'));
    }
    return Right(TeamName._(v));
  }

  @override
  bool operator ==(Object other) => other is TeamName && other.value == value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => value;
}
