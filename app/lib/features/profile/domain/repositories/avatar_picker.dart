import 'dart:io';

/// Picks + square-crops + resizes an avatar image. The implementation
/// (image_picker → 1:1 crop → compress) lives in the data layer; the edit
/// controller depends only on this abstraction. Returns null if cancelled.
abstract class AvatarPicker {
  Future<File?> pickSquare();

  /// Picks + 3:1-crops + resizes a cover image (artboard 1a). The profile
  /// header shows a cover, so the edit screen has to own it — otherwise the
  /// placeholder on the profile is unreachable. Returns null if cancelled.
  Future<File?> pickCover();
}
