// On-device photo pipeline for the composer:
//   pick (gallery) → crop/adjust → resize ≤1080px JPEG → BlurHash + dimensions.
// Produces a [ProcessedPhoto] the repository uploads as-is.
import 'dart:io';

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

  /// Pick one image, let the user crop/adjust it, then resize + compress.
  /// Returns null if the user cancelled at any step.
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
    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);

    var hash = '';
    var width = 0;
    var height = 0;
    if (decoded != null) {
      width = decoded.width;
      height = decoded.height;
      try {
        hash = BlurHash.encode(decoded, numCompX: 4, numCompY: 3).hash;
      } catch (_) {
        // BlurHash is a nicety; a missing one just means a plain placeholder.
      }
    }

    return ProcessedPhoto(
      file: file,
      blurhash: hash,
      width: width,
      height: height,
    );
  }
}
