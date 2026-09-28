import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/repositories/tournament_artwork_picker.dart';

/// On-device pipeline for a tournament's logo and banner.
///
/// Same shape as the posts composer's [PhotoProcessor] — pick → crop →
/// compress — but with the two ratios locked, because these images sit in a
/// fixed slot on the tournament card and share sheet. There is no BlurHash
/// step: `tournaments` has no column to store one.
class TournamentArtworkProcessor implements TournamentArtworkPicker {
  const TournamentArtworkProcessor();

  /// 1080×420, the banner size the create wizard names.
  static const _bannerW = 1080;
  static const _bannerH = 420;

  /// Square, and small — the logo renders as a crest at ~44–92px.
  static const _logoEdge = 512;

  static const _quality = 82;

  @override
  Future<File?> pickBanner() => _pick(
        ratioX: _bannerW.toDouble(),
        ratioY: _bannerH.toDouble(),
        maxWidth: _bannerW,
        maxHeight: _bannerH,
        title: 'Crop banner',
      );

  @override
  Future<File?> pickLogo() => _pick(
        ratioX: 1,
        ratioY: 1,
        maxWidth: _logoEdge,
        maxHeight: _logoEdge,
        title: 'Crop logo',
      );

  Future<File?> _pick({
    required double ratioX,
    required double ratioY,
    required int maxWidth,
    required int maxHeight,
    required String title,
  }) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      requestFullMetadata: false,
    );
    if (picked == null) return null;

    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      aspectRatio: CropAspectRatio(ratioX: ratioX, ratioY: ratioY),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: title,
          lockAspectRatio: true,
          hideBottomControls: true,
        ),
        IOSUiSettings(title: title, aspectRatioLockEnabled: true),
      ],
    );

    // uCrop can report a target path without writing it (see the same guard in
    // the posts processor). Fall back to the picked original rather than
    // handing back a path that does not exist.
    final source = cropped != null && await File(cropped.path).exists()
        ? cropped.path
        : picked.path;

    final dir = await getTemporaryDirectory();
    final target =
        '${dir.path}/mday_tournament_${DateTime.now().microsecondsSinceEpoch}.jpg';

    try {
      final out = await FlutterImageCompress.compressAndGetFile(
        source,
        target,
        minWidth: maxWidth,
        minHeight: maxHeight,
        quality: _quality,
        format: CompressFormat.jpeg,
      );
      if (out != null && await File(out.path).exists()) return File(out.path);
    } catch (_) {
      // Compression is an optimisation, not a requirement — the bucket caps
      // are 10 MB / 5 MB and a cropped photo is comfortably under both.
    }
    return File(source);
  }
}
