import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../domain/entities/roster_member.dart';
import '../../../domain/entities/team_relationship.dart';
import '../../../domain/entities/team_member.dart';

enum MemberActionType {
  jersey,
  assignCaptain,
  revokeCaptain,
  promoteManager,
  demoteManager,
  remove,
}

/// Action sheet for promoting, demoting, setting jersey, or removing a player.
class MemberActionsSheet extends StatelessWidget {
  const MemberActionsSheet({
    super.key,
    required this.entry,
    required this.viewer,
  });
  final RosterMember entry;

  /// The signed-in user's rung. Required: authority is never guessed.
  final TeamRelationship viewer;

  static Future<MemberActionType?> show(
    BuildContext context,
    RosterMember entry, {
    required TeamRelationship viewer,
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
    final isOwner = m.hasRole(MemberRole.owner);
    final isManager = m.hasRole(MemberRole.manager);
    final isCaptain = m.hasRole(MemberRole.captain);
    final canActOnAuthority = viewer == TeamRelationship.owner ||
        (viewer == TeamRelationship.manager && !isOwner && !isManager);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
                        m.roles.map((r) => r.toUpperCase()).join(' · '),
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
          if (!isOwner || viewer == TeamRelationship.owner)
            item(Icons.tag_rounded, 'Set jersey number', MemberActionType.jersey),
          if (canActOnAuthority && !isCaptain)
            item(
              Icons.star_rounded,
              'Promote to Captain',
              MemberActionType.assignCaptain,
              color: const Color(0xFFB45309),
            ),
          if (viewer.canAppointStaff && !isOwner && !isManager)
            item(
              Icons.shield_outlined,
              'Make Manager',
              MemberActionType.promoteManager,
            ),
          if (canActOnAuthority && isCaptain)
            item(
              Icons.star_outline_rounded,
              'Remove Captaincy',
              MemberActionType.revokeCaptain,
            ),
          if (viewer == TeamRelationship.owner && isManager)
            item(
              Icons.person_outline_rounded,
              'Remove Manager role',
              MemberActionType.demoteManager,
            ),
          if (canActOnAuthority && !isOwner)
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
