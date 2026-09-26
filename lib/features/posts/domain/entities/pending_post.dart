import 'package:equatable/equatable.dart';

enum PendingPostStatus {
  uploading,
  publishing,
  failed,
}

/// A post created on this device that is currently uploading source images
/// or waiting for server-side feed-ready processing.
/// Pure Dart (Domain).
class PendingPost extends Equatable {
  const PendingPost({
    required this.postId,
    this.text,
    this.localMediaPaths = const [],
    required this.createdAt,
    this.status = PendingPostStatus.uploading,
    this.progress = 0.0,
    this.errorMessage,
  });

  final String postId;
  final String? text;
  final List<String> localMediaPaths;
  final DateTime createdAt;
  final PendingPostStatus status;
  final double progress;
  final String? errorMessage;

  PendingPost copyWith({
    String? postId,
    String? text,
    List<String>? localMediaPaths,
    DateTime? createdAt,
    PendingPostStatus? status,
    double? progress,
    String? errorMessage,
  }) =>
      PendingPost(
        postId: postId ?? this.postId,
        text: text ?? this.text,
        localMediaPaths: localMediaPaths ?? this.localMediaPaths,
        createdAt: createdAt ?? this.createdAt,
        status: status ?? this.status,
        progress: progress ?? this.progress,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  @override
  List<Object?> get props => [
        postId,
        text,
        localMediaPaths,
        createdAt,
        status,
        progress,
        errorMessage,
      ];
}
