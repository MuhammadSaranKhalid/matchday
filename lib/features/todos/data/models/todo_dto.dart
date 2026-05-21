import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/todo.dart';

part 'todo_dto.freezed.dart';
part 'todo_dto.g.dart';

/// Wire-format todo. Carries [updatedAt] from Supabase for LWW sync.
///
/// Freezed 3.x: `abstract class` + private `_()` constructor (the latter
/// is required because we add a custom [toEntity] instance method).
@freezed
abstract class TodoDto with _$TodoDto {
  const factory TodoDto({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    required String title,
    required bool completed,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'updated_at') required String updatedAt,
  }) = _TodoDto;

  const TodoDto._();

  factory TodoDto.fromJson(Map<String, dynamic> json) =>
      _$TodoDtoFromJson(json);

  Todo toEntity() => Todo(
        id: TodoId(id),
        title: title,
        completed: completed,
        createdAt: DateTime.parse(createdAt),
        updatedAt: DateTime.parse(updatedAt),
      );
}
