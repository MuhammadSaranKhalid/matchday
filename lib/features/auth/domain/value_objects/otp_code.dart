import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';

/// A 6-digit numeric OTP code. Constructable only when valid.
class OtpCode {
  const OtpCode._(this.value);
  final String value;

  static final _digits = RegExp(r'^\d{6}$');

  static Either<ValidationFailure, OtpCode> create(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return const Left(ValidationFailure('Code is required'));
    }
    if (!_digits.hasMatch(trimmed)) {
      return const Left(ValidationFailure('Code must be 6 digits'));
    }
    return Right(OtpCode._(trimmed));
  }

  @override
  bool operator ==(Object other) => other is OtpCode && other.value == value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => 'OtpCode(***)';
}
