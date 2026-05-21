import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/todo.dart';
import '../repositories/todos_repository.dart';

class AddTodo implements UseCase<Todo, AddTodoParams> {
  const AddTodo(this._repo);
  final TodosRepository _repo;

  @override
  Future<Either<Failure, Todo>> call(AddTodoParams p) async {
    // Business rule lives here, not in the controller or the repo.
    final title = p.title.trim();
    if (title.isEmpty) {
      return const Left(ValidationFailure('Title cannot be empty'));
    }
    if (title.length > 140) {
      return const Left(ValidationFailure('Title is too long (max 140)'));
    }
    return _repo.add(title);
  }
}

class AddTodoParams {
  const AddTodoParams(this.title);
  final String title;
}
