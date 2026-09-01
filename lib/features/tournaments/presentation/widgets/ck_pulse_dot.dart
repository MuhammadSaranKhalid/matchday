import 'package:flutter/material.dart';
import '../../../../core/theme/circk_theme.dart';

/// The live pulse — one of the three places the canvas allows Cricket Red.
///
/// Mirrors the `mdpulse` keyframe on the design canvas: opacity 1 → .25 → 1
/// on a 1.5s ease-in-out loop.
class CkPulseDot extends StatefulWidget {
  const CkPulseDot({super.key, this.size = 6, this.color = CkColors.red});

  final double size;
  final Color color;

  @override
  State<CkPulseDot> createState() => _CkPulseDotState();
}

class _CkPulseDotState extends State<CkPulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat(reverse: true);

  late final Animation<double> _opacity = Tween<double>(
    begin: 1.0,
    end: 0.25,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}
