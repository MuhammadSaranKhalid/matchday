import 'package:equatable/equatable.dart';

/// Provider-neutral photo description for reserving a publishing session.
/// Pure Dart (Domain).
class PublishPhoto extends Equatable {
  const PublishPhoto({
    required this.localPath,
    required this.width,
    required this.height,
    this.fileSize = 0,
    this.mimeType = 'image/jpeg',
  });

  final String localPath;
  final int width;
  final int height;
  final int fileSize;
  final String mimeType;

  @override
  List<Object?> get props => [localPath, width, height, fileSize, mimeType];
}
