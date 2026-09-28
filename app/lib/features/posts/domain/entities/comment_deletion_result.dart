import 'package:equatable/equatable.dart';

/// Canonical server result for comment deletion RPC.
class CommentDeletionResult extends Equatable {
  const CommentDeletionResult({
    required this.deleted,
    required this.deletedCount,
    this.postId,
    this.remainingCommentsCount,
  });

  final bool deleted;
  final int deletedCount;
  final String? postId;
  final int? remainingCommentsCount;

  @override
  List<Object?> get props => [deleted, deletedCount, postId, remainingCommentsCount];
}
