import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:go_router/go_router.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/ck_button.dart';
import '../../domain/entities/roster_member.dart';
import '../../domain/entities/team.dart';
import '../../domain/entities/team_member.dart';
import '../../domain/value_objects/jersey_number.dart';
import '../../domain/value_objects/player_display_name.dart';
import '../providers/teams_providers.dart';
import '../utils/team_display.dart';
import '../widgets/team_avatar.dart';

/// Manager view — Phase 1 Roster tab only (Requests/Members/Settings are v1.1).
class TeamManageScreen extends ConsumerWidget {
  const TeamManageScreen({super.key, required this.teamId, this.justCreated = false});

  final String teamId;
  final bool justCreated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(teamProvider(teamId));

    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        child: switch (teamAsync) {
          AsyncData(:final value?) => _Manage(team: value, justCreated: justCreated),
          AsyncData() => const Center(child: Text('Team not found')),
          AsyncError() => const Center(child: Text('Could not load team')),
          _ => const Center(child: CircularProgressIndicator(color: CkColors.ink)),
        },
      ),
    );
  }
}

class _Manage extends ConsumerWidget {
  const _Manage({required this.team, required this.justCreated});
  final Team team;
  final bool justCreated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roster = ref.watch(rosterProvider(team.id.value));

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
          child: Row(
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.chevron_left_rounded, color: CkColors.ink),
              ),
              TeamAvatar(
                name: team.name,
                primaryColor: team.primaryColor,
                logoUrl: team.logoUrl,
                monogram: team.logoMonogram,
                size: 36,
                radius: 10,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(team.name,
                        style: CkType.display(fontSize: 17, letterSpacing: -0.01)),
                    GestureDetector(
                      onTap: () => context.go('/teams/${team.id.value}'),
                      child: Text('Public view',
                          style: CkType.body(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: CkColors.red)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const _ManageTabs(),
        if (justCreated) const _JustCreatedBanner(),
        Expanded(
          child: switch (roster) {
            AsyncData(:final value) => _Roster(team: team, members: value),
            AsyncError() => const Center(child: Text('Could not load roster')),
            _ => const Center(
                child: CircularProgressIndicator(color: CkColors.ink)),
          },
        ),
      ],
    );
  }
}

class _ManageTabs extends StatelessWidget {
  const _ManageTabs();
  @override
  Widget build(BuildContext context) {
    Widget tab(String label, {required bool active}) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: active ? CkColors.ink : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: CkType.body(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: active ? CkColors.ink : CkColors.soft,
              ),
            ),
          ),
        );
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CkColors.hairline)),
      ),
      child: Row(
        children: [
          tab('Roster', active: true),
          tab('Requests', active: false),
          tab('Members', active: false),
          tab('Settings', active: false),
        ],
      ),
    );
  }
}

class _JustCreatedBanner extends StatelessWidget {
  const _JustCreatedBanner();
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CkColors.greenSoft,
          borderRadius: BorderRadius.circular(CkRadii.sm),
        ),
        child: Text('Team created. Add your first player below.',
            style: CkType.body(fontSize: 13, color: CkColors.ink2)),
      );
}

class _Roster extends ConsumerWidget {
  const _Roster({required this.team, required this.members});
  final Team team;
  final List<RosterMember> members;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Expanded(
          child: members.isEmpty
              ? _EmptyRoster(onAdd: () => _addPlayer(context, ref, team))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: members.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: CkColors.hairline),
                  itemBuilder: (_, i) => _ManagedRow(
                    entry: members[i],
                    team: team,
                    onTap: () => _memberActions(context, ref, members[i]),
                  ),
                ),
        ),
        if (members.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: CkButton(
              label: 'Add player',
              icon: const Icon(Icons.add_rounded, size: 20, color: CkColors.paper),
              onPressed: () => _addPlayer(context, ref, team),
            ),
          ),
      ],
    );
  }
}

// ─── Actions ────────────────────────────────────────────────────────────────

void _snack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}

void _showFailure(BuildContext context, Either<Failure, Object?> result) {
  result.fold((f) => _snack(context, f.message), (_) {});
}

Future<void> _addPlayer(BuildContext context, WidgetRef ref, Team team) async {
  final name = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: CkColors.paper,
    builder: (_) => const _AddPlayerSheet(),
  );
  if (name == null || !context.mounted) return;
  final nameRes = PlayerDisplayName.create(name);
  if (nameRes.isLeft()) {
    _snack(context, nameRes.getLeft().toNullable()!.message);
    return;
  }
  final result = await ref.read(teamsRepositoryProvider).addUnclaimedPlayer(
        teamId: team.id,
        displayName: nameRes.getRight().toNullable()!,
      );
  if (context.mounted) _showFailure(context, result);
}

Future<void> _memberActions(
    BuildContext context, WidgetRef ref, RosterMember entry) async {
  final action = await showModalBottomSheet<_MemberAction>(
    context: context,
    backgroundColor: CkColors.paper,
    builder: (_) => _MemberActionsSheet(entry: entry),
  );
  if (action == null || !context.mounted) return;
  final m = entry.member;

  switch (action) {
    case _MemberAction.jersey:
      // Record result so a barrier-dismiss (null) is distinct from an
      // explicit clear ((value: null)).
      final picked = await showModalBottomSheet<({int? value})>(
        context: context,
        isScrollControlled: true,
        backgroundColor: CkColors.paper,
        builder: (_) => _JerseySheet(initial: m.jerseyNumber),
      );
      if (picked == null || !context.mounted) return;
      JerseyNumber? jersey;
      if (picked.value != null) {
        final jerseyRes = JerseyNumber.create(picked.value!);
        if (jerseyRes.isLeft()) {
          _snack(context, jerseyRes.getLeft().toNullable()!.message);
          return;
        }
        jersey = jerseyRes.getRight().toNullable();
      }
      final result =
          await ref.read(teamsRepositoryProvider).setJerseyNumber(m.id, jersey);
      if (context.mounted) _showFailure(context, result);
    case _MemberAction.captain:
    case _MemberAction.viceCaptain:
    case _MemberAction.keeper:
    case _MemberAction.player:
      final result = await ref
          .read(teamsRepositoryProvider)
          .setMemberRole(m.id, action.role!);
      if (context.mounted) _showFailure(context, result);
    case _MemberAction.remove:
      final result =
          await ref.read(teamsRepositoryProvider).removeMember(m.id);
      if (context.mounted) _showFailure(context, result);
  }
}

enum _MemberAction {
  jersey,
  captain,
  viceCaptain,
  keeper,
  player,
  remove;

  MemberRole? get role => switch (this) {
        _MemberAction.captain => MemberRole.captain,
        _MemberAction.viceCaptain => MemberRole.viceCaptain,
        _MemberAction.keeper => MemberRole.wicketKeeper,
        _MemberAction.player => MemberRole.player,
        _ => null,
      };
}

// ─── Rows + sheets ───────────────────────────────────────────────────────────

class _ManagedRow extends StatelessWidget {
  const _ManagedRow(
      {required this.entry, required this.team, required this.onTap});
  final RosterMember entry;
  final Team team;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final m = entry.member;
    final primary = parseHexColor(team.primaryColor, fallback: CkColors.ink);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: m.jerseyNumber == null ? CkColors.paper2 : primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(m.jerseyNumber == null ? '—' : '#${m.jerseyNumber}',
                  style: CkType.display(
                      fontSize: 12,
                      color: m.jerseyNumber == null
                          ? CkColors.muted
                          : Colors.white)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(entry.displayName,
                        style:
                            CkType.display(fontSize: 15, letterSpacing: -0.01)),
                  ),
                  if (m.role != MemberRole.player) ...[
                    const SizedBox(width: 6),
                    _roleChip(m.role),
                  ],
                ],
              ),
            ),
            const Icon(Icons.more_horiz_rounded, color: CkColors.muted),
          ],
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
          color: CkColors.cream, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: CkType.mono(fontSize: 9, color: CkColors.ink2)),
    );
  }
}

class _EmptyRoster extends StatelessWidget {
  const _EmptyRoster({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_add_alt_1_outlined,
                size: 52, color: CkColors.soft),
            const SizedBox(height: 14),
            Text('Your roster is empty', style: CkType.display(fontSize: 20)),
            const SizedBox(height: 6),
            Text('Add your first player to build the squad.',
                textAlign: TextAlign.center,
                style: CkType.body(fontSize: 14, color: CkColors.muted)),
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

class _AddPlayerSheet extends StatefulWidget {
  const _AddPlayerSheet();
  @override
  State<_AddPlayerSheet> createState() => _AddPlayerSheetState();
}

class _AddPlayerSheetState extends State<_AddPlayerSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add player', style: CkType.display(fontSize: 20)),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            style: CkType.body(fontSize: 16),
            decoration: const InputDecoration(hintText: 'Player name'),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 14),
          CkButton(label: 'Add to squad', onPressed: _submit),
        ],
      ),
    );
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(name);
  }
}

class _MemberActionsSheet extends StatelessWidget {
  const _MemberActionsSheet({required this.entry});
  final RosterMember entry;

  @override
  Widget build(BuildContext context) {
    Widget item(IconData icon, String label, _MemberAction action,
            {Color color = CkColors.ink}) =>
        ListTile(
          leading: Icon(icon, color: color),
          title: Text(label,
              style: CkType.body(
                  fontSize: 15, fontWeight: FontWeight.w500, color: color)),
          onTap: () => Navigator.of(context).pop(action),
        );

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(entry.displayName,
                  style: CkType.display(fontSize: 18)),
            ),
          ),
          item(Icons.tag_rounded, 'Set jersey number', _MemberAction.jersey),
          item(Icons.star_rounded, 'Make captain', _MemberAction.captain),
          item(Icons.star_half_rounded, 'Make vice-captain',
              _MemberAction.viceCaptain),
          item(Icons.sports_baseball_outlined, 'Make wicket-keeper',
              _MemberAction.keeper),
          item(Icons.person_outline_rounded, 'Set as player',
              _MemberAction.player),
          item(Icons.delete_outline_rounded, 'Remove from roster',
              _MemberAction.remove,
              color: CkColors.red),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _JerseySheet extends StatefulWidget {
  const _JerseySheet({this.initial});
  final int? initial;
  @override
  State<_JerseySheet> createState() => _JerseySheetState();
}

class _JerseySheetState extends State<_JerseySheet> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial?.toString() ?? '');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Jersey number', style: CkType.display(fontSize: 20)),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            style: CkType.body(fontSize: 16),
            decoration: const InputDecoration(hintText: 'e.g. 7'),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: CkButton.secondary(
                  label: 'Clear',
                  onPressed: () =>
                      Navigator.of(context).pop((value: null)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: CkButton(label: 'Save', onPressed: _submit)),
            ],
          ),
        ],
      ),
    );
  }

  void _submit() {
    final n = int.tryParse(_controller.text.trim());
    Navigator.of(context).pop((value: n));
  }
}
