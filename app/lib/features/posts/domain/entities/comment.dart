import 'package:equatable/equatable.dart';

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

/// A comment on a post. Pure Dart (Domain) — Equatable, zero framework or wire knowledge.
class Comment extends Equatable {
  const Comment({
    required this.id,
    required this.postId,
    required this.authorId,
    this.parentCommentId,
    required this.text,
    this.mentionedUserIds = const [],
    this.likesCount = 0,
    this.isLiked = false,
    this.repliesCount = 0,
    this.status = CommentStatus.active,
    required this.createdAt,
    this.editedAt,
    this.authorName,
    this.authorUsername,
    this.authorPhotoUrl,
    this.replies = const [],
  });

  final String id;
  final String postId;
  final String authorId;
  final String? parentCommentId;
  final String text;
  final List<String> mentionedUserIds;
  final int likesCount;
  final bool isLiked;
  final int repliesCount;
  final CommentStatus status;
  final DateTime createdAt;
  final DateTime? editedAt;
  final String? authorName;
  final String? authorUsername;
  final String? authorPhotoUrl;
  final List<Comment> replies;

  Comment copyWith({
    String? id,
    String? postId,
    String? authorId,
    String? Function()? parentCommentId,
    String? text,
    List<String>? mentionedUserIds,
    int? likesCount,
    bool? isLiked,
    int? repliesCount,
    CommentStatus? status,
    DateTime? createdAt,
    DateTime? Function()? editedAt,
    String? Function()? authorName,
    String? Function()? authorUsername,
    String? Function()? authorPhotoUrl,
    List<Comment>? replies,
  }) {
    return Comment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      authorId: authorId ?? this.authorId,
      parentCommentId: parentCommentId != null
          ? parentCommentId()
          : this.parentCommentId,
      text: text ?? this.text,
      mentionedUserIds: mentionedUserIds ?? this.mentionedUserIds,
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,
      repliesCount: repliesCount ?? this.repliesCount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      editedAt: editedAt != null ? editedAt() : this.editedAt,
      authorName: authorName != null ? authorName() : this.authorName,
      authorUsername:
          authorUsername != null ? authorUsername() : this.authorUsername,
      authorPhotoUrl:
          authorPhotoUrl != null ? authorPhotoUrl() : this.authorPhotoUrl,
      replies: replies ?? this.replies,
    );
  }

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

  @override
  List<Object?> get props => [
        id,
        postId,
        authorId,
        parentCommentId,
        text,
        mentionedUserIds,
        likesCount,
        isLiked,
        repliesCount,
        status,
        createdAt,
        editedAt,
        authorName,
        authorUsername,
        authorPhotoUrl,
        replies,
      ];
}
