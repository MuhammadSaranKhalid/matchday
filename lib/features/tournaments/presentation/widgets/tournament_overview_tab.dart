import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/ck_button.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/tournament.dart';
import '../providers/tournaments_providers.dart';
import 'tournament_fixture_row.dart';

/// The Overview tab in Tournament Detail adapting to the tournament's lifecycle.
class TournamentOverviewTab extends ConsumerWidget {
  const TournamentOverviewTab({
    super.key,
    required this.tournament,
    this.onRegisterTap,
    this.onManageTap,
  });

  final Tournament tournament;
  final VoidCallback? onRegisterTap;
  final VoidCallback? onManageTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId =
        ref.watch(currentUserStreamProvider).value?.id.value;
    final isOrganizer =
        currentUserId != null && tournament.isOrganizedBy(currentUserId);
    final fixturesAsync = ref.watch(tournamentFixturesProvider(tournament.id));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Organizer Console Quick Action
        if (isOrganizer) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: CkColors.paper2,
              borderRadius: BorderRadius.circular(CkRadii.md),
              border: Border.all(color: CkColors.creamBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.admin_panel_settings_outlined,
                    size: 24, color: Color(0xFF6B5414)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Organizer Controls',
                        style: CkType.display(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF6B5414),
                        ),
                      ),
                      Text(
                        'Manage registrations, seeding, and live matches.',
                        style: CkType.body(fontSize: 12, color: CkColors.ink2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                CkButton(
                  label: 'Console →',
                  onPressed: onManageTap ??
                      () => context.push('/tournaments/${tournament.id}/manage'),
                  variant: CkButtonVariant.secondary,
                  expand: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ─── Completed Champion Banner (Artboard 11) ───────────────────────
        if (tournament.status == TournamentStatus.completed) ...[
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: CkColors.paper2,
              borderRadius: BorderRadius.circular(CkRadii.md),
              border: Border.all(color: CkColors.line),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: CkColors.cream,
                    shape: BoxShape.circle,
                    border: Border.all(color: CkColors.creamBorder),
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    size: 26,
                    color: CkColors.amberDark,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOURNAMENT CONCLUDED',
                        style: CkType.mono(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: CkColors.greenInk,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Champions Crowned',
                        style: CkType.display(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: CkColors.ink,
                        ),
                      ),
                      Text(
                        'View the finale honors and tournament stats.',
                        style: CkType.body(fontSize: 12, color: CkColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ─── Registration Lifecycle State (Artboard 09) ────────────────────
        if (tournament.status == TournamentStatus.registration) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CkColors.surface,
              borderRadius: BorderRadius.circular(CkRadii.md),
              border: Border.all(color: CkColors.hairline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'REGISTRATION STATUS',
                      style: CkType.mono(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: CkColors.muted,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: CkColors.greenSoft,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: CkColors.greenBorder),
                      ),
                      child: Text(
                        tournament.maxTeams != null
                            ? '${tournament.approvedTeamsCount} / ${tournament.maxTeams} Teams'
                            : '${tournament.approvedTeamsCount} Teams',
                        style: CkType.mono(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: CkColors.greenInk,
                        ),
                      ),
                    ),
                  ],
                ),
                if (tournament.maxTeams != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (tournament.approvedTeamsCount) /
                          tournament.maxTeams!.clamp(1, 256),
                      backgroundColor: CkColors.paper2,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(CkColors.greenInk),
                      minHeight: 6,
                    ),
                  ),
                ],
                if (tournament.registrationDeadline != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: CkColors.cream,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: CkColors.creamBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: CkColors.amberDark,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Registration closes ${tournament.registrationDeadline!.day}/${tournament.registrationDeadline!.month}/${tournament.registrationDeadline!.year}',
                          style: CkType.mono(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: CkColors.amberDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                CkButton(
                  label: '🏏 Register Your Team',
                  onPressed: onRegisterTap ??
                      () => context.push('/tournaments/${tournament.id}/register'),
                  variant: CkButtonVariant.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ─── Live / Upcoming Fixtures Snapshot (Artboard 10) ────────────────
        Text(
          tournament.status == TournamentStatus.live
              ? 'FEATURED & RECENT FIXTURES'
              : 'SCHEDULE SNAPSHOT',
          style: CkType.mono(fontSize: 10.5, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        fixturesAsync.when(
          data: (fixtures) {
            if (fixtures.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: CkColors.paper2,
                  borderRadius: BorderRadius.circular(CkRadii.sm),
                ),
                child: Text(
                  'Fixtures will be published after registration closes and teams are seeded.',
                  style: CkType.body(fontSize: 12.5, color: CkColors.muted),
                  textAlign: TextAlign.center,
                ),
              );
            }
            return Column(
              children: fixtures.take(3).map((f) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TournamentFixtureRow(
                    match: f,
                    onTap: () => context.push('/matches/${f.id.value}'),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text(e.toString()),
        ),

        const SizedBox(height: 16),

        // ─── Tournament Info & Rules ─────────────────────────────────────────
        Text('TOURNAMENT RULES & INFO',
            style: CkType.mono(fontSize: 10.5, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CkColors.surface,
            borderRadius: BorderRadius.circular(CkRadii.md),
            border: Border.all(color: CkColors.hairline),
          ),
          child: Column(
            children: [
              _infoRow('Format', tournament.type.label),
              _infoRow('Overs', '${tournament.maxOvers} Overs per Innings'),
              _infoRow('Ball Type', tournament.ballType),
              _infoRow(
                'Entry Fee',
                tournament.entryFee != null
                    ? 'PKR ${tournament.entryFee!.toStringAsFixed(0)} (Pay offline)'
                    : 'Free Entry',
              ),
              if (tournament.prizeDetails != null)
                _infoRow('Prize Pool', tournament.prizeDetails!),
              _infoRow(
                'Grounds',
                tournament.venues.isNotEmpty &&
                        tournament.venues.first.name.trim().isNotEmpty
                    ? tournament.venues.map((v) => v.name).join(', ')
                    : 'TBA',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: CkType.body(fontSize: 12.5, color: CkColors.muted)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: CkType.display(fontSize: 12.5, fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
