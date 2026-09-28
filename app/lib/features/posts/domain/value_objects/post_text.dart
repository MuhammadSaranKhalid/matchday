import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';

/// Value object encapsulating feed post text constraints.
/// Pure Dart (Domain).
class PostText extends Equatable {
  const PostText._(this.value);

  final String? value;

  static const int maxLength = 2000;

  static Either<ValidationFailure, PostText> create(
    String? input, {
    required bool hasPhotos,
  }) {
    final trimmed = input?.trim();
    final hasText = trimmed != null && trimmed.isNotEmpty;

    if (!hasText && !hasPhotos) {
      return const Left(
        ValidationFailure('Add some text or a photo to post.'),
      );
    }

    if (hasText && trimmed.length > maxLength) {
      return const Left(
        ValidationFailure('Post cannot exceed $maxLength characters.'),
      );
    }

    return Right(PostText._(hasText ? trimmed : null));
  }

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value ?? '';
}
