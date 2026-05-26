import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import 'tp_view.dart';

/// Action row that adapts to viewer and team state. Lives inside the hero —
/// primary button = white fill / hero-color text; ghost = transparent with
/// translucent white border + white text. Archived teams override to a
/// single "Read-only archive" + share button row.
class TpActionRow extends StatelessWidget {
  const TpActionRow({
    super.key,
    required this.viewer,
    required this.team,
    required this.heroColor,
  });

  final TeamPageViewer viewer;
  final TpTeam team;
  final Color heroColor;

  List<_Action> _actionsFor() {
    if (team.archived != null) {
      return const [
        _Action(label: 'Read-only archive', icon: Icons.access_time),
        _Action(icon: Icons.ios_share, iconOnly: true),
      ];
    }
    switch (viewer) {
      case TeamPageViewer.owner:
        return [
          _Action(
            label: 'Manage',
            icon: Icons.dashboard_outlined,
            primary: true,
            badge: team.actionQueue.isEmpty ? null : team.actionQueue.length,
          ),
          const _Action(label: 'Post as team', icon: Icons.add),
        ];
      case TeamPageViewer.captain:
        return const [
          _Action(
            label: 'Captain inbox',
            icon: Icons.email_outlined,
            primary: true,
            badge: 3,
          ),
          _Action(label: 'Lineup', icon: Icons.format_list_bulleted),
        ];
      case TeamPageViewer.player:
        return const [
          _Action(
            label: 'Team chat',
            icon: Icons.chat_bubble_outline,
            primary: true,
          ),
          _Action(label: 'My stats', icon: Icons.bar_chart),
        ];
      case TeamPageViewer.following:
        return const [
          _Action(label: 'Following', icon: Icons.check, primary: true),
          _Action(label: 'Notify', icon: Icons.notifications_none),
        ];
      case TeamPageViewer.strangerPrivate:
        return const [
          _Action(label: 'Request to join', icon: Icons.add, primary: true),
        ];
      case TeamPageViewer.stranger:
        return const [
          _Action(label: 'Follow', icon: Icons.add, primary: true),
          _Action(label: 'Request to join'),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final actions = _actionsFor();
    return Row(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          _Button(
            action: actions[i],
            heroColor: heroColor,
          ),
        ],
      ],
    );
  }
}

class _Action {
  const _Action({
    this.label,
    this.icon,
    this.primary = false,
    this.iconOnly = false,
    this.badge,
  });
  final String? label;
  final IconData? icon;
  final bool primary;
  final bool iconOnly;
  final int? badge;
}

class _Button extends StatelessWidget {
  const _Button({required this.action, required this.heroColor});
  final _Action action;
  final Color heroColor;

  @override
  Widget build(BuildContext context) {
    final primary = action.primary;
    final body = Container(
      height: 44,
      padding: EdgeInsets.symmetric(
        horizontal: action.iconOnly ? 14 : (primary ? 0 : 14),
      ),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: primary ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        border: primary
            ? null
            : Border.all(color: Colors.white.withValues(alpha: 0.42)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (action.icon != null)
            Icon(
              action.icon,
              size: 14,
              color: primary ? heroColor : Colors.white,
            ),
          if (action.icon != null && action.label != null)
            const SizedBox(width: 6),
          if (action.label != null)
            Text(
              action.label!,
              style: CkType.body(
                fontSize: 13,
                fontWeight: primary ? FontWeight.w700 : FontWeight.w600,
                color: primary ? heroColor : Colors.white,
              ),
            ),
          if (action.badge != null && action.badge! > 0) ...[
            const SizedBox(width: 6),
            _CountPill(count: action.badge!),
          ],
        ],
      ),
    );
    if (primary || (!action.iconOnly && action.label != null)) {
      return Expanded(child: body);
    }
    return body;
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: CkColors.red,
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: CkType.display(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
