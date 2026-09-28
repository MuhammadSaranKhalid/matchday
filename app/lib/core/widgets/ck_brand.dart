import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/circk_theme.dart';

/// The matchday **Seam** mark — the cricket-ball logo (red ball + cream seam
/// curve + stitches). Geometry lifted verbatim from `brand/matchday-mark.svg`
/// in the brand sheet. The colours are fixed brand colours (`#DC4D32` /
/// `#F4ECDD`) per the do/don't rule "don't recolor the ball".
class CkBrandMark extends StatelessWidget {
  const CkBrandMark({super.key, this.size = 40});

  final double size;

  static const _svg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <circle cx="50" cy="50" r="33" fill="#DC4D32"/>
  <path d="M50 18 C 60 34, 60 66, 50 82" fill="none" stroke="#F4ECDD" stroke-width="2.4"/>
  <line x1="43" y1="23" x2="49" y2="28" stroke="#F4ECDD" stroke-width="2" stroke-linecap="round"/>
  <line x1="51" y1="24" x2="57" y2="29" stroke="#F4ECDD" stroke-width="2" stroke-linecap="round"/>
  <line x1="43" y1="31" x2="49" y2="36" stroke="#F4ECDD" stroke-width="2" stroke-linecap="round"/>
  <line x1="51" y1="32" x2="57" y2="37" stroke="#F4ECDD" stroke-width="2" stroke-linecap="round"/>
  <line x1="43" y1="39" x2="49" y2="44" stroke="#F4ECDD" stroke-width="2" stroke-linecap="round"/>
  <line x1="51" y1="40" x2="57" y2="45" stroke="#F4ECDD" stroke-width="2" stroke-linecap="round"/>
  <line x1="43" y1="47" x2="49" y2="52" stroke="#F4ECDD" stroke-width="2" stroke-linecap="round"/>
  <line x1="51" y1="48" x2="57" y2="53" stroke="#F4ECDD" stroke-width="2" stroke-linecap="round"/>
  <line x1="43" y1="55" x2="49" y2="60" stroke="#F4ECDD" stroke-width="2" stroke-linecap="round"/>
  <line x1="51" y1="56" x2="57" y2="61" stroke="#F4ECDD" stroke-width="2" stroke-linecap="round"/>
  <line x1="43" y1="63" x2="49" y2="68" stroke="#F4ECDD" stroke-width="2" stroke-linecap="round"/>
  <line x1="51" y1="64" x2="57" y2="69" stroke="#F4ECDD" stroke-width="2" stroke-linecap="round"/>
  <line x1="43" y1="71" x2="49" y2="76" stroke="#F4ECDD" stroke-width="2" stroke-linecap="round"/>
  <line x1="51" y1="72" x2="57" y2="77" stroke="#F4ECDD" stroke-width="2" stroke-linecap="round"/>
</svg>''';

  @override
  Widget build(BuildContext context) =>
      SvgPicture.string(_svg, width: size, height: size);
}

/// The primary brand lockup from the brand sheet: the Seam [CkBrandMark] +
/// the **matchday.** wordmark (Inter Tight 800, −0.05em, red "dot ball").
///
/// Proportions follow the sheet's horizontal lockup (mark 64 · wordmark 54 ·
/// gap 20). Pass [wordmarkColor] for dark/red backgrounds (the mark keeps its
/// fixed colours).
class CkBrandLockup extends StatelessWidget {
  const CkBrandLockup({
    super.key,
    this.markSize = 48,
    this.wordmarkColor = CkColors.ink,
  });

  final double markSize;
  final Color wordmarkColor;

  @override
  Widget build(BuildContext context) {
    final fontSize = markSize * 0.84;
    TextStyle wm(Color c) => CkType.display(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.05,
          color: c,
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CkBrandMark(size: markSize),
        SizedBox(width: markSize * 0.3),
        Text.rich(
          TextSpan(children: [
            TextSpan(text: 'matchday', style: wm(wordmarkColor)),
            TextSpan(text: '.', style: wm(CkColors.red)),
          ]),
        ),
      ],
    );
  }
}
