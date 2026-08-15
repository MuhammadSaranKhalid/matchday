import 'dart:io';

/// Picks + square-crops + resizes an avatar image. The implementation
/// (image_picker → 1:1 crop → compress) lives in the data layer; the edit
/// controller depends only on this abstraction. Returns null if cancelled.
abstract class AvatarPicker {
  Future<File?> pickSquare();
}
