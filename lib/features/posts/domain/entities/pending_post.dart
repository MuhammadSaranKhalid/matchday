import 'package:equatable/equatable.dart';

enum PendingPostStatus {
  uploading,
  publishing,
  failed,
}

/// A specific media asset attached to a pending post, persisting the exact
/// staging and server contracts for deterministic retry.
class PendingMediaItem extends Equatable {
  const PendingMediaItem({
    required this.mediaId,
    required this.position,
    required this.localPath,
    required this.stagingPath,
    this.uploaded = false,
  });

  final String mediaId;
  final int position;
  final String localPath;
  final String stagingPath;
  final bool uploaded;

  PendingMediaItem copyWith({
    String? mediaId,
    int? position,
    String? localPath,
    String? stagingPath,
    bool? uploaded,
  }) =>
      PendingMediaItem(
        mediaId: mediaId ?? this.mediaId,
        position: position ?? this.position,
        localPath: localPath ?? this.localPath,
        stagingPath: stagingPath ?? this.stagingPath,
        uploaded: uploaded ?? this.uploaded,
      );

  @override
  List<Object?> get props => [
        mediaId,
        position,
        localPath,
        stagingPath,
        uploaded,
      ];
}

/// A post created on this device that is currently uploading source images
/// or waiting for server-side feed-ready processing.
/// Pure Dart (Domain).
class PendingPost extends Equatable {
  const PendingPost({
    required this.postId,
    this.text,
    this.media = const [],
    required this.createdAt,
    this.status = PendingPostStatus.uploading,
    this.progress = 0.0,
    this.errorMessage,
  });

  final String postId;
  final String? text;
  final List<PendingMediaItem> media;
  final DateTime createdAt;
  final PendingPostStatus status;
  final double progress;
  final String? errorMessage;

  /// Convenience getter for backward compatibility with UI components.
  List<String> get localMediaPaths => media.map((m) => m.localPath).toList();

  PendingPost copyWith({
    String? postId,
    String? text,
    List<PendingMediaItem>? media,
    DateTime? createdAt,
    PendingPostStatus? status,
    double? progress,
    String? errorMessage,
  }) =>
      PendingPost(
        postId: postId ?? this.postId,
        text: text ?? this.text,
        media: media ?? this.media,
        createdAt: createdAt ?? this.createdAt,
        status: status ?? this.status,
        progress: progress ?? this.progress,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  @override
  List<Object?> get props => [
        postId,
        text,
        media,
        createdAt,
        status,
        progress,
        errorMessage,
      ];
}
