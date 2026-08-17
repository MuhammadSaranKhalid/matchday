// "My matches" — promoted out of the Pavilion god-screen into its own route at
// `/pavilion/my-matches`. Same widget tree the Pavilion sub-view used to host;
// now pushed over the Pavilion shell branch so the system back gesture works
// and the screen has its own go_router entry.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/v2/v2_kit.dart';
import '../../../matches/domain/entities/match_request.dart';
import '../../../matches/presentation/providers/matches_providers.dart';
import '../../../matches/presentation/providers/my_matches_providers.dart';
import '../../../matches/presentation/state/my_matches_view.dart';
import '../../../matches/presentation/widgets/withdraw_sheet.dart';

class MyMatchesScreen extends ConsumerStatefulWidget {
  const MyMatchesScreen({super.key});

  @override
  ConsumerState<MyMatchesScreen> createState() => _MyMatchesScreenState();
}

class _MyMatchesScreenState extends ConsumerState<MyMatchesScreen> {
  String _tab = 'confirmed';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(myMatchesViewProvider);
    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(
              title: 'My matches',
              // Pop back to Pavilion when there's a stack (normal in-app
              // navigation); fall back to /pavilion on a cold web load / deep
              // link where nothing is below.
              onBack: () =>
                  context.canPop() ? context.pop() : context.go('/pavilion'),
              right: const _ChallengeButton(),
            ),
            Expanded(
              child: async.when(
                loading: () => const _MyMatchesLoading(),
                error: (e, _) => _MyMatchesError(
                  message: e is FailureWrapper ? e.failure.message : e.toString(),
                  onRetry: () => ref.invalidate(myMatchesViewProvider),
                ),
                data: (view) => RefreshIndicator.adaptive(
                  onRefresh: () async => ref.invalidate(myMatchesViewProvider),
                  child: ListView(
                    padding: EdgeInsets.zero,
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      if (view.sent.isNotEmpty || view.inbound.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                          child: _RequestsSection(
                            inbound: view.inbound,
                            outbound: view.sent,
                            onOpen: (id) => context.push('/challenges/$id'),
                            onWithdraw: _onWithdraw,
                          ),
                        ),
                      if (view.pendingRequestsCount > 0)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                          child: _PendingRequestsBanner(
                            count: view.pendingRequestsCount,
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
                        child: _Segmented(
                          value: _tab,
                          tabs: [
                            (
                              id: 'confirmed',
                              label: 'Confirmed',
                              badge: view.confirmed.length,
                            ),
                            (
                              id: 'past',
                              label: 'Past',
                              badge: view.past.length,
                            ),
                          ],
                          onSelect: (v) => setState(() => _tab = v),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                        child: _tab == 'confirmed'
                            ? _confirmedBody(view)
                            : _pastBody(view),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _subhead(String label, String side) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 14, 0, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label.toUpperCase(), style: _monoLabel(color: CkColors.ink)),
            Text(side.toUpperCase(),
                style: CkType.mono(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.06,
                  color: CkColors.muted,
                )),
          ],
        ),
      );

  Widget _confirmedBody(MyMatchesView view) {
    if (view.confirmed.isEmpty) {
      return const _ConfirmedEmpty();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _subhead('Confirmed · ${view.confirmed.length}', 'upcoming'),
        for (var i = 0; i < view.confirmed.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _ConfirmedCard(v: view.confirmed[i]),
        ],
      ],
    );
  }

  Widget _pastBody(MyMatchesView view) {
    if (view.past.isEmpty) {
      return const _PastEmpty();
    }
    final total = view.totalPastCount;
    final shown = view.past.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _subhead('Past · $shown shown', 'most recent'),
        for (var i = 0; i < view.past.length; i++) ...[
          if (i > 0) const SizedBox(height: 6),
          _PastRow(m: _pastToRecord(view.past[i])),
        ],
        if (total > shown) ...[
          const SizedBox(height: 12),
          _SeeAllButton(label: 'SEE ALL $total MATCHES →'),
        ],
      ],
    );
  }

  Future<void> _onWithdraw(MyMatchRequest row) async {
    final result = await showModalBottomSheet<WithdrawResult>(
      context: context,
      backgroundColor: CkColors.paper,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => WithdrawSheet(
        opponentName: row.isOpen ? null : row.opponentName,
      ),
    );
    if (result == null || !mounted) return;
    final res = await ref.read(matchesRepositoryProvider).withdrawMatchChallenge(
          requestId: MatchRequestId(row.requestId),
          decisionNote: result.note,
        );
    if (!mounted) return;
    res.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(f.message)),
      ),
      (_) {
        ref.invalidate(myMatchChallengesProvider);
        ref.invalidate(myMatchesViewProvider);
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Header
// ═══════════════════════════════════════════════════════════════════════════

/// Back chevron + title + optional right widget. Matches the in-Pavilion
/// `_PvHeader` look so the visual transition from Pavilion → this screen is
/// invisible.
class _Header extends StatelessWidget {
  const _Header({required this.title, this.onBack, this.right});

  final String title;
  final VoidCallback? onBack;
  final Widget? right;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CkColors.hairline)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (onBack != null)
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 8),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onBack,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: V2Svg(
                    V2Icons.chevronLeft,
                    size: 22,
                    color: CkColors.ink,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
          Expanded(child: Text(title, style: _display(22))),
          if (right != null) ...[const SizedBox(width: 12), right!],
        ],
      ),
    );
  }
}

class _ChallengeButton extends StatelessWidget {
  const _ChallengeButton();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/challenge'),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: CkColors.paper,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: CkColors.hairline),
        ),
        child: Text('+ Challenge',
            style: CkType.body(fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// State views (loading / error / empty)
// ═══════════════════════════════════════════════════════════════════════════

class _MyMatchesLoading extends StatelessWidget {
  const _MyMatchesLoading();

  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 64),
          child: CircularProgressIndicator(),
        ),
      );
}

class _MyMatchesError extends StatelessWidget {
  const _MyMatchesError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 32, 18, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Couldn't load your matches.",
            style: CkType.display(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.01,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: CkType.body(fontSize: 12, color: CkColors.muted),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

class _ConfirmedEmpty extends StatelessWidget {
  const _ConfirmedEmpty();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 28, 18, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nothing on the schedule.',
            style: CkType.display(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.02,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Confirmed fixtures will appear here once you accept a "
            "challenge or your captain picks the XI.",
            style: CkType.body(
              fontSize: 12,
              color: CkColors.muted,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _PastEmpty extends StatelessWidget {
  const _PastEmpty();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 28, 18, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No past matches.',
            style: CkType.display(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.02,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Once you play or captain a match, the result will live here. "
            "It builds your career record.",
            style: CkType.body(
              fontSize: 12,
              color: CkColors.muted,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingRequestsBanner extends StatelessWidget {
  const _PendingRequestsBanner({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: const BoxDecoration(
          color: CkColors.paper,
          border: Border(
            top: BorderSide(color: CkColors.hairline),
            right: BorderSide(color: CkColors.hairline),
            bottom: BorderSide(color: CkColors.hairline),
            left: BorderSide(color: CkColors.amber, width: 3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                // oklch(0.94 0.05 90) — pale amber
                color: const Color(0xFFFBEFCF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const V2Svg(
                // chat-bubble (lines) from JSX
                '<path d="M4 4h16v12H5.17L4 17.17V4z"/><path d="M8 9h8M8 12h5"/>',
                size: 14,
                color: CkColors.amber,
                strokeWidth: 2.2,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$count match request${count == 1 ? '' : 's'} need your reply',
                    style: CkType.body(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Accept · counter · decline — tap challenge to review',
                      style: CkType.body(fontSize: 11, color: CkColors.muted),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text('OPEN →',
                style: CkType.mono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.08,
                  color: CkColors.amber,
                )),
          ],
        ),
      ),
    );
  }
}

class _RequestsSection extends StatelessWidget {
  const _RequestsSection({
    required this.inbound,
    required this.outbound,
    required this.onOpen,
    required this.onWithdraw,
  });

  final List<MyMatchRequest> inbound;
  final List<MyMatchRequest> outbound;
  final ValueChanged<String> onOpen;
  final ValueChanged<MyMatchRequest> onWithdraw;

  @override
  Widget build(BuildContext context) {
    final total = inbound.length + outbound.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'CHALLENGES · $total',
            style: _monoLabel(color: CkColors.ink),
          ),
        ),
        // Inbound Challenges First (Action required!)
        for (final req in inbound) ...[
          _InboundRequestRow(
            row: req,
            onOpen: () => onOpen(req.requestId),
          ),
          const SizedBox(height: 8),
        ],
        // Outbound Challenges
        for (var i = 0; i < outbound.length; i++) ...[
          if (i > 0 || inbound.isNotEmpty) const SizedBox(height: 8),
          _SentRequestRow(
            row: outbound[i],
            onOpen: () => onOpen(outbound[i].requestId),
            onWithdraw: () => onWithdraw(outbound[i]),
          ),
        ],
      ],
    );
  }
}

class _InboundRequestRow extends StatelessWidget {
  const _InboundRequestRow({
    required this.row,
    required this.onOpen,
  });

  final MyMatchRequest row;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final sub = [
      row.statusLabel,
      if (row.expiresLabel.isNotEmpty) row.expiresLabel,
    ].join(' · ');

    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: const BoxDecoration(
            color: CkColors.paper,
            border: Border(
              top: BorderSide(color: CkColors.hairline),
              right: BorderSide(color: CkColors.hairline),
              bottom: BorderSide(color: CkColors.hairline),
              left: BorderSide(color: Color(0xFFD97706), width: 3.5),
            ),
          ),
          child: Row(
            children: [
              _MiniCrest(short: row.opponentShort, color: row.opponentColor),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text('← ',
                            style: CkType.mono(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFD97706),
                            )),
                        Flexible(
                          child: Text(
                            row.opponentName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CkType.body(
                                fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        sub,
                        style: CkType.body(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: CkColors.ink,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Review →',
                  style: CkType.mono(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: CkColors.paper,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SentRequestRow extends StatelessWidget {
  const _SentRequestRow({
    required this.row,
    required this.onOpen,
    required this.onWithdraw,
  });

  final MyMatchRequest row;
  final VoidCallback onOpen;
  final VoidCallback onWithdraw;

  @override
  Widget build(BuildContext context) {
    final title = row.isOpen
        ? 'Open · code ${row.shareCode ?? '——'}'
        : row.opponentName;
    final sub = [
      row.statusLabel,
      if (row.expiresLabel.isNotEmpty) row.expiresLabel,
    ].join(' · ');
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(12),
      // Non-uniform border (amber left stripe) → round via ClipRRect, NOT a
      // borderRadius on the BoxDecoration. A borderRadius on a non-uniform
      // border throws at paint time and blanks the whole row.
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: const BoxDecoration(
            color: CkColors.paper,
            border: Border(
              top: BorderSide(color: CkColors.hairline),
              right: BorderSide(color: CkColors.hairline),
              bottom: BorderSide(color: CkColors.hairline),
              left: BorderSide(color: CkColors.amber, width: 3),
            ),
          ),
          child: Row(
            children: [
              _MiniCrest(short: row.opponentShort, color: row.opponentColor),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text('→ ',
                            style: CkType.mono(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0,
                              color: CkColors.muted,
                            )),
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CkType.body(
                                fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        sub,
                        style: CkType.body(fontSize: 11, color: CkColors.muted),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _WithdrawChip(onTap: onWithdraw),
            ],
          ),
        ),
      ),
    );
  }
}

class _WithdrawChip extends StatelessWidget {
  const _WithdrawChip({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: CkColors.paper,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: CkColors.line),
        ),
        child: Text(
          'Withdraw',
          style: CkType.body(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: CkColors.red,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Segmented control (Confirmed · Past)
// ═══════════════════════════════════════════════════════════════════════════

class _Segmented extends StatelessWidget {
  const _Segmented({
    required this.value,
    required this.tabs,
    required this.onSelect,
  });

  final String value;
  final List<({String id, String label, int badge})> tabs;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: CkColors.paper2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Row(
        children: [
          for (final t in tabs)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelect(t.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    color: value == t.id ? CkColors.paper : Colors.transparent,
                    borderRadius: BorderRadius.circular(7),
                    boxShadow: value == t.id
                        ? const [
                            BoxShadow(
                              color: Color(0x14281E0F), // rgba(40,30,15,0.08)
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        t.label,
                        style: CkType.body(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: value == t.id ? CkColors.ink : CkColors.muted,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color:
                              value == t.id ? CkColors.ink : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${t.badge}',
                          style: CkType.mono(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                            color:
                                value == t.id ? CkColors.paper : CkColors.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Confirmed card (+ pulsing dot, toss buttons)
// ═══════════════════════════════════════════════════════════════════════════

class _ConfirmedCard extends StatelessWidget {
  const _ConfirmedCard({required this.v});
  final MyMatchConfirmed v;

  @override
  Widget build(BuildContext context) {
    final captain = v.role.startsWith('Captain');
    final tossReady = v.tossReady;
    // Soft red wash for the header strip when toss-ready — oklch(0.97 0.018
    // 28) per the design source.
    const tossHeaderBg = Color(0xFFFFEEEC);

    return InkWell(
      // Live → scoring screen. Toss-ready → Match Start. Scheduled/upcoming → Match Detail.
      onTap: v.live
          ? () => _openScoring(context)
          : tossReady
              ? () => _openMatchStart(context)
              : () => _openMatchDetail(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: CkColors.paper,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (v.urgent || tossReady) ? CkColors.red : CkColors.hairline,
          ),
          boxShadow: tossReady
              ? const [
                  BoxShadow(
                    color: Color(0x2EBE3C28), // rgba(190,60,40,0.18)
                    blurRadius: 20,
                    offset: Offset(0, 6),
                  ),
                ]
              : v.urgent
                  ? const [
                      BoxShadow(
                        color: Color(0x14BE3C28), // rgba(190,60,40,0.08)
                        blurRadius: 16,
                        offset: Offset(0, 4),
                      ),
                    ]
                  : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header strip — soft red bg + pulsing dot in toss-ready mode.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: tossReady ? tossHeaderBg : CkColors.paper2,
                border: const Border(
                    bottom: BorderSide(color: CkColors.hairline)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (tossReady) ...[
                          const _PulsingDot(),
                          const SizedBox(width: 6),
                        ],
                        Flexible(
                          child: Text(
                            v.when.toUpperCase(),
                            overflow: TextOverflow.ellipsis,
                            style: CkType.mono(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.1,
                              color: (v.urgent || tossReady)
                                  ? CkColors.red
                                  : CkColors.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    v.tag,
                    style: CkType.mono(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.06,
                      color: CkColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            // Body.
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      _MiniCrest(short: v.homeShort, color: v.homeColor),
                      const SizedBox(width: 10),
                      Text('vs',
                          style: CkType.mono(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0,
                            color: CkColors.muted,
                          )),
                      const SizedBox(width: 10),
                      _MiniCrest(short: v.awayShort, color: v.awayColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${v.homeName} vs ${v.awayName}',
                              style: CkType.body(
                                  fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(v.venue,
                                  style: CkType.body(
                                      fontSize: 11, color: CkColors.muted)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.only(top: 8),
                    decoration: const BoxDecoration(
                      border:
                          Border(top: BorderSide(color: CkColors.hairline)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            (captain ? '✦ ' : '') + v.role,
                            style: CkType.mono(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.06,
                              color: captain ? CkColors.red : CkColors.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          v.countdown,
                          style: CkType.mono(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.06,
                            color: (v.urgent || tossReady)
                                ? CkColors.red
                                : CkColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (tossReady) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          flex: 14,
                          child: _TossActionButton(
                            label: 'Start match → Toss',
                            primary: true,
                            onTap: () => _openMatchStart(context),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 10,
                          child: _TossActionButton(
                            label: 'View squad',
                            onTap: () {/* squad view — follow-up */},
                          ),
                        ),
                      ],
                    ),
                    if (v.helper != null) ...[
                      const SizedBox(height: 6),
                      Center(
                        child: Text(
                          v.helper!,
                          textAlign: TextAlign.center,
                          style: CkType.body(
                            fontSize: 11,
                            color: CkColors.muted,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openMatchStart(BuildContext context) {
    context.push('/matches/${v.id}/start');
  }

  void _openMatchDetail(BuildContext context) {
    context.push('/pavilion/match/${v.id}');
  }

  void _openScoring(BuildContext context) {
    context.push('/matches/${v.id}/score');
  }
}

/// Red 7×7 dot that pulses with a 1.4s ease-in-out cycle (matches the
/// design's `pvm-pulse` keyframes: opacity 1 → 0.35 → 1).
class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Opacity(
        opacity: 0.35 + 0.65 * _c.value,
        child: Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: CkColors.red,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _TossActionButton extends StatelessWidget {
  const _TossActionButton({
    required this.label,
    required this.onTap,
    this.primary = false,
  });
  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: primary ? CkColors.red : CkColors.paper,
          border: primary ? null : Border.all(color: CkColors.hairline),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: CkType.body(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: primary ? CkColors.paper : CkColors.ink,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Past row
// ═══════════════════════════════════════════════════════════════════════════

typedef _Past = ({
  String id,
  String tag,
  String when,
  String homeShort,
  Color homeColor,
  int homeRuns,
  int homeWkts,
  String awayShort,
  Color awayColor,
  int awayRuns,
  int awayWkts,
  bool homeWon,
  String result,
  String mine,
});

_Past _pastToRecord(MyMatchPast v) => (
      id: v.id,
      tag: v.tag,
      when: v.when,
      homeShort: v.homeShort,
      homeColor: v.homeColor,
      homeRuns: v.homeRuns,
      homeWkts: v.homeWkts,
      awayShort: v.awayShort,
      awayColor: v.awayColor,
      awayRuns: v.awayRuns,
      awayWkts: v.awayWkts,
      homeWon: v.homeWon,
      result: v.result,
      mine: v.mine,
    );

class _PastRow extends StatelessWidget {
  const _PastRow({required this.m});
  final _Past m;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/matches/${m.id}'),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: CkColors.paper,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: CkColors.hairline),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(m.when.toUpperCase(),
                      style: CkType.mono(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.06,
                        color: CkColors.ink,
                      )),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(m.tag,
                        style: CkType.mono(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0,
                          color: CkColors.muted,
                        )),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _MiniCrest(short: m.homeShort, color: m.homeColor, size: 22),
            const SizedBox(width: 4),
            _MiniCrest(short: m.awayShort, color: m.awayColor, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text.rich(
                    TextSpan(
                      style: CkType.body(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      children: [
                        TextSpan(text: '${m.homeRuns}/${m.homeWkts} '),
                        TextSpan(
                          text: 'v',
                          style: CkType.body(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: CkColors.muted,
                          ),
                        ),
                        TextSpan(text: ' ${m.awayRuns}/${m.awayWkts}'),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(m.mine,
                        style: CkType.mono(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.04,
                          color: CkColors.muted,
                        )),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              m.result.split(' ').first.toUpperCase(),
              style: CkType.mono(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.08,
                color: m.homeWon ? CkColors.green : CkColors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeeAllButton extends StatelessWidget {
  const _SeeAllButton({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Text(
        label,
        style: CkType.mono(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.08,
          color: CkColors.ink2,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Atoms
// ═══════════════════════════════════════════════════════════════════════════

/// 28×22 r6 rounded-square crest (Inter Tight initials), size-parametric.
class _MiniCrest extends StatelessWidget {
  const _MiniCrest({required this.short, required this.color, this.size = 28});

  final String short;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular((size * 0.22).roundToDouble()),
      ),
      child: Text(
        short,
        style: CkType.display(
          fontSize: (size * 0.36).roundToDouble(),
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// monoLabel: JetBrains Mono 10 / 700 / 0.10em uppercase, default muted.
TextStyle _monoLabel({Color color = CkColors.muted}) => CkType.mono(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.10,
      color: color,
    );

/// display(size): Inter Tight 700 / -0.025em / line-height 1.05.
TextStyle _display(double size, {Color color = CkColors.ink}) => CkType.display(
      fontSize: size,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.025,
      height: 1.05,
      color: color,
    );
