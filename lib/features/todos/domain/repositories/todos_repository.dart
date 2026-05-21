import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/todo.dart';

abstract class TodosRepository {
  // ─── Request / response (default) ──────────────────────────────────────
  Future<Either<Failure, List<Todo>>> getAll();
  Future<Either<Failure, Todo>> add(String title);
  Future<Either<Failure, Todo>> toggle(TodoId id);
  Future<Either<Failure, Unit>> delete(TodoId id);

  // ─── Real-time (opt-in) ────────────────────────────────────────────────
  //
  // Emits the full list on every change to the underlying table.
  // Implementations wrap Supabase's .stream() builder. Errors are emitted
  // as stream errors so consumers can handle them with onError or
  // AsyncValue.error.
  Stream<List<Todo>> watchAll();
}
