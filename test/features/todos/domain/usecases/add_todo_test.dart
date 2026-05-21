import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novex_clean_arch/core/error/failures.dart';
import 'package:novex_clean_arch/features/todos/domain/entities/todo.dart';
import 'package:novex_clean_arch/features/todos/domain/repositories/todos_repository.dart';
import 'package:novex_clean_arch/features/todos/domain/usecases/add_todo.dart';

class _MockTodosRepo extends Mock implements TodosRepository {}

void main() {
  late _MockTodosRepo repo;
  late AddTodo addTodo;

  setUp(() {
    repo = _MockTodosRepo();
    addTodo = AddTodo(repo);
  });

  test('rejects empty title without calling the repo', () async {
    final result = await addTodo(const AddTodoParams('   '));

    expect(result.isLeft(), isTrue);
    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    verifyNever(() => repo.add(any()));
  });

  test('rejects title over 140 chars', () async {
    final result = await addTodo(AddTodoParams('x' * 141));
    expect(result.isLeft(), isTrue);
    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
  });

  test('forwards a trimmed valid title to the repo', () async {
    final created = Todo(
      id: const TodoId('t1'),
      title: 'Buy milk',
      completed: false,
      createdAt: DateTime(2026),
    );
    when(() => repo.add(any())).thenAnswer((_) async => Right(created));

    final result = await addTodo(const AddTodoParams('  Buy milk  '));

    expect(result, equals(Right<Failure, Todo>(created)));
    verify(() => repo.add('Buy milk')).called(1);
  });
}
