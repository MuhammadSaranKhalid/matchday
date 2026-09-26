import 'package:equatable/equatable.dart';

/// Provider-neutral photo description for reserving a publishing session.
/// Pure Dart (Domain).
class PublishPhoto extends Equatable {
  const PublishPhoto({
    required this.localPath,
    required this.width,
    required this.height,
  });

  final String localPath;
  final int width;
  final int height;

  @override
  List<Object?> get props => [localPath, width, height];
}
