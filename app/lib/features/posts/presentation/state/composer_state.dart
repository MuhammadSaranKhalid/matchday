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
    @Default(PostPublisherSelection.user) PostPublisherSelection publisher,
    @Default(PostKind.standard) PostKind postKind,
    String? linkedMatchId,
    String? linkedTournamentId,
    String? linkedTeamId,
  }) = _ComposerState;

  const ComposerState._();

  static const maxPhotos = 4;
  bool get canAddPhoto => photos.length < maxPhotos;
}
