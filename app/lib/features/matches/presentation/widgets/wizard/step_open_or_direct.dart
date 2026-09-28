import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../pool/pool_icons.dart';
import 'wizard_kit.dart';

/// The fork — `Pool.dc.html` artboard 06.
///
/// This choice drives the whole flow, so it gets a step of its own rather than
/// riding along with the opponent list: Open posts to the pool and you pick
/// from applicants; Direct challenges one team you already know. Open carries
/// the ink ring because it is the recommended path — you keep the choice of
/// who you end up playing.
class StepOpenOrDirect extends StatelessWidget {
  const StepOpenOrDirect({
    super.key,
    required this.isOpen,
    required this.onSelect,
    this.directContent,
  });

  /// Null = nothing chosen yet, which the design never shows: the step opens
  /// with Open selected.
  final bool isOpen;
  final ValueChanged<bool> onSelect;

  /// Shown under the Direct card once it is chosen. The design draws only the
  /// fork — its Open card is selected, so the picker is simply not on screen —
  /// but Direct has to name a team, and the flow is six steps either way.
  final Widget? directContent;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      children: [
        const WizardHeading(
          'How should teams find this match?',
          sub: 'You can post it openly, or challenge one team directly.',
        ),
        const SizedBox(height: 20),
        _ForkCard(
          icon: PoolIcons.broadcast,
          title: 'Open challenge',
          body:
              'Post to the Open Match Pool. Any team in range can apply — '
              'you review applicants and pick your opponent.',
          footnote: 'Recommended · you choose who plays',
          selected: isOpen,
          onTap: () => onSelect(true),
        ),
        const SizedBox(height: 14),
        _ForkCard(
          icon: PoolIcons.target,
          title: 'Direct challenge',
          body:
              'Send to one specific team you already know. They accept or '
              'decline — no pool, no applicants.',
          selected: !isOpen,
          onTap: () => onSelect(false),
        ),
        if (!isOpen && directContent != null) ...[
          const SizedBox(height: 16),
          directContent!,
        ],
      ],
    );
  }
}

class _ForkCard extends StatelessWidget {
  const _ForkCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.selected,
    required this.onTap,
    this.footnote,
  });

  final String icon;
  final String title;
  final String body;
  final bool selected;
  final VoidCallback onTap;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? CkColors.cream : CkColors.paper,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? CkColors.ink : CkColors.line,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? CkColors.paper : CkColors.paper2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? CkColors.creamBorder : CkColors.line,
                ),
              ),
              child: PoolIcon(icon, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: CkType.display(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: CkColors.ink,
                            letterSpacing: -0.01,
                          ),
                        ),
                      ),
                      if (selected)
                        const PoolIcon(PoolIcons.checkFilled, size: 22)
                      else
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: CkColors.soft,
                              width: 1.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    body,
                    style: CkType.body(
                      fontSize: 12.5,
                      height: 1.55,
                      color: selected ? CkColors.ink2 : CkColors.muted,
                    ),
                  ),
                  if (footnote != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      footnote!.toUpperCase(),
                      style: CkType.mono(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.06,
                        color: CkColors.amberInk,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
