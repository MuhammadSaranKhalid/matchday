import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';

/// Small presentational pieces shared by the Match Start stages. Nothing here
/// knows about Riverpod, the controller, or the domain.

/// The two-phone "the other captain is doing this" placeholder.
class MatchStartWaitingCard extends StatelessWidget {
  const MatchStartWaitingCard({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.body,
  });

  final String eyebrow;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        color: CkColors.paper,
        border: Border.all(color: CkColors.hairline, width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: CkColors.paper2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const MatchStartPulseDot(),
          ),
          const SizedBox(height: 12),
          Text(
            eyebrow,
            style: CkType.mono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
              color: CkColors.amber,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: CkType.display(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.02,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: CkType.body(
              fontSize: 12,
              color: CkColors.muted,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

/// Breathing amber dot — the "waiting on the other phone" tell.
class MatchStartPulseDot extends StatefulWidget {
  const MatchStartPulseDot({super.key});

  @override
  State<MatchStartPulseDot> createState() => _MatchStartPulseDotState();
}

class _MatchStartPulseDotState extends State<MatchStartPulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller.drive(Tween(begin: 0.35, end: 1)),
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: CkColors.amber,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// A bordered, selectable option tile (team names, bat/bowl).
class MatchStartChoiceTile extends StatelessWidget {
  const MatchStartChoiceTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: CkColors.paper,
          border: Border.all(
            color: selected ? CkColors.ink : CkColors.hairline,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: CkType.display(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

/// Centred spinner used while a stage resolves.
class MatchStartLoader extends StatelessWidget {
  const MatchStartLoader({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator(color: CkColors.ink));
}
