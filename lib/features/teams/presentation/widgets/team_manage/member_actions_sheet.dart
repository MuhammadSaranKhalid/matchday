import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../domain/entities/roster_member.dart';
import '../../../domain/entities/team_member.dart';

enum MemberActionType {
  jersey,
  captain,
  viceCaptain,
  keeper,
  player,
  remove;

  MemberRole? get role => switch (this) {
        MemberActionType.captain => MemberRole.captain,
        MemberActionType.viceCaptain => MemberRole.viceCaptain,
        MemberActionType.keeper => MemberRole.wicketKeeper,
        MemberActionType.player => MemberRole.player,
        _ => null,
      };
}

/// Action sheet for promoting, demoting, setting jersey, or removing a player.
class MemberActionsSheet extends StatelessWidget {
  const MemberActionsSheet({super.key, required this.entry});
  final RosterMember entry;

  static Future<MemberActionType?> show(
      BuildContext context, RosterMember entry) {
    return showModalBottomSheet<MemberActionType>(
      context: context,
      backgroundColor: CkColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => MemberActionsSheet(entry: entry),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget item(
      IconData icon,
      String label,
      MemberActionType action, {
      Color color = CkColors.ink,
    }) =>
        ListTile(
          leading: Icon(icon, color: color, size: 20),
          title: Text(
            label,
            style: CkType.body(
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          onTap: () => Navigator.of(context).pop(action),
        );

    final m = entry.member;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 8),
            decoration: BoxDecoration(
              color: CkColors.hairline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: CkColors.paper2,
                  child: Text(
                    entry.displayName.isNotEmpty
                        ? entry.displayName[0].toUpperCase()
                        : '?',
                    style: CkType.display(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.displayName,
                        style: CkType.display(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        m.role == MemberRole.captain
                            ? 'Captain'
                            : m.role == MemberRole.viceCaptain
                                ? 'Vice Captain'
                                : m.role == MemberRole.wicketKeeper
                                    ? 'Wicket-keeper'
                                    : 'Squad Player',
                        style: CkType.body(
                          fontSize: 12,
                          color: CkColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: CkColors.hairline),
          item(Icons.tag_rounded, 'Set jersey number', MemberActionType.jersey),
          if (m.role != MemberRole.captain)
            item(
              Icons.star_rounded,
              'Promote to Captain',
              MemberActionType.captain,
              color: const Color(0xFFB45309),
            ),
          if (m.role != MemberRole.viceCaptain)
            item(
              Icons.star_half_rounded,
              'Make Vice-Captain',
              MemberActionType.viceCaptain,
            ),
          if (m.role != MemberRole.wicketKeeper)
            item(
              Icons.sports_baseball_outlined,
              'Make Wicket-keeper',
              MemberActionType.keeper,
            ),
          if (m.role != MemberRole.player)
            item(
              Icons.person_outline_rounded,
              'Set as regular player',
              MemberActionType.player,
            ),
          item(
            Icons.delete_outline_rounded,
            'Remove from squad',
            MemberActionType.remove,
            color: CkColors.red,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
