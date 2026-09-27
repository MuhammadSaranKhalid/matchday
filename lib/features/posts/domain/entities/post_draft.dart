import 'package:equatable/equatable.dart';

import 'post.dart';

/// Preprocessed photo ready for staging upload. Pure Dart (Domain).
class ProcessedPhoto extends Equatable {
  const ProcessedPhoto({
    required this.filePath,
    required this.width,
    required this.height,
    this.fileSize = 0,
  });

  final String filePath;
  final int width;
  final int height;
  final int fileSize;

  @override
  List<Object?> get props => [filePath, width, height, fileSize];
}

/// Selected publisher identity for a post.
class PostPublisherSelection extends Equatable {
  const PostPublisherSelection({
    required this.type,
    this.id,
    this.name,
    this.photoUrl,
    this.monogram,
  });

  final PostPublisherType type;
  final String? id;
  final String? name;
  final String? photoUrl;
  final String? monogram;

  static const user = PostPublisherSelection(type: PostPublisherType.user);

  @override
  List<Object?> get props => [type, id, name, photoUrl, monogram];
}

/// Draft post ready for submission. Pure Dart (Domain) — Equatable.
class PostDraft extends Equatable {
  const PostDraft({
    this.text,
    this.photos = const [],
    this.publisher = PostPublisherSelection.user,
    this.postKind = PostKind.standard,
    this.linkedMatchId,
    this.linkedTournamentId,
    this.linkedTeamId,
  });

  final String? text;
  final List<ProcessedPhoto> photos;
  final PostPublisherSelection publisher;
  final PostKind postKind;
  final String? linkedMatchId;
  final String? linkedTournamentId;
  final String? linkedTeamId;

  bool get hasPhotos => photos.isNotEmpty;

  @override
  List<Object?> get props => [
        text,
        photos,
        publisher,
        postKind,
        linkedMatchId,
        linkedTournamentId,
        linkedTeamId,
      ];
}
