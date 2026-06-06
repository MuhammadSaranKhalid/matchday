import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/circk_theme.dart';

/// The `matchday.` wordmark (Inter Tight, tight tracking, red period).
class CkWordmark extends StatelessWidget {
  const CkWordmark({super.key, this.fontSize = 22, this.color = CkColors.ink});

  final double fontSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'matchday',
            style: CkType.display(
              fontSize: fontSize,
              letterSpacing: -0.045,
              color: color,
            ),
          ),
          TextSpan(
            text: '.',
            style: CkType.display(
              fontSize: fontSize,
              letterSpacing: -0.045,
              color: CkColors.red,
            ),
          ),
        ],
      ),
    );
  }
}

/// The multicolour Google "G" — rendered from the exact SVG used in the design.
class GoogleG extends StatelessWidget {
  const GoogleG({super.key, this.size = 20});

  final double size;

  static const _svg = '''
<svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
  <path fill="#4285F4" d="M21.6 12.2c0-.7-.1-1.4-.2-2H12v3.8h5.4c-.2 1.3-.9 2.4-2 3.1v2.6h3.3c1.9-1.8 3-4.4 3-7.5z"/>
  <path fill="#34A853" d="M12 22c2.7 0 5-.9 6.7-2.4l-3.3-2.6c-.9.6-2 1-3.4 1-2.6 0-4.8-1.8-5.6-4.1H2.9v2.6C4.6 19.9 8 22 12 22z"/>
  <path fill="#FBBC05" d="M6.4 13.9c-.2-.6-.3-1.3-.3-1.9s.1-1.3.3-1.9V7.5H2.9C2.3 8.9 2 10.4 2 12s.3 3.1.9 4.5l3.5-2.6z"/>
  <path fill="#EA4335" d="M12 6c1.5 0 2.8.5 3.8 1.5l2.9-2.9C16.9 2.9 14.7 2 12 2 8 2 4.6 4.1 2.9 7.5l3.5 2.6C7.2 7.8 9.4 6 12 6z"/>
</svg>''';

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(_svg, width: size, height: size);
  }
}

/// Faint cricket-pitch field markings used as background atmosphere.
class PitchMotif extends StatelessWidget {
  const PitchMotif({super.key, this.size = 300, this.opacity = 0.04});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final ink = CkColors.ink.toARGB32().toRadixString(16).substring(2);
    final svg =
        '''
<svg width="200" height="200" viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
  <g stroke="#$ink" stroke-width="0.6" fill="none">
    <ellipse cx="100" cy="100" rx="95" ry="60"/>
    <ellipse cx="100" cy="100" rx="55" ry="34"/>
    <rect x="92" y="70" width="16" height="60"/>
    <line x1="100" y1="40" x2="100" y2="160"/>
  </g>
</svg>''';
    return Opacity(
      opacity: opacity,
      child: SvgPicture.string(svg, width: size, height: size),
    );
  }
}
