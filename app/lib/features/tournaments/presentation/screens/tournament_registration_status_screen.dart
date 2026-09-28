import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../teams/presentation/providers/team_membership_providers.dart';
import '../../domain/entities/tournament.dart';
import '../../domain/entities/tournament_registration.dart';
import '../controllers/tournaments_controller.dart';
import '../providers/tournaments_providers.dart';

/// Artboard 33 — Register 4 · Status tracker + outcomes.
///
/// Route: `/tournaments/:tournamentId/register/status`
/// "The tracker is the screen a manager returns to, so it is a normal pushed
/// screen, not a success interstitial. Declined is neutral, never red — the
/// organiser's reason does the explaining, and the exit is a re-apply, not an
/// apology."
class TournamentRegistrationStatusScreen extends ConsumerStatefulWidget {
  const TournamentRegistrationStatusScreen({
    super.key,
    required this.tournamentId,
    this.registrationId,
  });

  final String tournamentId;
  final String? registrationId;

  @override
  ConsumerState<TournamentRegistrationStatusScreen> createState() =>
      _TournamentRegistrationStatusScreenState();
}

class _TournamentRegistrationStatusScreenState
    extends ConsumerState<TournamentRegistrationStatusScreen> {
  static final _money = NumberFormat.decimalPattern();

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays} days ago';
    if (diff.inHours > 0) return '${diff.inHours} hours ago';
    return '${diff.inMinutes} minutes ago';
  }

  Future<void> _withdraw(TournamentRegistration reg) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CkColors.paper,
        title: Text(
          'Withdraw registration?',
          style: CkType.display(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to withdraw ${reg.teamName ?? "your team"} from this tournament?',
          style: CkType.body(fontSize: 13, color: CkColors.ink2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: CkType.body(fontSize: 14, color: CkColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Withdraw', style: CkType.body(fontSize: 14, color: CkColors.redInk)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final ok = await ref
          .read(tournamentsControllerProvider.notifier)
          .withdrawRegistration(widget.tournamentId, reg.registrationId);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration withdrawn.')),
        );
        context.pop();
      }
    }
  }

  void _showSquadSheet(TournamentRegistration reg) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: CkColors.paper,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${reg.teamName ?? "Team"} · Submitted Squad (${reg.squad.length})',
              style: CkType.display(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ListView.separated(
                itemCount: reg.squad.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: CkColors.hairline),
                itemBuilder: (c, idx) {
                  final name = reg.squad[idx].replaceAll('guest_', '*');
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Text(
                          '${idx + 1}',
                          style: CkType.mono(
                            fontSize: 11,
                            color: CkColors.muted,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(name, style: CkType.body(fontSize: 13)),
                        const Spacer(),
                        if (idx == 0)
                          Text(
                            'CAPT',
                            style: CkType.mono(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: CkColors.muted,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tournamentAsync =
        ref.watch(tournamentDetailProvider(widget.tournamentId));
    final registrationsAsync =
        ref.watch(tournamentRegistrationsProvider(widget.tournamentId));
    final membershipsAsync = ref.watch(currentUserTeamMembershipsProvider);

    return Scaffold(
      backgroundColor: CkColors.paper,
      appBar: AppBar(
        backgroundColor: CkColors.paper,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: CkColors.ink),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Registration',
          style: CkType.display(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: CkColors.hairline),
        ),
      ),
      body: tournamentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (tournament) {
          return registrationsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (allRegs) {
              final myTeamIds = membershipsAsync.value
                      ?.where((m) => m.relationship.canRegisterForTournament)
                      .map((m) => m.team.id.value)
                      .toSet() ??
                  <String>{};
              
              // Find the relevant registration
              final reg = widget.registrationId != null
                  ? allRegs.where((r) => r.registrationId == widget.registrationId).firstOrNull
                  : allRegs.where((r) => myTeamIds.contains(r.teamId)).firstOrNull;

              if (reg == null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.info_outline, size: 36, color: CkColors.muted),
                        const SizedBox(height: 12),
                        Text(
                          'No active registration',
                          style: CkType.display(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'You haven’t registered a team for this tournament yet.',
                          textAlign: TextAlign.center,
                          style: CkType.body(fontSize: 13, color: CkColors.muted),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context.push('/tournaments/${tournament.id}/register'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: CkColors.ink,
                            foregroundColor: CkColors.paper,
                          ),
                          child: const Text('Register a Team'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Team header card (Artboard 33)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: CkColors.paper,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: CkColors.hairline),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F0E9),
                              shape: BoxShape.circle,
                              border: Border.all(color: CkColors.hairline),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              (reg.teamMonogram ?? reg.teamName?.substring(0, 2) ?? 'TM').toUpperCase(),
                              style: CkType.mono(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: CkColors.ink,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  reg.teamName ?? 'Team',
                                  style: CkType.display(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${reg.squad.length} players · submitted ${_timeAgo(reg.registeredAt)}',
                                  style: CkType.body(fontSize: 11.5, color: CkColors.muted),
                                ),
                              ],
                            ),
                          ),
                          _buildStatusChip(reg),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Outcomes variants
                    if (reg.isApproved) ...[
                      _buildApprovedOutcome(tournament, reg),
                      const SizedBox(height: 18),
                    ] else if (reg.status == TournamentRegistrationStatus.rejected) ...[
                      _buildDeclinedOutcome(tournament, reg),
                      const SizedBox(height: 18),
                    ],

                    // Progress timeline (Artboard 33)
                    Text(
                      'PROGRESS',
                      style: CkType.mono(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.12,
                        color: CkColors.muted,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        children: [
                          // Step 1: Submitted
                          _TimelineStep(
                            isDone: true,
                            isCurrent: false,
                            title: 'Submitted',
                            subtitle:
                                '${DateFormat("d MMM, h:mm a").format(reg.registeredAt)} · squad of ${reg.squad.length} sent to the organiser',
                            isLast: false,
                          ),

                          // Step 2: Under review
                          _TimelineStep(
                            isDone: reg.isApproved,
                            isCurrent: reg.isPending,
                            title: 'Under review',
                            subtitle:
                                'The organiser is checking squads and payments.',
                            badge: (tournament.entryFee ?? 0) > 0
                                ? Container(
                                    margin: const EdgeInsets.only(top: 6),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF4ECDD),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFFDED0AC)),
                                    ),
                                    child: Text(
                                      reg.isPaid
                                          ? 'FEE CONFIRMED · PKR ${_money.format(tournament.entryFee)}'
                                          : 'PENDING PAYMENT · PKR ${_money.format(tournament.entryFee)}',
                                      style: CkType.mono(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.08,
                                        color: const Color(0xFF6B5414),
                                      ),
                                    ),
                                  )
                                : null,
                            isLast: false,
                          ),

                          // Step 3: Approved
                          _TimelineStep(
                            isDone: reg.isApproved,
                            isCurrent: false,
                            title: 'Approved',
                            subtitle: reg.isApproved
                                ? 'Your team is in the tournament draw!'
                                : 'You will be notified and your seed appears in the draw.',
                            isLast: true,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Quick action buttons
                    Container(
                      decoration: BoxDecoration(
                        color: CkColors.paper,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: CkColors.hairline),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          ListTile(
                            title: Text(
                              'View submitted squad',
                              style: CkType.body(fontSize: 13.5, color: CkColors.ink),
                            ),
                            trailing: const Icon(Icons.chevron_right, size: 16, color: CkColors.muted),
                            onTap: () => _showSquadSheet(reg),
                          ),
                          const Divider(height: 1, color: CkColors.hairline),
                          ListTile(
                            title: Text(
                              'Message the organiser',
                              style: CkType.body(fontSize: 13.5, color: CkColors.ink),
                            ),
                            trailing: const Icon(Icons.chevron_right, size: 16, color: CkColors.muted),
                            onTap: () {},
                          ),
                          if (reg.isPending) ...[
                            const Divider(height: 1, color: CkColors.hairline),
                            ListTile(
                              title: Text(
                                'Withdraw application',
                                style: CkType.body(fontSize: 13.5, color: CkColors.redInk),
                              ),
                              onTap: () => _withdraw(reg),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(TournamentRegistration reg) {
    if (reg.isApproved) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFCFEED2),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFA9D9B2)),
        ),
        child: Text(
          'APPROVED',
          style: CkType.mono(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.10,
            color: const Color(0xFF1E5A2C),
          ),
        ),
      );
    }
    if (reg.status == TournamentRegistrationStatus.rejected) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F0E9),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFE6E2D9)),
        ),
        child: Text(
          'NOT ACCEPTED',
          style: CkType.mono(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.10,
            color: const Color(0xFF6E685E),
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF4ECDD),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFDED0AC)),
      ),
      child: Text(
        'PENDING',
        style: CkType.mono(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.12,
          color: const Color(0xFF6B5414),
        ),
      ),
    );
  }

  Widget _buildApprovedOutcome(Tournament t, TournamentRegistration reg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFA9D9B2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: Color(0xFFCFEED2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 18, color: Color(0xFF1E5A2C)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You’re in the draw',
                      style: CkType.display(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Approved by the organiser',
                      style: CkType.body(fontSize: 11.5, color: CkColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              if (reg.isPaid)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCFEED2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'FEE RECEIVED · CASH',
                    style: CkType.mono(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF276B34),
                    ),
                  ),
                ),
              if (reg.seedNumber != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F0E9),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: CkColors.hairline),
                  ),
                  child: Text(
                    'SEED ${reg.seedNumber} OF ${t.maxTeams ?? 8}',
                    style: CkType.mono(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: CkColors.ink2,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () => context.push('/tournaments/${t.id}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: CkColors.ink,
                foregroundColor: CkColors.paper,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('View the draw'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeclinedOutcome(Tournament t, TournamentRegistration reg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: Color(0xFFF3F0E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 18, color: CkColors.muted),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Not accepted this time',
                      style: CkType.display(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Declined · the draw filled up',
                      style: CkType.body(fontSize: 11.5, color: CkColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (reg.decisionReason != null && reg.decisionReason!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.only(left: 11),
              decoration: const BoxDecoration(
                border: Border(left: BorderSide(color: CkColors.line, width: 2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ORGANISER’S NOTE',
                    style: CkType.mono(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.08,
                      color: CkColors.muted,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '“${reg.decisionReason}”',
                    style: CkType.body(
                      fontSize: 12.5,
                      height: 1.5,
                      color: CkColors.ink2,
                    ).copyWith(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: CkColors.hairline),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Message organiser'),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => context.push('/tournaments'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CkColors.ink,
                      foregroundColor: CkColors.paper,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Find other cups'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.isDone,
    required this.isCurrent,
    required this.title,
    required this.subtitle,
    required this.isLast,
    this.badge,
  });

  final bool isDone;
  final bool isCurrent;
  final String title;
  final String subtitle;
  final bool isLast;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isDone
                    ? CkColors.ink
                    : isCurrent
                        ? const Color(0xFFF4ECDD)
                        : CkColors.paper,
                shape: BoxShape.circle,
                border: isDone
                    ? null
                    : Border.all(
                        color: isCurrent
                            ? const Color(0xFFE6AC3D)
                            : CkColors.hairline,
                        width: 2,
                      ),
              ),
              child: Center(
                child: isDone
                    ? const Icon(Icons.check, size: 12, color: CkColors.paper)
                    : isCurrent
                        ? Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE6AC3D),
                              shape: BoxShape.circle,
                            ),
                          )
                        : null,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 42,
                color: isDone ? CkColors.ink : CkColors.hairline,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: CkType.display(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: (isDone || isCurrent) ? CkColors.ink : CkColors.muted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: CkType.body(
                    fontSize: 12,
                    height: 1.45,
                    color: (isDone || isCurrent) ? CkColors.ink2 : CkColors.muted,
                  ),
                ),
                if (badge != null) badge!,
              ],
            ),
          ),
        ),
      ],
    );
  }
}
