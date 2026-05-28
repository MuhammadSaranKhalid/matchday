import '../../../../core/usecase/usecase.dart';
import '../entities/app_notification.dart';
import '../repositories/notifications_repository.dart';

/// Live notifications feed. The first emission is a hydration snapshot, then
/// each broadcast update re-emits the full list.
class WatchNotifications implements StreamUseCase<List<AppNotification>, NoParams> {
  const WatchNotifications(this._repo);
  final NotificationsRepository _repo;

  @override
  Stream<List<AppNotification>> call(NoParams params) => _repo.watchMine();
}
