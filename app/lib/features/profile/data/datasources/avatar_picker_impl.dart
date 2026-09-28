import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/repositories/avatar_picker.dart';

/// Pick from gallery → locked 1:1 crop → resize to ≤512px JPEG. Avatars are
/// small and square, so 512px is ample and keeps uploads tiny.
class AvatarPickerImpl implements AvatarPicker {
  const AvatarPickerImpl();

  static const _edge = 512;

  /// The canvas asks for at least 1200 x 400. The strip renders 390 x 112, so
  /// 1200 wide is a 3x asset on the widest phone and still a small upload.
  static const _coverWidth = 1200;
  static const _coverHeight = 400;

  @override
  Future<File?> pickSquare() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      requestFullMetadata: false,
    );
    if (picked == null) return null;

    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Adjust',
          lockAspectRatio: true,
          hideBottomControls: true,
        ),
        IOSUiSettings(title: 'Adjust', aspectRatioLockEnabled: true),
      ],
    );
    if (cropped == null) return null;

    final dir = await getTemporaryDirectory();
    final target =
        '${dir.path}/avatar_${DateTime.now().microsecondsSinceEpoch}.jpg';
    final out = await FlutterImageCompress.compressAndGetFile(
      cropped.path,
      target,
      minWidth: _edge,
      minHeight: _edge,
      quality: 80,
      format: CompressFormat.jpeg,
    );
    return out == null ? null : File(out.path);
  }

  @override
  Future<File?> pickCover() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      requestFullMetadata: false,
    );
    if (picked == null) return null;

    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(ratioX: 3, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Adjust cover',
          lockAspectRatio: true,
          hideBottomControls: true,
        ),
        IOSUiSettings(title: 'Adjust cover', aspectRatioLockEnabled: true),
      ],
    );
    if (cropped == null) return null;

    final dir = await getTemporaryDirectory();
    final target =
        '${dir.path}/cover_${DateTime.now().microsecondsSinceEpoch}.jpg';
    final out = await FlutterImageCompress.compressAndGetFile(
      cropped.path,
      target,
      minWidth: _coverWidth,
      minHeight: _coverHeight,
      quality: 80,
      format: CompressFormat.jpeg,
    );
    return out == null ? null : File(out.path);
  }
}
