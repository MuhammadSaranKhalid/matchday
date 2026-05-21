import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/sync/sync_provider.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/todo.dart';
import '../../domain/usecases/add_todo.dart';
import '../providers/todos_providers.dart';

part 'todos_controller.g.dart';

/// Todos controller — much simpler now that the data layer is offline-first.
///
/// build() listens to the local DB stream via WatchTodos. The local DB
/// is updated synchronously by the repository on every write and by
/// the sync service on every remote push, so this controller never has
/// to manage optimistic state itself.
///
/// Action methods (add/toggle/delete) just call the repo and return
/// the Either result. The UI doesn't need to roll back because the repo
/// never leaves the local DB in a partial state — writes are atomic.
@riverpod
class TodosController extends _$TodosController {
  @override
  Stream<List<Todo>> build() =>
      ref.watch(watchTodosUseCaseProvider).call(const NoParams());

  Future<Either<Failure, Todo>> add(String title) =>
      ref.read(addTodoUseCaseProvider).call(AddTodoParams(title));

  Future<Either<Failure, Todo>> toggle(TodoId id) =>
      ref.read(toggleTodoUseCaseProvider).call(id);

  Future<Either<Failure, Unit>> delete(TodoId id) =>
      ref.read(deleteTodoUseCaseProvider).call(id);

  /// Pull-to-refresh — kicks the sync service. Returns once the cycle
  /// completes so the RefreshIndicator can dismiss its spinner.
  Future<void> refresh() => ref.read(syncServiceProvider).sync();
}
