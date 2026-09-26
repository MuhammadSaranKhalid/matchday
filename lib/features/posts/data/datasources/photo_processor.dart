import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/post_draft.dart';
import '../../domain/repositories/photo_picker.dart';

class PhotoProcessor implements PhotoPicker {
  const PhotoProcessor();

  /// Max stored long-edge (max 2048px JPEG normalized source for staging).
  static const _maxEdge = 2048;
  static const _quality = 90;

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
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          hideBottomControls: false,
          aspectRatioPresets: [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9
          ],
        ),
        IOSUiSettings(
          title: 'Adjust',
          aspectRatioPresets: [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9
          ],
        ),
      ],
    );
    if (cropped == null) return null;

    final String sourceForCompression = await File(cropped.path).exists() 
        ? cropped.path 
        : picked.path;

    final dir = await getTemporaryDirectory();
    final target =
        '${dir.path}/mday_${DateTime.now().microsecondsSinceEpoch}.jpg';
        
    // Native resize/compress (runs off the Dart main isolate).
    XFile? out;
    try {
      out = await FlutterImageCompress.compressAndGetFile(
        sourceForCompression,
        target,
        minWidth: _maxEdge,
        minHeight: _maxEdge,
        quality: _quality,
        format: CompressFormat.jpeg,
      );
    } catch (_) {
      out = null;
    }

    // Fail cleanly if canonical JPEG compression failed rather than uploading unknown bytes (Point 4)
    if (out == null || !await File(out.path).exists()) {
      return null;
    }

    final file = File(out.path);
    // Dimensions from the header only (no full pure-Dart decode).
    final (width, height) = await _dimensions(file);

    return ProcessedPhoto(
      file: file,
      width: width,
      height: height,
    );
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
