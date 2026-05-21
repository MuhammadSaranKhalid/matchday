import 'package:fpdart/fpdart.dart';
import '../error/failures.dart';

/// Every use case is a callable: one input, one async result.
///
/// `Type` is the success payload (e.g. User, List<Todo>).
/// `Params` is whatever input the action needs (e.g. SignInParams).
///
/// Why `Either<Failure, T>`: success and failure are both first-class
/// in the return type. No throws cross the Domain boundary.
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// For use cases that need a stream instead of a one-shot result
/// (e.g. WatchTodos, WatchCurrentUser).
abstract class StreamUseCase<Type, Params> {
  Stream<Type> call(Params params);
}

/// Marker for "no input". Implements `==` so two NoParams are equal.
class NoParams {
  const NoParams();
  @override
  bool operator ==(Object other) => other is NoParams;
  @override
  int get hashCode => 0;
}
