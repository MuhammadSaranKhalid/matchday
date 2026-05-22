import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../../../core/sync/pending_operations_provider.dart';
import '../../../../core/sync/sync_provider.dart';
import '../../../../core/usecase/usecase.dart';
import '../../data/datasources/todos_datasource_providers.dart';
import '../../data/repositories/todos_repository_impl.dart';
import '../../domain/entities/todo.dart';
import '../../domain/repositories/todos_repository.dart';
import '../../domain/usecases/add_todo.dart';
import '../../domain/usecases/delete_todo.dart';
import '../../domain/usecases/toggle_todo.dart';
import '../../domain/usecases/watch_todos.dart';
import '../../domain/usecases/watch_todos_stream.dart';

part 'todos_providers.g.dart';

// Repository (coordinator of local + remote + sync) ----------------------

@Riverpod(keepAlive: true)
TodosRepository todosRepository(Ref ref) => TodosRepositoryImpl(
      local: ref.watch(todosLocalDataSourceProvider),
      pendingOps: ref.watch(pendingOperationsDataSourceProvider),
      syncService: ref.watch(syncServiceProvider),
      supabase: ref.watch(supabaseClientProvider),
    );

// Use cases --------------------------------------------------------------

@riverpod
GetTodos getTodosUseCase(Ref ref) =>
    GetTodos(ref.watch(todosRepositoryProvider));

@riverpod
AddTodo addTodoUseCase(Ref ref) =>
    AddTodo(ref.watch(todosRepositoryProvider));

@riverpod
ToggleTodo toggleTodoUseCase(Ref ref) =>
    ToggleTodo(ref.watch(todosRepositoryProvider));

@riverpod
DeleteTodo deleteTodoUseCase(Ref ref) =>
    DeleteTodo(ref.watch(todosRepositoryProvider));

@riverpod
WatchTodos watchTodosUseCase(Ref ref) =>
    WatchTodos(ref.watch(todosRepositoryProvider));

/// Real-time stream — now backed by the LOCAL DB stream.
/// The sync service mirrors Supabase real-time pushes into the local DB,
/// so the UI gets server-pushed updates for free without subscribing to
/// the websocket directly.
@riverpod
Stream<List<Todo>> todosStream(Ref ref) =>
    ref.watch(watchTodosUseCaseProvider).call(const NoParams());
