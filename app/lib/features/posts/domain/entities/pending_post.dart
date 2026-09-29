import 'package:equatable/equatable.dart';

import 'post.dart';

enum PendingPostStatus { uploading, publishing, failed, cancelRequested }

/// A specific media asset attached to a pending post, persisting the exact
/// staging and server contracts for deterministic retry.
class PendingMediaItem extends Equatable {
  const PendingMediaItem({
    required this.mediaId,
    required this.position,
    required this.localPath,
    required this.stagingPath,
    this.uploadToken,
    this.width = 0,
    this.height = 0,
    this.bytes = 0,
    this.uploaded = false,
  });

  final String mediaId;
  final int position;
  final String localPath;
  final String stagingPath;
  final String? uploadToken;
  final int width;
  final int height;
  final int bytes;
  final bool uploaded;

  PendingMediaItem copyWith({
    String? mediaId,
    int? position,
    String? localPath,
    String? stagingPath,
    String? uploadToken,
    int? width,
    int? height,
    int? bytes,
    bool? uploaded,
  }) => PendingMediaItem(
    mediaId: mediaId ?? this.mediaId,
    position: position ?? this.position,
    localPath: localPath ?? this.localPath,
    stagingPath: stagingPath ?? this.stagingPath,
    uploadToken: uploadToken ?? this.uploadToken,
    width: width ?? this.width,
    height: height ?? this.height,
    bytes: bytes ?? this.bytes,
    uploaded: uploaded ?? this.uploaded,
  );

  @override
  List<Object?> get props => [
    mediaId,
    position,
    localPath,
    stagingPath,
    uploadToken,
    width,
    height,
    bytes,
    uploaded,
  ];
}

/// A post created on this device that is currently uploading source images
/// or waiting for server-side feed-ready processing.
/// Pure Dart (Domain).
class PendingPost extends Equatable {
  const PendingPost({
    required this.postId,
    this.clientCommandId = '',
    this.text,
    this.media = const [],
    required this.createdAt,
    this.status = PendingPostStatus.uploading,
    this.progress = 0.0,
    this.errorMessage,
    this.publisherType = 'user',
    this.publisherId = '',
    this.postKind = 'standard',
    this.optimisticPost,
  });

  final String postId;
  final String clientCommandId;
  final String? text;
  final List<PendingMediaItem> media;
  final DateTime createdAt;
  final PendingPostStatus status;
  final double progress;
  final String? errorMessage;
  final String publisherType;
  final String publisherId;
  final String postKind;
  final Post? optimisticPost;

  PendingPost copyWith({
    String? postId,
    String? clientCommandId,
    String? text,
    List<PendingMediaItem>? media,
    DateTime? createdAt,
    PendingPostStatus? status,
    double? progress,
    String? errorMessage,
    String? publisherType,
    String? publisherId,
    String? postKind,
    Post? optimisticPost,
  }) => PendingPost(
    postId: postId ?? this.postId,
    clientCommandId: clientCommandId ?? this.clientCommandId,
    text: text ?? this.text,
    media: media ?? this.media,
    createdAt: createdAt ?? this.createdAt,
    status: status ?? this.status,
    progress: progress ?? this.progress,
    errorMessage: errorMessage ?? this.errorMessage,
    publisherType: publisherType ?? this.publisherType,
    publisherId: publisherId ?? this.publisherId,
    postKind: postKind ?? this.postKind,
    optimisticPost: optimisticPost ?? this.optimisticPost,
  );

  @override
  List<Object?> get props => [
    postId,
    clientCommandId,
    text,
    media,
    createdAt,
    status,
    progress,
    errorMessage,
    publisherType,
    publisherId,
    postKind,
    optimisticPost,
  ];
}
