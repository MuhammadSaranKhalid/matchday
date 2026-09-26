import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/post.dart';
import '../../domain/entities/post_media.dart';
import '../datasources/media_url_factory.dart';
import 'post_media_dto.dart';

part 'post_dto.freezed.dart';
part 'post_dto.g.dart';

@freezed
abstract class PostPublisherDto with _$PostPublisherDto {
  const factory PostPublisherDto({
    required String id,
    @Default('user') String type,
    @JsonKey(name: 'display_name') required String displayName,
    String? username,
    @JsonKey(name: 'photo_url') String? photoUrl,
  }) = _PostPublisherDto;

  const PostPublisherDto._();

  factory PostPublisherDto.fromJson(Map<String, dynamic> json) =>
      _$PostPublisherDtoFromJson(json);

  PostPublisher toEntity() => PostPublisher(
        id: id,
        type: switch (type) {
          'team' => PostPublisherType.team,
          'tournament' => PostPublisherType.tournament,
          _ => PostPublisherType.user,
        },
        displayName: displayName,
        username: username,
        photoUrl: photoUrl,
      );
}

@freezed
abstract class PostCountsDto with _$PostCountsDto {
  const factory PostCountsDto({
    @Default(0) int likes,
    @Default(0) int comments,
    @Default(0) int shares,
  }) = _PostCountsDto;

  const PostCountsDto._();

  factory PostCountsDto.fromJson(Map<String, dynamic> json) =>
      _$PostCountsDtoFromJson(json);

  PostCounts toEntity() => PostCounts(
        likes: likes,
        comments: comments,
        shares: shares,
      );
}

@freezed
abstract class PostViewerInteractionsDto with _$PostViewerInteractionsDto {
  const factory PostViewerInteractionsDto({
    @JsonKey(name: 'is_liked') @Default(false) bool isLiked,
    @JsonKey(name: 'liked') @Default(false) bool liked,
    @JsonKey(name: 'is_bookmarked') @Default(false) bool isBookmarked,
    @JsonKey(name: 'bookmarked') @Default(false) bool bookmarked,
    @JsonKey(name: 'is_following_publisher')
    @Default(false)
    bool isFollowingPublisher,
    @JsonKey(name: 'following_publisher')
    @Default(false)
    bool followingPublisher,
    @JsonKey(name: 'bookmarked_at') String? bookmarkedAt,
  }) = _PostViewerInteractionsDto;

  const PostViewerInteractionsDto._();

  factory PostViewerInteractionsDto.fromJson(Map<String, dynamic> json) =>
      _$PostViewerInteractionsDtoFromJson(json);

  PostViewerInteractions toEntity() => PostViewerInteractions(
        isLiked: isLiked || liked,
        isBookmarked: isBookmarked || bookmarked,
        isFollowingPublisher: isFollowingPublisher || followingPublisher,
        bookmarkedAt:
            bookmarkedAt != null ? DateTime.tryParse(bookmarkedAt!) : null,
      );
}

@freezed
abstract class PostDto with _$PostDto {
  const factory PostDto({
    @JsonKey(name: 'post_id') required String postId,
    @JsonKey(name: 'created_by_user_id') String? createdByUserId,
    @JsonKey(name: 'author_id') String? authorId,
    Map<String, dynamic>? publisher,
    @JsonKey(name: 'post_kind') @Default('standard') String postKind,
    @JsonKey(name: 'post_type') String? postType,
    String? text,
    @Default('public') String visibility,
    @Default('active') String status,
    @JsonKey(name: 'expected_media_count') @Default(0) int expectedMediaCount,
    @Default(<dynamic>[]) List<dynamic> media,
    Map<String, dynamic>? counts,
    Map<String, dynamic>? viewer,
    @JsonKey(name: 'published_at') String? publishedAt,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'linked_match_id') String? linkedMatchId,
    @JsonKey(name: 'linked_tournament_id') String? linkedTournamentId,
    @JsonKey(name: 'linked_team_id') String? linkedTeamId,
    Map<String, dynamic>? author,
    Map<String, dynamic>? team,
    @JsonKey(name: 'is_liked') @Default(false) bool isLiked,
    @JsonKey(name: 'is_bookmarked') @Default(false) bool isBookmarked,
    @JsonKey(name: 'likes_count') @Default(0) int likesCount,
    @JsonKey(name: 'comments_count') @Default(0) int commentsCount,
    @JsonKey(name: 'shares_count') @Default(0) int sharesCount,
  }) = _PostDto;

  const PostDto._();

  factory PostDto.fromJson(Map<String, dynamic> json) =>
      _$PostDtoFromJson(json);

  Post toEntity({
    bool? isLikedOverride,
    bool? isBookmarkedOverride,
    MediaUrlFactory? urlFactory,
  }) {
    final effectiveUserId = createdByUserId ?? authorId ?? '';

    // Parse publisher from consolidated projection or legacy author/team joins
    final effectivePublisher = publisher != null
        ? PostPublisherDto.fromJson(publisher!).toEntity()
        : (team != null
            ? PostPublisher(
                id: linkedTeamId ?? '',
                type: PostPublisherType.team,
                displayName: team!['team_name'] as String? ?? 'Team',
                photoUrl: team!['logo_url'] as String?,
              )
            : PostPublisher(
                id: effectiveUserId,
                type: PostPublisherType.user,
                displayName: author?['display_name'] as String? ?? 'Player',
                username: author?['username'] as String?,
                photoUrl: author?['profile_photo_url'] as String?,
              ));

    // Parse counts
    final effectiveCounts = counts != null
        ? PostCountsDto.fromJson(counts!).toEntity()
        : PostCounts(
            likes: likesCount,
            comments: commentsCount,
            shares: sharesCount,
          );

    // Parse viewer state
    final effectiveViewer = viewer != null
        ? PostViewerInteractionsDto.fromJson(viewer!).toEntity()
        : PostViewerInteractions(
            isLiked: isLikedOverride ?? isLiked,
            isBookmarked: isBookmarkedOverride ?? isBookmarked,
            isFollowingPublisher: false,
          );

    return Post(
      id: PostId(postId),
      createdByUserId: effectiveUserId,
      publisher: effectivePublisher,
      kind: _parsePostKind(postKind, postType),
      text: text,
      visibility: _parseVisibility(visibility),
      status: _parseStatus(status),
      expectedMediaCount: expectedMediaCount,
      media: _parseMediaList(urlFactory),
      counts: effectiveCounts,
      viewer: effectiveViewer,
      publishedAt:
          publishedAt != null ? DateTime.tryParse(publishedAt!) : null,
      createdAt: DateTime.parse(createdAt),
      linkedMatchId: linkedMatchId,
      linkedTournamentId: linkedTournamentId,
      linkedTeamId: linkedTeamId,
    );
  }

  List<PostMedia> _parseMediaList([MediaUrlFactory? urlFactory]) {
    if (media.isNotEmpty) {
      return media.whereType<Map<String, dynamic>>().map((m) {
        if (m.containsKey('media_id')) {
          return PostMediaDto.fromJson(m).toEntity(urlFactory);
        }
        // Legacy fallback shape: { url, blurhash, width, height }
        final url = m['url'] as String? ?? '';
        final blurhash = m['blurhash'] as String?;
        final width = (m['width'] as num?)?.toInt() ?? 1080;
        final height = (m['height'] as num?)?.toInt() ?? 1080;
        return PostMedia(
          mediaId: url,
          postId: postId,
          position: 0,
          width: width,
          height: height,
          blurhash: blurhash,
        );
      }).toList();
    }

    return const [];
  }

  static PostKind _parsePostKind(String kind, String? legacyType) =>
      switch (kind) {
        'recruitment' => PostKind.recruitment,
        'match_announcement' => PostKind.matchAnnouncement,
        'match_result' => PostKind.matchResult,
        'tournament_update' => PostKind.tournamentUpdate,
        'roster_update' => PostKind.rosterUpdate,
        'milestone' => PostKind.milestone,
        _ => switch (legacyType) {
            'recruitment' => PostKind.recruitment,
            'match_announcement' => PostKind.matchAnnouncement,
            'tournament_update' => PostKind.tournamentUpdate,
            _ => PostKind.standard,
          },
      };

  static PostVisibility _parseVisibility(String v) => switch (v) {
        'followers_only' => PostVisibility.followersOnly,
        'private' => PostVisibility.private,
        _ => PostVisibility.public,
      };

  static PostStatus _parseStatus(String s) => switch (s) {
        'publishing' => PostStatus.publishing,
        'hidden' => PostStatus.hidden,
        'reported' => PostStatus.reported,
        'deleted' => PostStatus.deleted,
        _ => PostStatus.active,
      };
}
