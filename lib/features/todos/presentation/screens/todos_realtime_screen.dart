import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/todo.dart';
import '../controllers/todos_controller.dart';
import '../providers/todos_providers.dart';

/// Alternative Todos screen — same UI, but reads from the real-time
/// stream provider instead of the CRUD AsyncNotifier.
///
/// Trade-off: list updates are pushed by the server (instant on other
/// devices), but mutations still go through todosControllerProvider
/// because the stream provider is read-only. The local controller
/// rolls back optimistically on failure exactly as before — the next
/// stream emission will overwrite with server truth either way.
///
/// To wire this in, replace SignInScreen → TodosScreen with this in
/// app_router.dart, or add it as a separate route.
class TodosRealtimeScreen extends ConsumerWidget {
  const TodosRealtimeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todosAsync = ref.watch(todosStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Todos'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: _LiveBadge(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: todosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('$err')),
        data: (todos) => todos.isEmpty
            ? const Center(child: Text('Nothing here yet'))
            : ListView.separated(
                itemCount: todos.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) => _TodoTile(todo: todos[i]),
              ),
      ),
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

    // Writes still go through the CRUD controller. The stream provider
    // will emit the updated list once Supabase echoes the insert.
    final result =
        await ref.read(todosControllerProvider.notifier).add(title);
    if (!context.mounted) return;
    result.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(f.message)),
      ),
      (_) {},
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
      onDismissed: (_) {
        ref.read(todosControllerProvider.notifier).delete(todo.id);
      },
      child: CheckboxListTile(
        value: todo.completed,
        title: Text(
          todo.title,
          style: TextStyle(
            decoration: todo.completed ? TextDecoration.lineThrough : null,
          ),
        ),
        onChanged: (_) =>
            ref.read(todosControllerProvider.notifier).toggle(todo.id),
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.green.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          'LIVE',
          style: TextStyle(
            color: Colors.green.shade900,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      );
}
