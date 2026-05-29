import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_remote_datasource.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  NotificationsRepositoryImpl(this._remote);
  final NotificationsRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<AppNotification>>> listMine() async {
    try {
      final dtos = await _remote.listMine();
      return Right(dtos.map((d) => d.toEntity()).toList());
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Stream<List<AppNotification>> watchMine() => _remote
      .watchMine()
      .map((dtos) => dtos.map((d) => d.toEntity()).toList())
      .handleError(
        (Object e) => throw FailureWrapper(ServerFailure(e.toString())),
      );

  @override
  Future<Either<Failure, Unit>> markRead(NotificationId id) async {
    try {
      await _remote.markRead(id.value);
      return const Right(unit);
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> markAllRead() async {
    try {
      await _remote.markAllRead();
      return const Right(unit);
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> registerDeviceToken({
    required String fcmToken,
    required DevicePlatform platform,
    String? appVersion,
  }) async {
    if (fcmToken.trim().isEmpty) {
      return const Left(ValidationFailure('FCM token is required'));
    }
    try {
      await _remote.registerDeviceToken(
        fcmToken: fcmToken,
        platform: platform.wire,
        appVersion: appVersion,
      );
      return const Right(unit);
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> revokeDeviceToken(String fcmToken) async {
    try {
      await _remote.revokeDeviceToken(fcmToken);
      return const Right(unit);
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
