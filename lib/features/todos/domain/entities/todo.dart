class Todo {
  const Todo({
    required this.id,
    required this.title,
    required this.completed,
    required this.createdAt,
    required this.updatedAt,
  });

  final TodoId id;
  final String title;
  final bool completed;
  final DateTime createdAt;

  /// Last modification timestamp. Drives LWW conflict resolution at the
  /// data layer, but is also a real business attribute the UI may surface.
  final DateTime updatedAt;

  Todo copyWith({String? title, bool? completed, DateTime? updatedAt}) => Todo(
        id: id,
        title: title ?? this.title,
        completed: completed ?? this.completed,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Todo &&
          other.id == id &&
          other.title == title &&
          other.completed == completed &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt;

  @override
  int get hashCode =>
      Object.hash(id, title, completed, createdAt, updatedAt);
}

class TodoId {
  const TodoId(this.value);
  final String value;
  @override
  bool operator ==(Object other) => other is TodoId && other.value == value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => value;
}
