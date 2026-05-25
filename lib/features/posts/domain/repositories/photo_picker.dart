import '../entities/post_draft.dart';

/// Pick + adjust + process a single photo for the composer. The implementation
/// (gallery pick → crop → resize → blurhash) lives in the data layer; the
/// composer depends only on this abstraction.
abstract class PhotoPicker {
  /// Returns a processed photo, or null if the user cancelled.
  Future<ProcessedPhoto?> pickOne();
}
