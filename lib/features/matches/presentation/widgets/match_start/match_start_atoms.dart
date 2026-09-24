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
    this.statusNote = 'Connected via Match Day Live Relay • Syncs automatically',
  });

  final String eyebrow;
  final String title;
  final String body;
  final String statusNote;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: CkColors.surface,
        border: Border.all(color: const Color(0xFFE8E3DA), width: 1.5),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF8EFE1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8D9C0)),
            ),
            child: const MatchStartPulseDot(),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF8EFE1),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              eyebrow.toUpperCase(),
              style: CkType.mono(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: const Color(0xFF8A6132),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: CkType.display(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.02,
              color: const Color(0xFF24231F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: CkType.body(
              fontSize: 13,
              color: const Color(0xFF7C776F),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5EA),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: const Color(0xFFC7E6CB)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4E7D58),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    statusNote,
                    style: CkType.mono(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF4E7D58),
                    ),
                  ),
                ),
              ],
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
