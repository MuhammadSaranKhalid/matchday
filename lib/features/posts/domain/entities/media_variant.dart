import 'package:equatable/equatable.dart';

/// Representation of a single responsive WebP derivative (360, 540, 720, 1080, 2048).
/// Pure Dart (Domain).
class MediaVariant extends Equatable {
  const MediaVariant({
    required this.path,
    required this.width,
    required this.height,
    required this.sizeBytes,
    required this.mimeType,
  });

  final String path;
  final int width;
  final int height;
  final int sizeBytes;
  final String mimeType;

  String get url => path;

  @override
  List<Object?> get props => [path, width, height, sizeBytes, mimeType];
}
