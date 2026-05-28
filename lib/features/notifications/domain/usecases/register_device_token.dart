import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/app_notification.dart';
import '../repositories/notifications_repository.dart';

/// Upsert the caller's FCM token. Invoked by the sign-in flow + every cold
/// start so the server always has the latest token for this device.
class RegisterDeviceToken implements UseCase<Unit, RegisterDeviceTokenParams> {
  const RegisterDeviceToken(this._repo);
  final NotificationsRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(RegisterDeviceTokenParams p) {
    if (p.fcmToken.trim().isEmpty) {
      return Future.value(const Left(
        ValidationFailure('FCM token is required'),
      ));
    }
    return _repo.registerDeviceToken(
      fcmToken: p.fcmToken,
      platform: p.platform,
      appVersion: p.appVersion,
    );
  }
}

class RegisterDeviceTokenParams {
  const RegisterDeviceTokenParams({
    required this.fcmToken,
    required this.platform,
    this.appVersion,
  });
  final String fcmToken;
  final DevicePlatform platform;
  final String? appVersion;
}

/// Drop the device-token row on sign-out so the server stops pushing.
class RevokeDeviceToken implements UseCase<Unit, String> {
  const RevokeDeviceToken(this._repo);
  final NotificationsRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(String fcmToken) =>
      _repo.revokeDeviceToken(fcmToken);
}
