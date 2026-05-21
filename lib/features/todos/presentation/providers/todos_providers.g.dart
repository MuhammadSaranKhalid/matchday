// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todos_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(todosRepository)
final todosRepositoryProvider = TodosRepositoryProvider._();

final class TodosRepositoryProvider
    extends
        $FunctionalProvider<TodosRepository, TodosRepository, TodosRepository>
    with $Provider<TodosRepository> {
  TodosRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'todosRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todosRepositoryHash();

  @$internal
  @override
  $ProviderElement<TodosRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TodosRepository create(Ref ref) {
    return todosRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TodosRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TodosRepository>(value),
    );
  }
}

String _$todosRepositoryHash() => r'2505195400a56e2ba226daf8bb83be2dbbc2c1d0';

@ProviderFor(getTodosUseCase)
final getTodosUseCaseProvider = GetTodosUseCaseProvider._();

final class GetTodosUseCaseProvider
    extends $FunctionalProvider<GetTodos, GetTodos, GetTodos>
    with $Provider<GetTodos> {
  GetTodosUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getTodosUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getTodosUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetTodos> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GetTodos create(Ref ref) {
    return getTodosUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetTodos value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetTodos>(value),
    );
  }
}

String _$getTodosUseCaseHash() => r'ce70c37bdb505cf7a2283b3c5a3792f56eb352dd';

@ProviderFor(addTodoUseCase)
final addTodoUseCaseProvider = AddTodoUseCaseProvider._();

final class AddTodoUseCaseProvider
    extends $FunctionalProvider<AddTodo, AddTodo, AddTodo>
    with $Provider<AddTodo> {
  AddTodoUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'addTodoUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$addTodoUseCaseHash();

  @$internal
  @override
  $ProviderElement<AddTodo> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AddTodo create(Ref ref) {
    return addTodoUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AddTodo value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AddTodo>(value),
    );
  }
}

String _$addTodoUseCaseHash() => r'4daa5bcf84861ae67ab4bb0a563506aed4fa84e1';

@ProviderFor(toggleTodoUseCase)
final toggleTodoUseCaseProvider = ToggleTodoUseCaseProvider._();

final class ToggleTodoUseCaseProvider
    extends $FunctionalProvider<ToggleTodo, ToggleTodo, ToggleTodo>
    with $Provider<ToggleTodo> {
  ToggleTodoUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'toggleTodoUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$toggleTodoUseCaseHash();

  @$internal
  @override
  $ProviderElement<ToggleTodo> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ToggleTodo create(Ref ref) {
    return toggleTodoUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ToggleTodo value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ToggleTodo>(value),
    );
  }
}

String _$toggleTodoUseCaseHash() => r'3e53f54b55ed2ef5cdebf4eed48a31056b824195';

@ProviderFor(deleteTodoUseCase)
final deleteTodoUseCaseProvider = DeleteTodoUseCaseProvider._();

final class DeleteTodoUseCaseProvider
    extends $FunctionalProvider<DeleteTodo, DeleteTodo, DeleteTodo>
    with $Provider<DeleteTodo> {
  DeleteTodoUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deleteTodoUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deleteTodoUseCaseHash();

  @$internal
  @override
  $ProviderElement<DeleteTodo> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DeleteTodo create(Ref ref) {
    return deleteTodoUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeleteTodo value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeleteTodo>(value),
    );
  }
}

String _$deleteTodoUseCaseHash() => r'2a1adfc7a0a7fcf42b308d785d3266902efae50f';

@ProviderFor(watchTodosUseCase)
final watchTodosUseCaseProvider = WatchTodosUseCaseProvider._();

final class WatchTodosUseCaseProvider
    extends $FunctionalProvider<WatchTodos, WatchTodos, WatchTodos>
    with $Provider<WatchTodos> {
  WatchTodosUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'watchTodosUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$watchTodosUseCaseHash();

  @$internal
  @override
  $ProviderElement<WatchTodos> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WatchTodos create(Ref ref) {
    return watchTodosUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WatchTodos value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WatchTodos>(value),
    );
  }
}

String _$watchTodosUseCaseHash() => r'8ee0c5abe3a7b40b3abd0f7eb88987ce5e152210';

/// Real-time stream — now backed by the LOCAL DB stream.
/// The sync service mirrors Supabase real-time pushes into the local DB,
/// so the UI gets server-pushed updates for free without subscribing to
/// the websocket directly.

@ProviderFor(todosStream)
final todosStreamProvider = TodosStreamProvider._();

/// Real-time stream — now backed by the LOCAL DB stream.
/// The sync service mirrors Supabase real-time pushes into the local DB,
/// so the UI gets server-pushed updates for free without subscribing to
/// the websocket directly.

final class TodosStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Todo>>,
          List<Todo>,
          Stream<List<Todo>>
        >
    with $FutureModifier<List<Todo>>, $StreamProvider<List<Todo>> {
  /// Real-time stream — now backed by the LOCAL DB stream.
  /// The sync service mirrors Supabase real-time pushes into the local DB,
  /// so the UI gets server-pushed updates for free without subscribing to
  /// the websocket directly.
  TodosStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'todosStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todosStreamHash();

  @$internal
  @override
  $StreamProviderElement<List<Todo>> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<Todo>> create(Ref ref) {
    return todosStream(ref);
  }
}

String _$todosStreamHash() => r'4a99ded7f2404c2015b68bccd95367cbcc24bd58';
