import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/comment.dart';

part 'comment_dto.freezed.dart';
part 'comment_dto.g.dart';

@freezed
abstract class CommentDto with _$CommentDto {
  const factory CommentDto({
    @JsonKey(name: 'comment_id') required String commentId,
    @JsonKey(name: 'post_id') required String postId,
    @JsonKey(name: 'author_id') required String authorId,
    @JsonKey(name: 'parent_comment_id') String? parentCommentId,
    required String text,
    @JsonKey(name: 'mentioned_user_ids')
    @Default(<String>[])
    List<String> mentionedUserIds,
    @JsonKey(name: 'likes_count') @Default(0) int likesCount,
    @JsonKey(name: 'is_liked') @Default(false) bool isLiked,
    @JsonKey(name: 'replies_count') @Default(0) int repliesCount,
    @Default('active') String status,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'edited_at') String? editedAt,
    Map<String, dynamic>? author,
  }) = _CommentDto;

  const CommentDto._();

  factory CommentDto.fromJson(Map<String, dynamic> json) =>
      _$CommentDtoFromJson(json);

  Comment toEntity({bool? isLikedOverride, List<Comment> replies = const []}) =>
      Comment(
        id: commentId,
        postId: postId,
        authorId: authorId,
        parentCommentId: parentCommentId,
        text: text,
        mentionedUserIds: mentionedUserIds,
        likesCount: likesCount,
        isLiked: isLikedOverride ?? isLiked,
        repliesCount: repliesCount,
        status: CommentStatus.fromString(status),
        createdAt: DateTime.parse(createdAt),
        editedAt: editedAt == null ? null : DateTime.tryParse(editedAt!),
        authorName: author?['display_name'] as String?,
        authorUsername: author?['username'] as String?,
        authorPhotoUrl: author?['profile_photo_url'] as String?,
        replies: replies,
      );
}
