// The scoring screen's header.
//
// Deliberately not a Material `AppBar`: this is a three-part composition
// (close · live pill + match type · overflow) that scrolls away with the
// content to give the run pad more room, and `AppBar` is a fixed-height
// PreferredSizeWidget that pins by default and brings a leading button and
// title centring we would only have to suppress.
//
// The trade that comes with hand-rolling it is that nothing reminds you to
// wire things up — this bar shipped with a decorative "More" chip that had no
// onTap at all. Hence [ScoringMenuAction]: the overflow either does something
// or is not rendered.
import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../domain/entities/match.dart';

/// What the overflow menu can do. Kept as an enum so the screen owns the
/// behaviour and this stays presentational.
enum ScoringMenuAction {
  /// Full scorecard for the match.
  viewScorecard,

  /// Swap the bowler mid-over (a mis-tap at the top of an over, usually).
  changeBowler,
}

class ScoringTopBar extends StatelessWidget {
  const ScoringTopBar({
    super.key,
    required this.matchType,
    required this.onClose,
    required this.onMenuAction,
    this.menuActions = const [],
  });

  final MatchType matchType;
  final VoidCallback onClose;
  final ValueChanged<ScoringMenuAction> onMenuAction;

  /// Empty hides the overflow entirely rather than showing a dead control.
  final List<ScoringMenuAction> menuActions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
            tooltip: 'Close scoring',
            icon: const Icon(Icons.close, size: 22, color: CkColors.ink),
          ),
          const Spacer(),
          const _LivePill(),
          const SizedBox(width: 8),
          Text(
            matchType.label,
            style: CkType.mono(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.06,
              color: CkColors.muted,
            ),
          ),
          const Spacer(),
          if (menuActions.isEmpty)
            // Keeps the live pill optically centred without a dead affordance.
            const SizedBox(width: 34)
          else
            _MoreMenu(actions: menuActions, onSelected: onMenuAction),
        ],
      ),
    );
  }
}

class _LivePill extends StatelessWidget {
  const _LivePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: CkColors.red,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'SCORING',
            style: CkType.mono(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.06,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreMenu extends StatelessWidget {
  const _MoreMenu({required this.actions, required this.onSelected});

  final List<ScoringMenuAction> actions;
  final ValueChanged<ScoringMenuAction> onSelected;

  static String _label(ScoringMenuAction a) => switch (a) {
        ScoringMenuAction.viewScorecard => 'View scorecard',
        ScoringMenuAction.changeBowler => 'Change bowler',
      };

  static IconData _icon(ScoringMenuAction a) => switch (a) {
        ScoringMenuAction.viewScorecard => Icons.list_alt_outlined,
        ScoringMenuAction.changeBowler => Icons.sports_cricket_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ScoringMenuAction>(
      onSelected: onSelected,
      tooltip: 'More',
      color: CkColors.paper,
      position: PopupMenuPosition.under,
      itemBuilder: (context) => [
        for (final a in actions)
          PopupMenuItem(
            value: a,
            child: Row(
              children: [
                Icon(_icon(a), size: 16, color: CkColors.ink2),
                const SizedBox(width: 10),
                Text(
                  _label(a),
                  style: CkType.body(fontSize: 13, color: CkColors.ink),
                ),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: CkColors.paper2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: CkColors.hairline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.more_horiz, size: 14, color: CkColors.ink2),
            const SizedBox(width: 6),
            Text(
              'More',
              style: CkType.body(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: CkColors.ink2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
