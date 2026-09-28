import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/ck_text_field.dart';
import '../../domain/entities/tournament_registration.dart';
import '../controllers/tournaments_controller.dart';
import '../providers/tournaments_providers.dart';

enum _RequestFilter { pending, rejected, withdrawn }

/// Artboard 24f — Requests as a pushed page.
///
/// Pushed from the Teams badged inbox icon (`/manage/requests`).
/// "A sheet is for one decision you return from; this is a list you work down,
/// so it gets its own page. There is no cap on teams, so the header counts
/// rather than rations: how many have applied, how many you have approved,
/// and how long the oldest request has waited. Approvals stay here: the row
/// leaves, a toast offers Undo, and you keep going until the queue is empty."
class TournamentRequestsScreen extends ConsumerStatefulWidget {
  const TournamentRequestsScreen({super.key, required this.tournamentId});

  final String tournamentId;

  @override
  ConsumerState<TournamentRequestsScreen> createState() =>
      _TournamentRequestsScreenState();
}

class _TournamentRequestsScreenState
    extends ConsumerState<TournamentRequestsScreen> {
  _RequestFilter _filter = _RequestFilter.pending;

  /// The queue opens at four (24f). A busy cup can carry a dozen applications
  /// and the summary above already says how many are waiting, so the list
  /// offers the rest rather than making you scroll past them.
  static const _collapsedPending = 4;
  bool _showAllPending = false;

  /// Approvals waiting out their 5-second undo window.
  final Map<String, Timer> _pendingApprovals = {};
  final Set<String> _optimisticallyApproved = {};
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _undoBanner;

  /// Set of registration IDs whose squad expander is currently open.
  final Set<String> _expandedSquads = {};

  @override
  void dispose() {
    // Flush any pending approvals on unmount
    for (final entry in _pendingApprovals.entries) {
      entry.value.cancel();
      ref
          .read(tournamentsControllerProvider.notifier)
          .approveRegistration(widget.tournamentId, entry.key);
    }
    _pendingApprovals.clear();
    super.dispose();
  }

  void _approve(TournamentRegistration reg) {
    setState(() => _optimisticallyApproved.add(reg.registrationId));

    _pendingApprovals[reg.registrationId] = Timer(
      const Duration(seconds: 5),
      () async {
        _pendingApprovals.remove(reg.registrationId);
        _undoBanner?.close();
        _undoBanner = null;
        if (!mounted) return;
        await ref
            .read(tournamentsControllerProvider.notifier)
            .approveRegistration(widget.tournamentId, reg.registrationId);
        if (mounted) {
          setState(() => _optimisticallyApproved.remove(reg.registrationId));
        }
      },
    );

    final messenger = ScaffoldMessenger.of(context)..clearSnackBars();
    _undoBanner = messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5),
        backgroundColor: CkColors.ink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: Color(0xFFCFEED2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, size: 12, color: Color(0xFF1E5A2C)),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                '${reg.teamName ?? 'Team'} approved',
                style: CkType.body(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: CkColors.paper,
                ),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'Undo',
          textColor: CkColors.paper,
          onPressed: () {
            _pendingApprovals.remove(reg.registrationId)?.cancel();
            if (mounted) {
              setState(
                () => _optimisticallyApproved.remove(reg.registrationId),
              );
            }
          },
        ),
      ),
    );
  }

  Future<void> _showRejectSheet(TournamentRegistration reg) async {
    final reasonController = TextEditingController();
    String? selectedPreset;

    final presets = [
      'Squad incomplete',
      'Outside catchment area',
      'Write a note…',
    ];

    final result = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: CkColors.ink.withValues(alpha: 0.32),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            decoration: const BoxDecoration(
              color: CkColors.paper,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.fromLTRB(
              20,
              10,
              20,
              MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: CkColors.hairline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Reject ${reg.teamName ?? 'this team'}?',
                  style: CkType.display(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.02,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'A reason is optional — it is sent to the manager either way.',
                  style: CkType.body(fontSize: 12.5, color: CkColors.muted),
                ),
                const SizedBox(height: 14),
                Text(
                  'REASON',
                  style: CkType.mono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.12,
                    color: CkColors.muted,
                  ),
                ),
                const SizedBox(height: 8),
                for (final preset in presets) ...[
                  InkWell(
                    onTap: () {
                      setSheetState(() {
                        selectedPreset = preset;
                        if (preset != 'Write a note…') {
                          reasonController.text = preset;
                        } else {
                          reasonController.clear();
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(11),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 7),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: selectedPreset == preset
                            ? CkColors.paper
                            : CkColors.paper,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                          color: selectedPreset == preset
                              ? CkColors.ink
                              : CkColors.hairline,
                          width: selectedPreset == preset ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        preset,
                        style: CkType.body(
                          fontSize: 13,
                          fontWeight: selectedPreset == preset
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: selectedPreset == preset
                              ? CkColors.ink
                              : CkColors.ink2,
                        ),
                      ),
                    ),
                  ),
                ],
                if (selectedPreset == 'Write a note…') ...[
                  const SizedBox(height: 4),
                  CkTextField(
                    label: 'Note',
                    controller: reasonController,
                    hint: 'Write a note to the manager…',
                    maxLines: 2,
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  'Rejected teams stay on the Rejected tab, so you can see who '
                  'you turned away — and reinstate them at any time.',
                  style: CkType.body(
                    fontSize: 11.5,
                    height: 1.5,
                    color: CkColors.muted,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: CkColors.hairline),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: CkType.body(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: CkColors.ink,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            final finalReason = reasonController.text.trim();
                            Navigator.pop(
                              ctx,
                              finalReason.isEmpty
                                  ? 'Registration declined by organiser'
                                  : finalReason,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: CkColors.ink,
                            foregroundColor: CkColors.paper,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Reject & Notify',
                            style: CkType.body(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: CkColors.paper,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(
                      ctx,
                      'Registration declined by organiser',
                    ),
                    child: Text(
                      'Skip the reason',
                      style: CkType.body(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: CkColors.muted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    reasonController.dispose();

    if (result != null && mounted) {
      await ref.read(tournamentsControllerProvider.notifier).rejectRegistration(
            widget.tournamentId,
            reg.registrationId,
            result,
          );
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays} days ago';
    if (diff.inHours > 0) return '${diff.inHours} hours ago';
    return '${diff.inMinutes} minutes ago';
  }

  @override
  Widget build(BuildContext context) {
    final tournamentAsync =
        ref.watch(tournamentDetailProvider(widget.tournamentId));
    final registrationsAsync =
        ref.watch(tournamentRegistrationsProvider(widget.tournamentId));

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
        titleSpacing: 0,
        title: tournamentAsync.when(
          data: (tournament) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Requests', style: CkType.display(fontSize: 17)),
              Text(
                tournament.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CkType.body(fontSize: 11, color: CkColors.muted),
              ),
            ],
          ),
          loading: () => const Text('Requests'),
          error: (_, __) => const Text('Requests'),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: CkColors.hairline),
        ),
      ),
      body: registrationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (all) {
          final pendingAll = all
              .where((r) =>
                  r.isPending &&
                  !_optimisticallyApproved.contains(r.registrationId))
              .toList();
          final approved = all.where((r) => r.isApproved).toList();
          final rejected = all
              .where((r) => r.status == TournamentRegistrationStatus.rejected)
              .toList();
          final withdrawn = all
              .where((r) => r.status == TournamentRegistrationStatus.withdrawn)
              .toList();

          // Oldest pending application
          final oldestPending = pendingAll.isEmpty
              ? null
              : pendingAll.reduce(
                  (a, b) => a.registeredAt.isBefore(b.registeredAt) ? a : b,
                );
          final oldestDays = oldestPending == null
              ? 0
              : DateTime.now().difference(oldestPending.registeredAt).inDays;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top summary banner (Artboard 24f)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4ECDD),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDED0AC)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${pendingAll.length} REQUESTS AWAITING YOU',
                              style: CkType.mono(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.10,
                                color: const Color(0xFF8C5311),
                              ),
                            ),
                          ),
                          Text(
                            '${approved.length} approved',
                            style: CkType.mono(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF8C5311),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${oldestDays > 0 ? "Oldest has waited $oldestDays days. " : ""}'
                        'Fixtures can be generated for any number of approved '
                        'teams — byes are added automatically for odd counts.',
                        style: CkType.body(
                          fontSize: 11,
                          height: 1.45,
                          color: const Color(0xFF8C5311),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Filter pills (Artboard 24f)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: Row(
                  children: [
                    _FilterPill(
                      label: 'Pending ${pendingAll.length}',
                      active: _filter == _RequestFilter.pending,
                      onTap: () =>
                          setState(() => _filter = _RequestFilter.pending),
                    ),
                    const SizedBox(width: 6),
                    _FilterPill(
                      label: 'Rejected ${rejected.length}',
                      active: _filter == _RequestFilter.rejected,
                      onTap: () =>
                          setState(() => _filter = _RequestFilter.rejected),
                    ),
                    const SizedBox(width: 6),
                    _FilterPill(
                      label: 'Withdrawn ${withdrawn.length}',
                      active: _filter == _RequestFilter.withdrawn,
                      onTap: () =>
                          setState(() => _filter = _RequestFilter.withdrawn),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: CkColors.hairline),

              // List body
              Expanded(
                child: switch (_filter) {
                  _RequestFilter.pending => _buildPendingList(pendingAll),
                  _RequestFilter.rejected => _buildRejectedList(rejected),
                  _RequestFilter.withdrawn => _buildWithdrawnList(withdrawn),
                },
              ),
            ],
          );
        },
      ),
    );
  }

  /// "2 more pending · oldest applied 6 days ago" over a Show all (24f). The
  /// age belongs here rather than on the hidden rows: it is the reason to
  /// open them.
  /// How many squad names the expander shows before it summarises.
  static const _squadPreview = 3;

  /// "+ 11 more · 2 unregistered on Matchday" (24f). A guest is a roster spot
  /// with no account behind it — the team sheet writes those as `guest_<name>`
  /// (see `team_registration_sheet.dart`), and the organiser wants the count
  /// because those players cannot be messaged or verified.
  String? _squadTail(TournamentRegistration reg) {
    final more = reg.squad.length - _squadPreview;
    final guests = reg.squad.where((p) => p.startsWith('guest_')).length;
    if (more <= 0 && guests == 0) return null;

    final parts = <String>[
      if (more > 0) '+ $more more',
      if (guests > 0) '$guests unregistered on Matchday',
    ];
    return parts.join(' · ');
  }

  Widget _morePendingFooter(List<TournamentRegistration> list, int hidden) {
    final now = DateTime.now();
    final oldest = list
        .map((r) => now.difference(r.registeredAt).inDays)
        .fold<int>(0, (a, b) => b > a ? b : a);

    return InkWell(
      onTap: () => setState(() => _showAllPending = true),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '$hidden more pending'
                '${oldest > 0 ? ' · oldest applied $oldest days ago' : ''}',
                style: CkType.body(fontSize: 12, color: CkColors.muted),
              ),
            ),
            Text(
              'Show all',
              style: CkType.body(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: CkColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingList(List<TournamentRegistration> list) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inbox, size: 36, color: CkColors.line),
              const SizedBox(height: 12),
              Text(
                'No pending requests',
                style: CkType.display(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'All applications have been reviewed.',
                style: CkType.body(fontSize: 12.5, color: CkColors.muted),
              ),
            ],
          ),
        ),
      );
    }

    final shown = _showAllPending
        ? list
        : list.take(_collapsedPending).toList(growable: false);
    final hidden = list.length - shown.length;

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: shown.length + (hidden > 0 ? 1 : 0),
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: CkColors.hairline),
      itemBuilder: (context, index) {
        if (index == shown.length) return _morePendingFooter(list, hidden);
        final reg = shown[index];
        final isExpanded = _expandedSquads.contains(reg.registrationId);
        final hasFee = reg.isPaid;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top row: Avatar + Team Name & Manager info + Fee chip
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MonogramAvatar(
                    monogram: reg.teamMonogram ?? _generateMonogram(reg.teamName),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                reg.teamName ?? 'Team',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: CkType.display(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.chevron_right,
                              size: 14,
                              color: CkColors.muted,
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            if (reg.captainName != null) reg.captainName!,
                            if (reg.registeredByName != null &&
                                reg.registeredByName != reg.captainName)
                              reg.registeredByName!,
                            _timeAgo(reg.registeredAt),
                          ].join(' · '),
                          style: CkType.mono(
                            fontSize: 9.5,
                            color: CkColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: hasFee
                          ? const Color(0xFFCFEED2)
                          : const Color(0xFFF3F0E9),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: hasFee
                            ? const Color(0xFFA9D9B2)
                            : const Color(0xFFE6E2D9),
                      ),
                    ),
                    child: Text(
                      hasFee ? 'FEE READY' : 'NO FEE YET',
                      style: CkType.mono(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.06,
                        color: hasFee
                            ? const Color(0xFF1E5A2C)
                            : const Color(0xFF6E685E),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Action row: Squad expander pill + Approve & Reject buttons
              Row(
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        if (isExpanded) {
                          _expandedSquads.remove(reg.registrationId);
                        } else {
                          _expandedSquads.add(reg.registrationId);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: CkColors.paper,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: CkColors.hairline),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${reg.squad.length} players',
                            style: CkType.mono(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: CkColors.ink,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            size: 14,
                            color: CkColors.ink,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      onPressed: () => _approve(reg),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CkColors.ink,
                        foregroundColor: CkColors.paper,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Approve',
                        style: CkType.body(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: CkColors.paper,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 36,
                    child: OutlinedButton(
                      onPressed: () => _showRejectSheet(reg),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: CkColors.hairline),
                        backgroundColor: CkColors.paper,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Reject',
                        style: CkType.body(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: CkColors.ink,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Expanded Squad View (Artboard 24f)
              if (isExpanded) ...[
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: CkColors.paper,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: CkColors.hairline),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        color: const Color(0xFFF3F0E9),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'SQUAD · ${reg.squad.length} NAMED',
                                style: CkType.mono(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.10,
                                  color: const Color(0xFF6E685E),
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () => context.push('/teams/${reg.teamId}'),
                              child: Text(
                                'OPEN TEAM',
                                style: CkType.mono(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.06,
                                  color: CkColors.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Three names, then a count (24f). The panel is a
                            // glance at who is applying, not a team sheet.
                            for (var i = 0;
                                i < reg.squad.length && i < _squadPreview;
                                i++) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 3),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        reg.squad[i].replaceAll('guest_', '*'),
                                        style: CkType.body(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    if (i == 0)
                                      Text(
                                        'C · WK',
                                        style: CkType.mono(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color: CkColors.muted,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                            if (_squadTail(reg) != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                _squadTail(reg)!,
                                style: CkType.body(
                                  fontSize: 11,
                                  color: CkColors.muted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildRejectedList(List<TournamentRegistration> list) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.block, size: 36, color: CkColors.line),
              const SizedBox(height: 12),
              Text(
                'No rejected applications',
                style: CkType.display(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final reg = list[index];

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: CkColors.paper,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: CkColors.hairline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _MonogramAvatar(
                    monogram:
                        reg.teamMonogram ?? _generateMonogram(reg.teamName),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reg.teamName ?? 'Team',
                          style: CkType.display(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Declined ${_timeAgo(reg.decidedAt ?? reg.updatedAt)}',
                          style: CkType.body(fontSize: 11, color: CkColors.muted),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 32,
                    child: OutlinedButton(
                      onPressed: () => _approve(reg),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: CkColors.hairline),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      child: Text(
                        'Reinstate',
                        style: CkType.mono(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: CkColors.ink,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (reg.decisionReason != null &&
                  reg.decisionReason!.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.only(left: 10),
                  decoration: const BoxDecoration(
                    border: Border(
                      left: BorderSide(color: CkColors.line, width: 2),
                    ),
                  ),
                  child: Text(
                    '“${reg.decisionReason}”',
                    style: CkType.body(
                      fontSize: 11.5,
                      height: 1.4,
                      color: CkColors.ink2,
                    ).copyWith(fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildWithdrawnList(List<TournamentRegistration> list) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.remove_circle_outline,
                  size: 36, color: CkColors.line),
              const SizedBox(height: 12),
              Text(
                'No withdrawn applications',
                style: CkType.display(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final reg = list[index];

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: CkColors.paper,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: CkColors.hairline),
          ),
          child: Row(
            children: [
              _MonogramAvatar(
                monogram: reg.teamMonogram ?? _generateMonogram(reg.teamName),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reg.teamName ?? 'Team',
                      style: CkType.display(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Withdrawn ${_timeAgo(reg.updatedAt)}',
                      style: CkType.body(fontSize: 11, color: CkColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _generateMonogram(String? name) {
    if (name == null || name.trim().isEmpty) return 'TM';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.trim().padRight(2).substring(0, 2).toUpperCase();
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? CkColors.ink : CkColors.paper,
          borderRadius: BorderRadius.circular(999),
          border: active ? null : Border.all(color: CkColors.hairline),
        ),
        child: Text(
          label,
          style: CkType.body(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? CkColors.paper : CkColors.ink2,
          ),
        ),
      ),
    );
  }
}

class _MonogramAvatar extends StatelessWidget {
  const _MonogramAvatar({required this.monogram});

  final String monogram;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F0E9),
        shape: BoxShape.circle,
        border: Border.all(color: CkColors.hairline),
      ),
      alignment: Alignment.center,
      child: Text(
        monogram,
        style: CkType.mono(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: CkColors.ink,
        ),
      ),
    );
  }
}
