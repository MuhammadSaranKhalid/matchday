import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:go_router/go_router.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/ck_button.dart';
import '../../../../core/widgets/modals/modals.dart';
import '../../../posts/presentation/providers/posts_providers.dart';
import '../../../posts/presentation/screens/photo_viewer_screen.dart';
import '../../../posts/presentation/widgets/post_card.dart';
import '../../../posts/presentation/widgets/post_card_skeleton.dart';
import '../../domain/entities/roster_member.dart';
import '../../domain/entities/team.dart';
import '../../domain/entities/team_member.dart';
import '../../domain/value_objects/jersey_number.dart';
import '../../domain/value_objects/player_display_name.dart';
import '../providers/teams_providers.dart';
import '../utils/team_display.dart';
import '../widgets/team_avatar.dart';

/// Complete Manager console: Roster, Posts, Requests, Roles, and Settings.
class TeamManageScreen extends ConsumerStatefulWidget {
  const TeamManageScreen({super.key, required this.teamId, this.justCreated = false});

  final String teamId;
  final bool justCreated;

  @override
  ConsumerState<TeamManageScreen> createState() => _TeamManageScreenState();
}

class _TeamManageScreenState extends ConsumerState<TeamManageScreen> {
  int _activeTab = 0; // 0: Roster, 1: Posts, 2: Requests, 3: Settings

  @override
  Widget build(BuildContext context) {
    final teamAsync = ref.watch(teamProvider(widget.teamId));

    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        child: switch (teamAsync) {
          AsyncData(:final value?) => Column(
              children: [
                // Top Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.chevron_left_rounded, color: CkColors.ink),
                      ),
                      TeamAvatar(
                        name: value.name,
                        primaryColor: value.primaryColor,
                        logoUrl: value.logoUrl,
                        monogram: value.logoMonogram,
                        size: 36,
                        radius: 10,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(value.name,
                                style: CkType.display(fontSize: 17, letterSpacing: -0.01)),
                            GestureDetector(
                              onTap: () => context.go('/teams/${value.id.value}'),
                              child: Text('Public team page →',
                                  style: CkType.body(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: CkColors.red)),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          final uri = Uri(
                            path: '/composer',
                            queryParameters: {
                              'teamId': value.id.value,
                              'teamName': value.name,
                              if (value.logoMonogram != null && value.logoMonogram!.isNotEmpty)
                                'teamMono': value.logoMonogram!,
                            },
                          );
                          context.push(uri.toString());
                        },
                        icon: const Icon(Icons.add_rounded, size: 14),
                        label: const Text('Post'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CkColors.ink,
                          foregroundColor: CkColors.paper,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),

                // Tab Bar
                _TabHeader(
                  activeIndex: _activeTab,
                  onTabSelected: (i) => setState(() => _activeTab = i),
                ),

                if (widget.justCreated && _activeTab == 0) const _JustCreatedBanner(),

                // Tab Content
                Expanded(
                  child: switch (_activeTab) {
                    0 => _RosterTab(team: value),
                    1 => _TeamAnnouncementsManageTab(team: value),
                    2 => _RequestsTab(team: value),
                    _ => _SettingsTab(team: value),
                  },
                ),
              ],
            ),
          AsyncData() => const Center(child: Text('Team not found')),
          AsyncError() => const Center(child: Text('Could not load team')),
          _ => const Center(child: CircularProgressIndicator(color: CkColors.ink)),
        },
      ),
    );
  }
}

class _TabHeader extends StatelessWidget {
  const _TabHeader({required this.activeIndex, required this.onTabSelected});
  final int activeIndex;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CkColors.hairline)),
      ),
      child: Row(
        children: [
          _TabItem(label: 'Roster', active: activeIndex == 0, onTap: () => onTabSelected(0)),
          _TabItem(label: 'Posts', active: activeIndex == 1, onTap: () => onTabSelected(1)),
          _TabItem(label: 'Requests', active: activeIndex == 2, onTap: () => onTabSelected(2)),
          _TabItem(label: 'Settings', active: activeIndex == 3, onTap: () => onTabSelected(3)),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? CkColors.ink : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: CkType.body(
              fontSize: 13,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? CkColors.ink : CkColors.muted,
            ),
          ),
        ),
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
            style: CkType.body(fontSize: 13, color: const Color(0xFF1E5A2C))),
      );
}

// ─── Tab 1: Roster ──────────────────────────────────────────────────────────

class _RosterTab extends ConsumerWidget {
  const _RosterTab({required this.team});
  final Team team;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rosterAsync = ref.watch(rosterProvider(team.id.value));

    return switch (rosterAsync) {
      AsyncData(:final value) => Column(
          children: [
            Expanded(
              child: value.isEmpty
                  ? _EmptyRoster(onAdd: () => _addPlayer(context, ref, team))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: value.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: CkColors.hairline),
                      itemBuilder: (_, i) => _ManagedRow(
                        entry: value[i],
                        team: team,
                        onTap: () => _memberActions(context, ref, value[i]),
                      ),
                    ),
            ),
            if (value.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: CkButton(
                  label: 'Add player to squad',
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 18, color: CkColors.paper),
                  onPressed: () => _addPlayer(context, ref, team),
                ),
              ),
          ],
        ),
      AsyncError() => const Center(child: Text('Could not load roster')),
      _ => const Center(child: CircularProgressIndicator(color: CkColors.ink)),
    };
  }
}

// ─── Tab 2: Requests & Invitations ──────────────────────────────────────────

class _RequestsTab extends StatelessWidget {
  const _RequestsTab({required this.team});
  final Team team;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Invite share card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: CkColors.paper2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CkColors.hairline),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: CkColors.paper,
                  shape: BoxShape.circle,
                  border: Border.all(color: CkColors.hairline),
                ),
                child: const Icon(Icons.link_rounded, color: CkColors.ink),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Share Team Invite',
                        style: CkType.display(fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('Invite players via link or QR',
                        style: CkType.body(fontSize: 11, color: CkColors.muted)),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: 'https://matchday.app/teams/${team.id.value}/join'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invite link copied to clipboard!')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: CkColors.ink,
                  foregroundColor: CkColors.paper,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
                child: const Text('Copy Link'),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        Text(
          'PENDING PLAYER REQUESTS (0)',
          style: CkType.mono(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.06,
            color: CkColors.muted,
          ),
        ),
        const SizedBox(height: 10),

        Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: CkColors.paper2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CkColors.hairline),
          ),
          child: Column(
            children: [
              const Icon(Icons.inbox_outlined, size: 36, color: CkColors.muted),
              const SizedBox(height: 8),
              Text(
                'No pending join requests',
                style: CkType.display(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                'When local players ask to join your squad, their requests will appear here for approval.',
                textAlign: TextAlign.center,
                style: CkType.body(fontSize: 12, color: CkColors.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Tab 3: Settings ────────────────────────────────────────────────────────

class _SettingsTab extends StatelessWidget {
  const _SettingsTab({required this.team});
  final Team team;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _settingTile(
          title: 'Team Name',
          value: team.name,
          icon: Icons.shield_outlined,
          onTap: () {},
        ),
        _settingTile(
          title: 'Home Ground',
          value: team.homeGround ?? 'Not specified',
          icon: Icons.location_on_outlined,
          onTap: () {},
        ),
        _settingTile(
          title: 'Squad Capacity',
          value: '25 Players Max',
          icon: Icons.groups_outlined,
          onTap: () {},
        ),
        _settingTile(
          title: 'Team Privacy',
          value: team.privacy == TeamPrivacy.private ? 'Private Team' : 'Public Team',
          icon: Icons.lock_outline_rounded,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _settingTile({
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CkColors.paper2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: CkColors.ink),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: CkType.body(fontSize: 11, color: CkColors.muted)),
                const SizedBox(height: 1),
                Text(value, style: CkType.display(fontSize: 14, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, size: 18, color: CkColors.muted),
        ],
      ),
    );
  }
}

// ─── Actions & Sub-widgets ──────────────────────────────────────────────────

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
      child: Text(label, style: CkType.mono(fontSize: 9, color: const Color(0xFF6B5414))),
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

// ---------------------------------------------------------------------------
// Team Announcements & Posts Management Tab
// ---------------------------------------------------------------------------

class _TeamAnnouncementsManageTab extends ConsumerWidget {
  const _TeamAnnouncementsManageTab({required this.team});
  final Team team;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(teamPostsProvider(team.id.value));

    return RefreshIndicator(
      color: CkColors.ink,
      onRefresh: () async =>
          ref.refresh(teamPostsProvider(team.id.value).future),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
        children: [
          // Announcement Creation Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CkColors.paper2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CkColors.hairline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: CkColors.ink,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.campaign_outlined,
                        size: 18,
                        color: CkColors.paper,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Post Announcement',
                            style: CkType.display(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Share trials, match updates & squad selections',
                            style: CkType.body(
                              fontSize: 11.5,
                              color: CkColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final uri = Uri(
                        path: '/composer',
                        queryParameters: {
                          'teamId': team.id.value,
                          'teamName': team.name,
                          if (team.logoMonogram != null && team.logoMonogram!.isNotEmpty)
                            'teamMono': team.logoMonogram!,
                        },
                      );
                      context.push(uri.toString());
                    },
                    icon: const Icon(Icons.edit_note_rounded, size: 16),
                    label: Text('Post as ${team.name}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CkColors.ink,
                      foregroundColor: CkColors.paper,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'PUBLISHED POSTS',
            style: CkType.mono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.08,
              color: CkColors.muted,
            ),
          ),
          const SizedBox(height: 10),
          switch (postsAsync) {
            AsyncData(:final value) when value.isEmpty => Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Icon(
                    Icons.chat_bubble_outline,
                    size: 32,
                    color: CkColors.muted,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No posts published yet',
                    style: CkType.display(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Posts you publish as ${team.name} will appear here and on the team\'s public page.',
                    textAlign: TextAlign.center,
                    style: CkType.body(fontSize: 12, color: CkColors.muted),
                  ),
                ],
              ),
            ),
            AsyncData(:final value) => Column(
              children: [
                for (final post in value)
                  FeedPostCard(
                    post: post,
                    onComment: () => showCommentsSheet(
                      context,
                      postId: post.id.value,
                      postAuthorHandle: post.authorUsername != null &&
                              post.authorUsername!.isNotEmpty
                          ? '@${post.authorUsername}'
                          : post.authorName,
                      onOpenProfile: (String u) => context.push('/u/$u'),
                    ),
                    onLike: () => ref
                        .read(postsRepositoryProvider)
                        .togglePostLike(post.id),
                    onBookmark: () => ref
                        .read(postsRepositoryProvider)
                        .toggleBookmark(post.id),
                    onAuthorTap: (String u) => context.push('/u/$u'),
                    onOpenPhoto: (int idx) {
                      Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PhotoViewerScreen(
                            media: post.media,
                            initialIndex: idx,
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
            AsyncError() => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'Could not load posts.',
                  style: TextStyle(fontSize: 13, color: CkColors.muted),
                ),
              ),
            ),
            _ => const Padding(
              padding: EdgeInsets.all(16),
              child: PostCardSkeleton(),
            ),
          },
        ],
      ),
    );
  }
}
