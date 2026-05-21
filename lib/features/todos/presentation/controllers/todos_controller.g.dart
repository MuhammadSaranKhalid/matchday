// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todos_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Todos controller — much simpler now that the data layer is offline-first.
///
/// build() listens to the local DB stream via WatchTodos. The local DB
/// is updated synchronously by the repository on every write and by
/// the sync service on every remote push, so this controller never has
/// to manage optimistic state itself.
///
/// Action methods (add/toggle/delete) just call the repo and return
/// the Either result. The UI doesn't need to roll back because the repo
/// never leaves the local DB in a partial state — writes are atomic.

@ProviderFor(TodosController)
final todosControllerProvider = TodosControllerProvider._();

/// Todos controller — much simpler now that the data layer is offline-first.
///
/// build() listens to the local DB stream via WatchTodos. The local DB
/// is updated synchronously by the repository on every write and by
/// the sync service on every remote push, so this controller never has
/// to manage optimistic state itself.
///
/// Action methods (add/toggle/delete) just call the repo and return
/// the Either result. The UI doesn't need to roll back because the repo
/// never leaves the local DB in a partial state — writes are atomic.
final class TodosControllerProvider
    extends $StreamNotifierProvider<TodosController, List<Todo>> {
  /// Todos controller — much simpler now that the data layer is offline-first.
  ///
  /// build() listens to the local DB stream via WatchTodos. The local DB
  /// is updated synchronously by the repository on every write and by
  /// the sync service on every remote push, so this controller never has
  /// to manage optimistic state itself.
  ///
  /// Action methods (add/toggle/delete) just call the repo and return
  /// the Either result. The UI doesn't need to roll back because the repo
  /// never leaves the local DB in a partial state — writes are atomic.
  TodosControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'todosControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todosControllerHash();

  @$internal
  @override
  TodosController create() => TodosController();
}

String _$todosControllerHash() => r'75cdfd62dbf64228718822c398cf006c0e585ce8';

/// Todos controller — much simpler now that the data layer is offline-first.
///
/// build() listens to the local DB stream via WatchTodos. The local DB
/// is updated synchronously by the repository on every write and by
/// the sync service on every remote push, so this controller never has
/// to manage optimistic state itself.
///
/// Action methods (add/toggle/delete) just call the repo and return
/// the Either result. The UI doesn't need to roll back because the repo
/// never leaves the local DB in a partial state — writes are atomic.

abstract class _$TodosController extends $StreamNotifier<List<Todo>> {
  Stream<List<Todo>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Todo>>, List<Todo>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Todo>>, List<Todo>>,
              AsyncValue<List<Todo>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
