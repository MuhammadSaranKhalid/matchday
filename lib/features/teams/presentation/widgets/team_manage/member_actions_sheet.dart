import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../domain/entities/roster_member.dart';
import '../../../domain/entities/team_relationship.dart';
import '../../../domain/entities/team_member.dart';

enum MemberActionType {
  jersey,
  captain,
  manager,
  player,
  remove;

  MemberRole? get role => switch (this) {
        MemberActionType.manager => MemberRole.manager,
        MemberActionType.captain => MemberRole.captain,
        MemberActionType.player => MemberRole.player,
        _ => null,
      };
}

/// Action sheet for promoting, demoting, setting jersey, or removing a player.
class MemberActionsSheet extends StatelessWidget {
  const MemberActionsSheet({
    super.key,
    required this.entry,
    this.viewer = TeamRelationship.owner,
  });
  final RosterMember entry;

  /// The signed-in user's rung. Gates the staff actions so the sheet never
  /// offers something the server will refuse with a 42501.
  final TeamRelationship viewer;

  static Future<MemberActionType?> show(
    BuildContext context,
    RosterMember entry, {
    TeamRelationship viewer = TeamRelationship.owner,
  }) {
    return showModalBottomSheet<MemberActionType>(
      context: context,
      backgroundColor: CkColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => MemberActionsSheet(entry: entry, viewer: viewer),
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
                        switch (m.topRole) {
                          MemberRole.owner => 'Owner',
                          MemberRole.manager => 'Manager',
                          MemberRole.captain => 'Captain',
                          MemberRole.player => 'Squad Player',
                        },
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
          if (m.topRole != MemberRole.captain)
            item(
              Icons.star_rounded,
              'Promote to Captain',
              MemberActionType.captain,
              color: const Color(0xFFB45309),
            ),
          // Appointing staff is the owner's call alone; the server rejects a
          // manager who tries (set_team_member_role, "never grant a rung at or
          // above your own"), so only offer it when it can succeed.
          if (viewer.canAppointStaff && m.topRole != MemberRole.manager)
            item(
              Icons.shield_outlined,
              'Make Manager',
              MemberActionType.manager,
            ),
          if (m.topRole != MemberRole.player)
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
