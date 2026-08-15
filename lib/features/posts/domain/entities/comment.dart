import 'package:freezed_annotation/freezed_annotation.dart';

part 'comment.freezed.dart';

enum CommentStatus {
  active,
  deleted,
  reported;

  static CommentStatus fromString(String val) {
    return switch (val.toLowerCase()) {
      'deleted' => CommentStatus.deleted,
      'reported' => CommentStatus.reported,
      _ => CommentStatus.active,
    };
  }
}

@freezed
abstract class Comment with _$Comment {
  const factory Comment({
    required String id,
    required String postId,
    required String authorId,
    String? parentCommentId,
    required String text,
    @Default([]) List<String> mentionedUserIds,
    @Default(0) int likesCount,
    @Default(false) bool isLiked,
    @Default(CommentStatus.active) CommentStatus status,
    required DateTime createdAt,
    DateTime? editedAt,
    String? authorName,
    String? authorUsername,
    String? authorPhotoUrl,
    @Default([]) List<Comment> replies,
  }) = _Comment;

  const Comment._();

  /// Two-letter monogram for the commenter's avatar.
  String get authorMonogram {
    final n = (authorName ?? '').trim();
    if (n.isEmpty) return '?';
    final parts = n.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
    }
    return (parts.first[0] + parts[1][0]).toUpperCase();
  }
}
