// On-device photo pipeline for the composer:
//   pick (gallery) → crop/adjust → resize ≤1080px JPEG  (pickOne, fast)
//   tiny 32px copy → decode + BlurHash on a background isolate  (blurHashFor)
// Split in two so the thumbnail can show instantly while the BlurHash computes.
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:blurhash_dart/blurhash_dart.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/post_draft.dart';
import '../../domain/repositories/photo_picker.dart';

class PhotoProcessor implements PhotoPicker {
  const PhotoProcessor();

  /// Max stored long-edge (Instagram-style). Feed decodes smaller; the viewer
  /// uses this same file.
  static const _maxEdge = 1080;
  static const _quality = 75;

  @override
  Future<ProcessedPhoto?> pickOne() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      requestFullMetadata: false,
    );
    if (picked == null) return null;

    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Adjust',
          lockAspectRatio: false,
          hideBottomControls: false,
        ),
        IOSUiSettings(title: 'Adjust'),
      ],
    );
    if (cropped == null) return null;

    final dir = await getTemporaryDirectory();
    final target =
        '${dir.path}/mday_${DateTime.now().microsecondsSinceEpoch}.jpg';
    // Native resize/compress (runs off the Dart main isolate).
    final out = await FlutterImageCompress.compressAndGetFile(
      cropped.path,
      target,
      minWidth: _maxEdge,
      minHeight: _maxEdge,
      quality: _quality,
      format: CompressFormat.jpeg,
    );
    if (out == null) return null;

    final file = File(out.path);
    // Dimensions from the header only (no full pure-Dart decode).
    final (width, height) = await _dimensions(file);

    // Return immediately; BlurHash is computed separately via [blurHashFor].
    return ProcessedPhoto(
      file: file,
      blurhash: '',
      width: width,
      height: height,
      hashPending: true,
    );
  }

  @override
  Future<String> blurHashFor(File file) async {
    try {
      final bytes = await file.readAsBytes();
      // Decode + encode the full (≤1080px) image on a background isolate so the
      // UI never freezes. Per the Isolate.run docs, hand a top-level function
      // explicit args (`bytes`) instead of an inline closure, so no enclosing
      // instance state is implicitly captured/copied across the boundary. Only
      // the immutable Uint8List goes in and the String hash comes out.
      return await Isolate.run(() => _encodeBlurHash(bytes));
    } catch (_) {
      return '';
    }
  }

  /// Header-only width/height via Flutter's native codec (no full decode).
  Future<(int, int)> _dimensions(File file) async {
    try {
      final bytes = await file.readAsBytes(); // already a Uint8List
      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      final size = (descriptor.width, descriptor.height);
      descriptor.dispose();
      buffer.dispose();
      return size;
    } catch (_) {
      return (0, 0);
    }
  }
}

/// Decode + BlurHash-encode raw image bytes. Top-level (not a closure/instance
/// method) so `Isolate.run` copies only [bytes] across the boundary — per the
/// Isolate.run API guidance to pass state as explicit arguments. Runs entirely
/// inside the spawned isolate; returns '' on failure.
String _encodeBlurHash(Uint8List bytes) {
  final image = img.decodeImage(bytes);
  if (image == null) return '';
  return BlurHash.encode(image, numCompX: 4, numCompY: 3).hash;
}
