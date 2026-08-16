import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../../../core/widgets/ck_button.dart';
import '../../../../../core/widgets/v2/v2_kit.dart';
import '../../../domain/entities/roster_member.dart';
import '../../../domain/entities/team.dart';
import '../../../domain/entities/team_member.dart';
import '../../controllers/team_manage_controller.dart';
import '../../providers/teams_providers.dart';
import '../add_player_sheet.dart';
import 'jersey_sheet.dart';
import 'member_actions_sheet.dart';

/// Roster management tab showing current squad members and actions.
class RosterTab extends ConsumerWidget {
  const RosterTab({super.key, required this.team});
  final Team team;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rosterAsync = ref.watch(rosterProvider(team.id.value));

    return switch (rosterAsync) {
      AsyncData(:final value) => Column(
          children: [
            Expanded(
              child: value.isEmpty
                  ? EmptyRoster(onAdd: () => AddPlayerSheet.show(context, team))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: value.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: CkColors.hairline),
                      itemBuilder: (_, i) => ManagedRow(
                        entry: value[i],
                        team: team,
                        onManage: () => _handleMemberAction(context, ref, value[i]),
                      ),
                    ),
            ),
            if (value.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: CkButton(
                  label: 'Add player to squad',
                  icon: const Icon(
                    Icons.person_add_alt_1_rounded,
                    size: 18,
                    color: CkColors.paper,
                  ),
                  onPressed: () => AddPlayerSheet.show(context, team),
                ),
              ),
          ],
        ),
      AsyncError() => const Center(child: Text('Could not load roster')),
      _ => const Center(child: CircularProgressIndicator(color: CkColors.ink)),
    };
  }

  Future<void> _handleMemberAction(
    BuildContext context,
    WidgetRef ref,
    RosterMember entry,
  ) async {
    final action = await MemberActionsSheet.show(context, entry);
    if (action == null || !context.mounted) return;
    final m = entry.member;
    final ctrl = ref.read(teamManageControllerProvider.notifier);

    switch (action) {
      case MemberActionType.jersey:
        final picked = await JerseySheet.show(context, initial: m.jerseyNumber);
        if (picked == null || !context.mounted) return;
        final error = await ctrl.setJerseyNumber(
          memberId: m.id,
          teamId: m.teamId.value,
          jersey: picked.value,
        );
        if (error != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
        }

      case MemberActionType.captain:
      case MemberActionType.viceCaptain:
      case MemberActionType.keeper:
      case MemberActionType.player:
        final error = await ctrl.setMemberRole(
          memberId: m.id,
          teamId: m.teamId.value,
          role: action.role!,
        );
        if (error != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
        }

      case MemberActionType.remove:
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'Remove from squad?',
              style: CkType.display(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            content: Text(
              'Remove ${entry.displayName} from the active team roster? Historical match scorecards will remain intact.',
              style: CkType.body(fontSize: 13, color: CkColors.muted),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel', style: TextStyle(color: CkColors.ink)),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text(
                  'Remove',
                  style: TextStyle(color: CkColors.red, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        );
        if (confirm != true || !context.mounted) return;
        final error = await ctrl.removeMember(
          memberId: m.id,
          teamId: m.teamId.value,
        );
        if (error != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
        }
    }
  }
}

class ManagedRow extends StatelessWidget {
  const ManagedRow({
    super.key,
    required this.entry,
    required this.team,
    required this.onManage,
  });
  final RosterMember entry;
  final Team team;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final m = entry.member;
    final isUnclaimed = m.playerType == PlayerType.unclaimed;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                if (!isUnclaimed && entry.username != null && entry.username!.isNotEmpty) {
                  context.push('/u/${entry.username}');
                } else if (isUnclaimed) {
                  showOfflinePlayerSheet(context, team, entry, onManage);
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Avatar(
                      mono: entry.displayName.isNotEmpty ? entry.displayName[0].toUpperCase() : '?',
                      imageUrl: !isUnclaimed ? entry.profilePhotoUrl : null,
                      size: 38,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  entry.displayName,
                                  style: CkType.display(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.01,
                                  ),
                                ),
                              ),
                              if (m.role != MemberRole.player) ...[
                                const SizedBox(width: 6),
                                _roleChip(m.role),
                              ],
                              if (m.jerseyNumber != null) ...[
                                const SizedBox(width: 6),
                                _jerseyBadge(m.jerseyNumber!),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              if (isUnclaimed) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: CkColors.paper2,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Offline Player',
                                    style: CkType.mono(fontSize: 9, color: CkColors.muted),
                                  ),
                                ),
                              ] else ...[
                                Text(
                                  entry.username != null ? '@${entry.username}' : 'Verified Member',
                                  style: CkType.body(fontSize: 11, color: const Color(0xFF1E5A2C)),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: onManage,
            icon: const Icon(Icons.more_horiz_rounded, color: CkColors.ink),
            tooltip: 'Member actions',
          ),
        ],
      ),
    );
  }

  Widget _jerseyBadge(int number) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: CkColors.paper2,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Text(
        '#$number',
        style: CkType.mono(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: CkColors.ink,
        ),
      ),
    );
  }

  Widget _roleChip(MemberRole role) {
    final label = switch (role) {
      MemberRole.captain => 'C',
      MemberRole.viceCaptain => 'VC',
      MemberRole.wicketKeeper => 'WK',
      MemberRole.player => '',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: CkColors.cream,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: CkType.mono(fontSize: 9, fontWeight: FontWeight.w700, color: const Color(0xFF6B5414)),
      ),
    );
  }
}

void showOfflinePlayerSheet(
  BuildContext context,
  Team team,
  RosterMember entry,
  VoidCallback onManage,
) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: CkColors.paper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: CkColors.hairline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: CkColors.paper2,
                    shape: BoxShape.circle,
                    border: Border.all(color: CkColors.hairline),
                  ),
                  child: Text(
                    entry.displayName.isNotEmpty ? entry.displayName[0].toUpperCase() : '?',
                    style: CkType.display(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.displayName,
                        style: CkType.display(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Offline Squad Placeholder',
                        style: CkType.body(fontSize: 12, color: CkColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (entry.phoneNumber != null && entry.phoneNumber!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CkColors.paper2,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 16, color: CkColors.muted),
                    const SizedBox(width: 8),
                    Text(
                      entry.phoneNumber!,
                      style: CkType.mono(fontSize: 13, fontWeight: FontWeight.w600, color: CkColors.ink),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CkColors.paper2,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 18, color: CkColors.muted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This player does not have a linked Matchday account yet. You can share the claim link so they can register and claim their stats.',
                      style: CkType.body(fontSize: 11.5, color: CkColors.muted),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(
                        text: 'https://matchday.app/teams/${team.id.value}/claim',
                      ));
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Claim link copied to clipboard!')),
                      );
                    },
                    icon: const Icon(Icons.link_rounded, size: 16),
                    label: const Text('Claim Link'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CkColors.ink,
                      side: const BorderSide(color: CkColors.hairline),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      onManage();
                    },
                    icon: const Icon(Icons.tune_rounded, size: 16),
                    label: const Text('Manage Role'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CkColors.ink,
                      foregroundColor: CkColors.paper,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class EmptyRoster extends StatelessWidget {
  const EmptyRoster({super.key, required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.person_add_alt_1_outlined,
              size: 52,
              color: CkColors.soft,
            ),
            const SizedBox(height: 14),
            Text('Your roster is empty', style: CkType.display(fontSize: 20)),
            const SizedBox(height: 6),
            Text(
              'Add your first player to build the squad.',
              textAlign: TextAlign.center,
              style: CkType.body(fontSize: 14, color: CkColors.muted),
            ),
            const SizedBox(height: 18),
            CkButton(
              label: 'Add player',
              expand: false,
              icon: const Icon(Icons.add_rounded, size: 20, color: CkColors.paper),
              onPressed: onAdd,
            ),
          ],
        ),
      ),
    );
  }
}
