import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/post_draft.dart';

part 'composer_state.freezed.dart';

@freezed
abstract class ComposerState with _$ComposerState {
  const factory ComposerState({
    @Default([]) List<ProcessedPhoto> photos,
    @Default(false) bool busy,
    Failure? error,
    @Default(PostAuthorContext.personal) PostAuthorContext authorContext,
    String? contextEntityId,
    String? entityName,
    String? entityMono,
  }) = _ComposerState;

  const ComposerState._();

  static const maxPhotos = 4;
  bool get canAddPhoto => photos.length < maxPhotos;
}
