import 'package:equatable/equatable.dart';

/// Server-reconciled outcome of a desired-state post like mutation.
class PostLikeResult extends Equatable {
  const PostLikeResult({
    required this.isLiked,
    required this.likesCount,
  });

  final bool isLiked;
  final int likesCount;

  @override
  List<Object?> get props => [isLiked, likesCount];
}
