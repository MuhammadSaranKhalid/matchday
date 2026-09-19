import 'package:flutter/material.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/v2/v2_kit.dart';
import '../../domain/entities/team_member.dart';

/// Renders the roles that matter on a team-membership row.
///
/// PLAYER is intentionally implicit inside the "Teams you play for" section.
/// CAPTAIN can coexist with OWNER or MANAGER, so both pills are shown when
/// both roles are present.
class TeamRolePills extends StatelessWidget {
  const TeamRolePills({
    super.key,
    required this.roles,
  });

  final Set<String> roles;

  @override
  Widget build(BuildContext context) {
    final visible = <MemberRole>[];

    if (roles.contains(MemberRole.owner.wire)) {
      visible.add(MemberRole.owner);
    } else if (roles.contains(MemberRole.manager.wire)) {
      visible.add(MemberRole.manager);
    }

    if (roles.contains(MemberRole.captain.wire)) {
      visible.add(MemberRole.captain);
    }

    if (visible.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 5,
      runSpacing: 4,
      alignment: WrapAlignment.end,
      children: [
        for (final role in visible) _TeamRolePill(role: role),
      ],
    );
  }
}

class _TeamRolePill extends StatelessWidget {
  const _TeamRolePill({required this.role});

  final MemberRole role;

  @override
  Widget build(BuildContext context) {
    final spec = switch (role) {
      MemberRole.owner => const _RoleSpec(
          label: 'OWNER',
          background: CkColors.ink,
          foreground: CkColors.paper,
        ),
      MemberRole.manager => const _RoleSpec(
          label: 'MANAGER',
          background: CkColors.paper2,
          foreground: CkColors.ink2,
          border: CkColors.hairline,
        ),
      MemberRole.captain => const _RoleSpec(
          label: 'CAPTAIN',
          background: CkColors.paper,
          foreground: CkColors.ink,
          border: CkColors.line,
        ),
      MemberRole.player => const _RoleSpec(
          label: 'PLAYER',
          background: CkColors.paper2,
          foreground: CkColors.muted,
          border: CkColors.hairline,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: spec.background,
        borderRadius: BorderRadius.circular(4),
        border:
            spec.border == null
                ? null
                : Border.all(
                    color: spec.border!,
                    width: 1,
                  ),
      ),
      child: Text(
        spec.label,
        style: CkType.mono(
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.08,
          color: spec.foreground,
        ),
      ),
    );
  }
}

class _RoleSpec {
  const _RoleSpec({
    required this.label,
    required this.background,
    required this.foreground,
    this.border,
  });

  final String label;
  final Color background;
  final Color foreground;
  final Color? border;
}
