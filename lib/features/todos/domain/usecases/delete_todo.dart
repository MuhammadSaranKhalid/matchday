import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/todo.dart';
import '../repositories/todos_repository.dart';

class DeleteTodo implements UseCase<Unit, TodoId> {
  const DeleteTodo(this._repo);
  final TodosRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(TodoId id) => _repo.delete(id);
}
