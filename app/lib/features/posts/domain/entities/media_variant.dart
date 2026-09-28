import 'package:equatable/equatable.dart';

/// Representation of a single responsive WebP derivative (360, 540, 720, 1080, 2048).
/// Pure Dart (Domain).
class MediaVariant extends Equatable {
  const MediaVariant({
    required this.path,
    String? url,
    required this.width,
    required this.height,
    required this.sizeBytes,
    required this.mimeType,
  }) : _url = url;

  final String path;
  final String? _url;
  final int width;
  final int height;
  final int sizeBytes;
  final String mimeType;

  String get url {
    final u = _url;
    return (u != null && u.isNotEmpty) ? u : path;
  }

  @override
  List<Object?> get props => [path, _url, width, height, sizeBytes, mimeType];
}
