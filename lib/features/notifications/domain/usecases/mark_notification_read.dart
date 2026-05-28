import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/app_notification.dart';
import '../repositories/notifications_repository.dart';

class MarkNotificationRead implements UseCase<Unit, NotificationId> {
  const MarkNotificationRead(this._repo);
  final NotificationsRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(NotificationId id) => _repo.markRead(id);
}

class MarkAllNotificationsRead implements UseCase<Unit, NoParams> {
  const MarkAllNotificationsRead(this._repo);
  final NotificationsRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) => _repo.markAllRead();
}
