import 'dart:io';

/// Pick + crop + compress a tournament's logo or banner.
///
/// The implementation (gallery pick → locked-ratio crop → JPEG resize) lives
/// in the data layer; the create wizard and settings screen depend only on
/// this abstraction.
abstract class TournamentArtworkPicker {
  /// 1080×420, ratio locked. Null if the user cancelled.
  Future<File?> pickBanner();

  /// Square, ratio locked. Null if the user cancelled.
  Future<File?> pickLogo();
}
