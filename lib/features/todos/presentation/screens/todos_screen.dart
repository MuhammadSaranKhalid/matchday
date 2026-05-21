import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/todo.dart';
import '../controllers/todos_controller.dart';

/// Todos list screen.
///
/// Pattern-matches the AsyncValue with a Dart 3 switch (data/error/loading),
/// plus RefreshIndicator wired to the controller's refresh().
class TodosScreen extends ConsumerWidget {
  const TodosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todosAsync = ref.watch(todosControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Todos')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: switch (todosAsync) {
        AsyncData(:final value) => RefreshIndicator(
            onRefresh: () =>
                ref.read(todosControllerProvider.notifier).refresh(),
            child: value.isEmpty
                ? const _EmptyView()
                : ListView.separated(
                    itemCount: value.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) => _TodoTile(todo: value[i]),
                  ),
          ),
        AsyncError(:final error) => _ErrorView(
            message: error is FailureWrapper
                ? error.failure.message
                : error.toString(),
            onRetry: () => ref.read(todosControllerProvider.notifier).refresh(),
          ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New todo'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'What needs doing?'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (title == null || title.trim().isEmpty || !context.mounted) return;

    final result =
        await ref.read(todosControllerProvider.notifier).add(title);
    if (!context.mounted) return;
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      ),
      (_) {/* nothing — the list already updated optimistically */},
    );
  }
}

class _TodoTile extends ConsumerWidget {
  const _TodoTile({required this.todo});
  final Todo todo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey(todo.id.value),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) async {
        final result =
            await ref.read(todosControllerProvider.notifier).delete(todo.id);
        if (!context.mounted) return;
        result.fold(
          (f) => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(f.message)),
          ),
          (_) {},
        );
      },
      child: CheckboxListTile(
        value: todo.completed,
        title: Text(
          todo.title,
          style: TextStyle(
            decoration: todo.completed ? TextDecoration.lineThrough : null,
          ),
        ),
        onChanged: (_) {
          ref.read(todosControllerProvider.notifier).toggle(todo.id);
        },
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();
  @override
  Widget build(BuildContext context) => const Center(
        child: Text('Nothing here yet. Add one with +'),
      );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
}
