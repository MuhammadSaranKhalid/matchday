// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CommentDto _$CommentDtoFromJson(Map<String, dynamic> json) => _CommentDto(
  commentId: json['comment_id'] as String,
  postId: json['post_id'] as String,
  authorId: json['author_id'] as String,
  parentCommentId: json['parent_comment_id'] as String?,
  text: json['text'] as String,
  mentionedUserIds:
      (json['mentioned_user_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
  isLiked: json['is_liked'] as bool? ?? false,
  status: json['status'] as String? ?? 'active',
  createdAt: json['created_at'] as String,
  editedAt: json['edited_at'] as String?,
  author: json['author'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$CommentDtoToJson(_CommentDto instance) =>
    <String, dynamic>{
      'comment_id': instance.commentId,
      'post_id': instance.postId,
      'author_id': instance.authorId,
      'parent_comment_id': instance.parentCommentId,
      'text': instance.text,
      'mentioned_user_ids': instance.mentionedUserIds,
      'likes_count': instance.likesCount,
      'is_liked': instance.isLiked,
      'status': instance.status,
      'created_at': instance.createdAt,
      'edited_at': instance.editedAt,
      'author': instance.author,
    };
