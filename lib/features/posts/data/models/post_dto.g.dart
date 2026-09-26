// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PostPublisherDto _$PostPublisherDtoFromJson(Map<String, dynamic> json) =>
    _PostPublisherDto(
      id: json['id'] as String,
      type: json['type'] as String? ?? 'user',
      displayName: json['display_name'] as String,
      username: json['username'] as String?,
      photoUrl: json['photo_url'] as String?,
    );

Map<String, dynamic> _$PostPublisherDtoToJson(_PostPublisherDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'display_name': instance.displayName,
      'username': instance.username,
      'photo_url': instance.photoUrl,
    };

_PostCountsDto _$PostCountsDtoFromJson(Map<String, dynamic> json) =>
    _PostCountsDto(
      likes: (json['likes'] as num?)?.toInt() ?? 0,
      comments: (json['comments'] as num?)?.toInt() ?? 0,
      shares: (json['shares'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$PostCountsDtoToJson(_PostCountsDto instance) =>
    <String, dynamic>{
      'likes': instance.likes,
      'comments': instance.comments,
      'shares': instance.shares,
    };

_PostViewerInteractionsDto _$PostViewerInteractionsDtoFromJson(
  Map<String, dynamic> json,
) => _PostViewerInteractionsDto(
  liked: json['liked'] as bool? ?? false,
  bookmarked: json['bookmarked'] as bool? ?? false,
  followingPublisher: json['following_publisher'] as bool? ?? false,
);

Map<String, dynamic> _$PostViewerInteractionsDtoToJson(
  _PostViewerInteractionsDto instance,
) => <String, dynamic>{
  'liked': instance.liked,
  'bookmarked': instance.bookmarked,
  'following_publisher': instance.followingPublisher,
};

_PostDto _$PostDtoFromJson(Map<String, dynamic> json) => _PostDto(
  postId: json['post_id'] as String,
  createdByUserId: json['created_by_user_id'] as String?,
  authorId: json['author_id'] as String?,
  publisher: json['publisher'] as Map<String, dynamic>?,
  postKind: json['post_kind'] as String? ?? 'standard',
  postType: json['post_type'] as String?,
  text: json['text'] as String?,
  visibility: json['visibility'] as String? ?? 'public',
  status: json['status'] as String? ?? 'active',
  expectedMediaCount: (json['expected_media_count'] as num?)?.toInt() ?? 0,
  media: json['media'] as List<dynamic>? ?? const <dynamic>[],
  counts: json['counts'] as Map<String, dynamic>?,
  viewer: json['viewer'] as Map<String, dynamic>?,
  publishedAt: json['published_at'] as String?,
  createdAt: json['created_at'] as String,
  linkedMatchId: json['linked_match_id'] as String?,
  linkedTournamentId: json['linked_tournament_id'] as String?,
  linkedTeamId: json['linked_team_id'] as String?,
  author: json['author'] as Map<String, dynamic>?,
  team: json['team'] as Map<String, dynamic>?,
  isLiked: json['is_liked'] as bool? ?? false,
  isBookmarked: json['is_bookmarked'] as bool? ?? false,
  likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
  commentsCount: (json['comments_count'] as num?)?.toInt() ?? 0,
  sharesCount: (json['shares_count'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$PostDtoToJson(_PostDto instance) => <String, dynamic>{
  'post_id': instance.postId,
  'created_by_user_id': instance.createdByUserId,
  'author_id': instance.authorId,
  'publisher': instance.publisher,
  'post_kind': instance.postKind,
  'post_type': instance.postType,
  'text': instance.text,
  'visibility': instance.visibility,
  'status': instance.status,
  'expected_media_count': instance.expectedMediaCount,
  'media': instance.media,
  'counts': instance.counts,
  'viewer': instance.viewer,
  'published_at': instance.publishedAt,
  'created_at': instance.createdAt,
  'linked_match_id': instance.linkedMatchId,
  'linked_tournament_id': instance.linkedTournamentId,
  'linked_team_id': instance.linkedTeamId,
  'author': instance.author,
  'team': instance.team,
  'is_liked': instance.isLiked,
  'is_bookmarked': instance.isBookmarked,
  'likes_count': instance.likesCount,
  'comments_count': instance.commentsCount,
  'shares_count': instance.sharesCount,
};
