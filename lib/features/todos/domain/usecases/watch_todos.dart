import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/todo.dart';
import '../repositories/todos_repository.dart';

class GetTodos implements UseCase<List<Todo>, NoParams> {
  const GetTodos(this._repo);
  final TodosRepository _repo;

  @override
  Future<Either<Failure, List<Todo>>> call(NoParams _) => _repo.getAll();
}
