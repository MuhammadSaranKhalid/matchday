import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/util/surface_mode.dart';
import '../utils/team_display.dart';

/// How a logo sits inside the crest disc.
enum TeamCrestFit {
  /// Artwork fills the circle edge to edge, cropped to a square. The default.
  cover,

  /// Artwork floats whole inside a paper disc. Preserves a wide wordmark that
  /// [cover] would clip, at the cost of letterboxing a photo.
  contain,
}

/// The team crest — a circle, at every size, on every surface.
///
/// **Logos fill the circle.** Real uploads in this app are overwhelmingly
/// photographs — a ground, a team lineup — and `contain` letterboxes those
/// into a band floating in paper, which reads as a rendering fault rather
/// than a design. `cover` crops to a square instead, so the disc is always
/// full.
///
/// The cost is real and worth stating: a wide wordmark logo loses its first
/// and last letters under `cover`, and the owner never sees it happen. Pass
/// [TeamCrestFit.contain] for such a mark. Persisting that choice per team
/// (a `logo_fit` column plus a toggle in the logo picker) is a follow-up;
/// until then every crest fills.
///
/// **Inset tapers below 44.** Only the [TeamCrestFit.contain] path and the
/// monogram use it. Below 32px the shadow is dropped for a 1px hairline: a
/// 1px blur on a 22px disc is mud, and dense rows sit on paper where a
/// hairline is enough.
///
/// Note that a filled crest and a player avatar ([Avatar] in
/// `core/widgets/v2`) are now the same silhouette — a full-bleed photo
/// circle. In mixed lists (search, mentions) the mono TEAM / PLAYER label is
/// what separates a club from a person.
class TeamCrest extends StatelessWidget {
  const TeamCrest({
    super.key,
    required this.name,
    this.primaryColor,
    this.logoUrl,
    this.monogram,
    this.size = 44,
    this.fit = TeamCrestFit.cover,
    this.onLightSurface = false,
  });

  final String name;

  /// Team `primary_color` hex. Tints the monogram letters.
  final String? primaryColor;

  final String? logoUrl;

  /// 1–3 letter override (`teams.logo_monogram`). Derived from [name] when
  /// null or blank.
  final String? monogram;

  /// Diameter. The ramp is 72 (hero) · 44 (sheet) · 36 (post) · 28 (list) ·
  /// 22 (dense); values in between interpolate their inset and shadow.
  final double size;

  final TeamCrestFit fit;

  /// Set on a light ground (an ink-mode hero, cream paper). Adds the defining
  /// ring that a paper disc needs when it sits on something nearly as pale as
  /// it is.
  final bool onLightSurface;

  /// The measured ramp: 72→7 · 44→4 · 36→3 · 28→2 · 22→1.5.
  ///
  /// Roughly a tenth of the diameter, but deliberately tapering below 44 — a
  /// strictly proportional inset starts eating the artwork once the disc is
  /// small enough that the ring is already reading as a ring.
  double get _inset {
    if (size >= 72) return 7;
    if (size >= 44) return 4;
    if (size >= 36) return 3;
    if (size >= 28) return 2;
    return 1.5;
  }

  bool get _hasShadow => size >= 32;

  double get _monoSize => size * 0.38;

  List<BoxShadow> get _shadows {
    if (!_hasShadow) return const [];
    if (onLightSurface) {
      return [
        BoxShadow(
          color: CkColors.ink.withValues(alpha: 0.16),
          offset: const Offset(0, 3),
          blurRadius: 10,
        ),
      ];
    }
    // Scaled off the 72px hero spec (0 4 14 black@28).
    final k = size / 72;
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: size >= 56 ? 0.28 : 0.18),
        offset: Offset(0, 4 * k),
        blurRadius: 14 * k,
      ),
    ];
  }

  /// The disc edge. Small discs and discs on light grounds need a drawn edge;
  /// a large disc on a dark hero is defined by its own shadow.
  Border? get _border {
    if (onLightSurface) {
      return Border.all(color: CkColors.ink.withValues(alpha: 0.14));
    }
    if (!_hasShadow) {
      return Border.all(color: CkColors.ink.withValues(alpha: 0.12));
    }
    return Border.all(color: CkColors.ink.withValues(alpha: 0.10));
  }

  @override
  Widget build(BuildContext context) {
    final url = logoUrl?.trim();
    final hasLogo = url != null && url.isNotEmpty;
    final cover = fit == TeamCrestFit.cover && hasLogo;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: CkColors.paper,
        shape: BoxShape.circle,
        boxShadow: _shadows,
        border: _border,
      ),
      // `cover` fills the disc, so its artwork is clipped to the circle
      // itself; `contain` keeps the paper ring visible around the artwork.
      padding: cover ? EdgeInsets.zero : EdgeInsets.all(_inset),
      child: ClipOval(
        child: hasLogo ? _logo(context, url, cover: cover) : _monogram(),
      ),
    );
  }

  Widget _logo(BuildContext context, String url, {required bool cover}) {
    final memW =
        (size * MediaQuery.devicePixelRatioOf(context)).round().clamp(1, 4096);
    return CachedNetworkImage(
      imageUrl: url,
      fit: cover ? BoxFit.cover : BoxFit.contain,
      // No explicit width/height: the disc's own box (already inset by the
      // border) is the constraint, so `cover` fills exactly the ring's inside
      // rather than overflowing it by the border width.
      memCacheWidth: memW,
      errorWidget: (_, __, ___) => _monogram(),
      placeholder: (_, __) => _monogram(),
    );
  }

  Widget _monogram() {
    final primary = parseHexColor(primaryColor, fallback: CkColors.ink);
    // Letters in the team's own primary on a paper disc. The inverse — a
    // primary disc with paper letters — collapses to 1.05:1 on the cream and
    // amber swatches; this direction holds for all twelve.
    final letters = teamCrestMonogram(
      name,
      override: monogram,
      maxLetters: size <= 24 ? 1 : 3,
    );
    return Container(
      alignment: Alignment.center,
      color: CkColors.paper,
      child: Text(
        letters,
        maxLines: 1,
        style: CkType.display(
          fontSize: _monoSize / (letters.length > 2 ? 1.25 : 1),
          fontWeight: FontWeight.w700,
          letterSpacing: -0.03,
          color: darkenForPaper(primary),
        ),
      ),
    );
  }
}
