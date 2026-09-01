import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/circk_theme.dart';
import '../../domain/entities/tournament.dart';
import '../../domain/entities/tournament_registration.dart';
import '../providers/tournaments_providers.dart';

/// Teams tab showing confirmed tournament entrants, group badges, and squad counts.
class TournamentTeamsTab extends ConsumerStatefulWidget {
  const TournamentTeamsTab({super.key, required this.tournament});

  final Tournament tournament;

  @override
  ConsumerState<TournamentTeamsTab> createState() => _TournamentTeamsTabState();
}

class _TournamentTeamsTabState extends ConsumerState<TournamentTeamsTab> {
  String? _selectedGroupId;

  @override
  Widget build(BuildContext context) {
    final regsAsync =
        ref.watch(tournamentRegistrationsProvider(widget.tournament.id));

    return regsAsync.when(
      data: (registrations) {
        final approved =
            registrations.where((r) => r.isApproved).toList();

        if (approved.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shield_outlined,
                      size: 40, color: CkColors.soft),
                  const SizedBox(height: 12),
                  Text('No Confirmed Teams Yet',
                      style: CkType.display(fontSize: 16)),
                  const SizedBox(height: 6),
                  Text(
                    'Teams will appear here once approved by the organizer.',
                    style: CkType.body(fontSize: 13, color: CkColors.muted),
                  ),
                ],
              ),
            ),
          );
        }

        // Collect distinct groups
        final groups = <String>{};
        for (final r in approved) {
          if (r.groupId != null && r.groupId!.trim().isNotEmpty) {
            groups.add(r.groupId!.trim());
          }
        }
        final sortedGroups = groups.toList()..sort();
        final hasMultipleGroups = sortedGroups.length > 1;

        final displayedTeams = _selectedGroupId == null
            ? approved
            : approved.where((r) => r.groupId == _selectedGroupId).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (hasMultipleGroups) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildGroupPill(
                      label: 'All Teams (${approved.length})',
                      isSelected: _selectedGroupId == null,
                      onTap: () => setState(() => _selectedGroupId = null),
                    ),
                    const SizedBox(width: 8),
                    ...sortedGroups.map((grp) {
                      final grpCount =
                          approved.where((r) => r.groupId == grp).length;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildGroupPill(
                          label: '$grp ($grpCount)',
                          isSelected: _selectedGroupId == grp,
                          onTap: () => setState(() => _selectedGroupId = grp),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            ...displayedTeams.map((reg) => _buildTeamCard(reg)),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
    );
  }

  Widget _buildGroupPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? CkColors.ink : CkColors.paper2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? CkColors.ink : CkColors.hairline,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : CkColors.ink,
          ),
        ),
      ),
    );
  }

  Widget _buildTeamCard(TournamentRegistration reg) {
    final teamName = reg.teamName ?? 'Team';
    final monogram = teamName.length >= 2
        ? teamName.substring(0, 2).toUpperCase()
        : teamName;

    Color parsedColor = CkColors.ink2;
    if (reg.teamPrimaryColor != null &&
        reg.teamPrimaryColor!.startsWith('#')) {
      final hex = reg.teamPrimaryColor!.replaceAll('#', '');
      if (hex.length == 6) {
        parsedColor = Color(int.parse('0xFF$hex'));
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.circular(CkRadii.md),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(CkRadii.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(CkRadii.md),
          onTap: () => context.push('/teams/${reg.teamId}'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: parsedColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      monogram,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              teamName,
                              style: CkType.display(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (reg.groupId != null && reg.groupId!.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: CkColors.paper2,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                reg.groupId!.toUpperCase(),
                                style: CkType.mono(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: CkColors.ink2,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (reg.captainName != null &&
                              reg.captainName!.isNotEmpty) ...[
                            Text(
                              'C: ${reg.captainName}',
                              style: CkType.body(
                                  fontSize: 12, color: CkColors.muted),
                            ),
                            const SizedBox(width: 8),
                            Text('·',
                                style: CkType.mono(
                                    fontSize: 11, color: CkColors.soft)),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            '${reg.squad.length} Players',
                            style: CkType.body(
                                fontSize: 12, color: CkColors.muted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (reg.seedNumber != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: CkColors.paper2,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'SEED #${reg.seedNumber}',
                      style: CkType.mono(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: CkColors.ink,
                      ),
                    ),
                  )
                else
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: CkColors.soft,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
