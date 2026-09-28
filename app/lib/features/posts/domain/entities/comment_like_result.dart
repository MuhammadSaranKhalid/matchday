import 'package:equatable/equatable.dart';

/// Canonical server result for desired-state comment like RPC.
class CommentLikeResult extends Equatable {
  const CommentLikeResult({
    required this.commentId,
    required this.isLiked,
    required this.likesCount,
  });

  final String commentId;
  final bool isLiked;
  final int likesCount;

  @override
  List<Object?> get props => [commentId, isLiked, likesCount];
}
