import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/todo.dart';
import '../repositories/todos_repository.dart';

class ToggleTodo implements UseCase<Todo, TodoId> {
  const ToggleTodo(this._repo);
  final TodosRepository _repo;

  @override
  Future<Either<Failure, Todo>> call(TodoId id) => _repo.toggle(id);
}
