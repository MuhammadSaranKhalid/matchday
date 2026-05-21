import '../../../../core/usecase/usecase.dart';
import '../entities/todo.dart';
import '../repositories/todos_repository.dart';

/// Opt-in real-time use case. The screen chooses whether to use this
/// (StreamNotifier under the hood) or [GetTodos] (request/response).
class WatchTodos implements StreamUseCase<List<Todo>, NoParams> {
  const WatchTodos(this._repo);
  final TodosRepository _repo;

  @override
  Stream<List<Todo>> call(NoParams _) => _repo.watchAll();
}
