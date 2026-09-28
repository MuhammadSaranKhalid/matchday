import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/post.dart';

/// Normalized query state: holds membership ordering (post IDs), pagination cursors, and status.
/// Canonical Post entities live exclusively inside [PostStore].
class PostQueryState extends Equatable {
  const PostQueryState({
    this.ids = const [],
    this.nextCursorPublishedAt,
    this.nextCursorSavedAt,
    this.nextCursorPostId,
    this.hasMore = true,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  final List<PostId> ids;
  final DateTime? nextCursorPublishedAt;
  final DateTime? nextCursorSavedAt;
  final String? nextCursorPostId;
  final bool hasMore;
  final bool isRefreshing;
  final bool isLoadingMore;
  final Failure? loadMoreError;

  bool get isEmpty => ids.isEmpty;

  PostQueryState copyWith({
    List<PostId>? ids,
    DateTime? Function()? nextCursorPublishedAt,
    DateTime? Function()? nextCursorSavedAt,
    String? Function()? nextCursorPostId,
    bool? hasMore,
    bool? isRefreshing,
    bool? isLoadingMore,
    Failure? Function()? loadMoreError,
  }) {
    return PostQueryState(
      ids: ids ?? this.ids,
      nextCursorPublishedAt: nextCursorPublishedAt != null
          ? nextCursorPublishedAt()
          : this.nextCursorPublishedAt,
      nextCursorSavedAt: nextCursorSavedAt != null
          ? nextCursorSavedAt()
          : this.nextCursorSavedAt,
      nextCursorPostId: nextCursorPostId != null
          ? nextCursorPostId()
          : this.nextCursorPostId,
      hasMore: hasMore ?? this.hasMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreError: loadMoreError != null
          ? loadMoreError()
          : this.loadMoreError,
    );
  }

  @override
  List<Object?> get props => [
        ids,
        nextCursorPublishedAt,
        nextCursorSavedAt,
        nextCursorPostId,
        hasMore,
        isRefreshing,
        isLoadingMore,
        loadMoreError,
      ];
}
