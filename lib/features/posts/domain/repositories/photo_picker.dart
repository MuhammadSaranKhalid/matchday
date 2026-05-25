import 'dart:io';

import '../entities/post_draft.dart';

/// Pick + adjust + process a single photo for the composer. The implementation
/// (gallery pick → crop → resize → blurhash) lives in the data layer; the
/// composer depends only on this abstraction.
abstract class PhotoPicker {
  /// Pick → crop → resize. Returns FAST with the file + dimensions and
  /// `hashPending: true` (the BlurHash is computed separately so the thumbnail
  /// can show immediately). Null if the user cancelled.
  Future<ProcessedPhoto?> pickOne();

  /// Compute the BlurHash for an already-processed photo (off the main isolate,
  /// from a tiny downscaled copy). Returns '' on failure.
  Future<String> blurHashFor(File file);
}
