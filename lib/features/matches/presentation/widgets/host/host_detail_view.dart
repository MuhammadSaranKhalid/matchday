import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../../../core/widgets/v2/v2_kit.dart';
import '../../../../teams/presentation/providers/teams_providers.dart';
import '../../../domain/entities/match_pool_application.dart';
import '../../../domain/entities/match_request.dart';
import '../../providers/matches_feed_providers.dart';
import '../pool/pool_challenge_card.dart';
import '../pool/pool_icons.dart';
import 'host_kit.dart';

/// The host's view of their own open challenge — `Pool.dc.html` artboards
/// 14 (waiting) and 15 (applicants).
///
/// One host marker: the amber HOSTING pill, inline with the title. The banner
/// sentence and the kicker the old screen carried are both gone.
///
/// A card here is a **row, not a decision**. Tapping opens the applicant,
/// where the single Accept lives — four stacked ink buttons made nothing
/// primary.
class HostDetailView extends ConsumerWidget {
  const HostDetailView({
    super.key,
    required this.request,
    required this.applications,
    required this.onBack,
    required this.onShare,
    required this.onWithdraw,
    required this.onOpenApplicant,
  });

  final MatchRequest request;
  final List<MatchPoolApplication> applications;
  final VoidCallback onBack;
  final VoidCallback onShare;
  final VoidCallback onWithdraw;
  final void Function(MatchPoolApplication) onOpenApplicant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final team = ref.watch(teamProvider(request.fromTeamId.value)).value;
    final item = OpenMatchPoolItem(
      request: request,
      fromTeam: team,
      formatLabel: '',
      venue: request.proposedVenue ?? '',
      shareCode: request.shareCode ?? '',
      timeLabel: '',
    );

    final pending =
        applications
            .where((a) => a.status == PoolApplicationStatus.pending)
            .toList();
    final settled =
        applications
            .where((a) => a.status != PoolApplicationStatus.pending)
            .toList();
    final waiting = applications.isEmpty;

    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: HostTopBar(
            title: 'Challenge',
            onBack: onBack,
            action: PoolIcons.share,
            trailing: onShare,
          ),
        ),
        if (!waiting) _ContextBar(item: item),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children:
                waiting
                    ? [
                      _WaitingHeader(item: item),
                      _SpecTable(item: item),
                      const HostSectionLabel('Applicants · 0'),
                      _WaitingCard(code: request.shareCode),
                      const SizedBox(height: 20),
                    ]
                    : [
                      HostSectionLabel(
                        'Applicants · ${applications.length}',
                        padding: const EdgeInsets.fromLTRB(16, 15, 16, 8),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            for (final app in [...pending, ...settled]) ...[
                              _ApplicantRow(
                                application: app,
                                playersPerSide: request.playersPerSide,
                                onTap: () => onOpenApplicant(app),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
          ),
        ),
        HostBottomBar(
          padding: EdgeInsets.fromLTRB(
            16,
            waiting ? 14 : 12,
            16,
            waiting ? 20 : 18,
          ),
          child: WithdrawLink(onTap: onWithdraw),
        ),
      ],
    );
  }
}

/// Artboard 14's title block — crest, "Your open challenge", HOSTING.
class _WaitingHeader extends StatelessWidget {
  const _WaitingHeader({required this.item});

  final OpenMatchPoolItem item;

  @override
  Widget build(BuildContext context) {
    final team = item.fromTeam;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CkStatusPill.banner(
            'Hosting',
            background: CkColors.amber,
            compact: true,
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Crest(
                short: teamMonogram(team),
                color: teamCrestColor(team),
                logoUrl: team?.logoUrl,
                size: 46,
                radius: 13,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Your open challenge',
                      style: CkType.display(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: CkColors.ink,
                        letterSpacing: -0.02,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${team?.name ?? 'Your team'} · looking for a game',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CkType.body(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: CkColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Artboard 15's cream strip — the same facts as 14's header, compressed to
/// one line so the applicants get the screen.
class _ContextBar extends StatelessWidget {
  const _ContextBar({required this.item});

  final OpenMatchPoolItem item;

  @override
  Widget build(BuildContext context) {
    final team = item.fromTeam;
    final start = item.startTime;
    final summary = [
      if (item.request.proposedFormat?.oversPerInnings case final o? when o > 0)
        '$o ov',
      switch (item.ballType.wire) {
        'leather' => 'Leather',
        'tennis' => 'Tennis-ball',
        _ => 'Tape-ball',
      },
      if (start != null) poolStartLabel(start).replaceFirst(' · ', ' '),
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: const BoxDecoration(
        color: CkColors.cream,
        border: Border(bottom: BorderSide(color: CkColors.creamBorder)),
      ),
      child: Row(
        children: [
          CkStatusPill.banner(
            'Hosting',
            background: CkColors.amber,
            compact: true,
          ),
          const SizedBox(width: 10),
          Crest(
            short: teamMonogram(team),
            color: teamCrestColor(team),
            logoUrl: team?.logoUrl,
            size: 30,
            radius: 9,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Your open challenge',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CkType.display(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: CkColors.ink,
                    letterSpacing: -0.01,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  summary.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CkType.mono(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.04,
                    color: CkColors.amberInk,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Artboard 14's ruled Format / When / Where / Expires table.
class _SpecTable extends StatelessWidget {
  const _SpecTable({required this.item});

  final OpenMatchPoolItem item;

  @override
  Widget build(BuildContext context) {
    final start = item.startTime;
    final expiry = hostExpiryLabel(item.expiresAt);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CkColors.line),
      ),
      child: Column(
        children: [
          _row('Format', Text(item.formatLine, style: _value), first: true),
          if (start != null)
            _row('When', Text(poolStartLabel(start), style: _value)),
          if (item.ground case final ground?)
            _row('Where', Text(ground, style: _value)),
          if (expiry != null)
            _row(
              'Expires',
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: CkColors.amber,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'In $expiry'.toUpperCase(),
                    style: CkType.mono(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.04,
                      color: CkColors.amberInk,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static TextStyle get _value => CkType.display(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: CkColors.ink,
    letterSpacing: 0,
  );

  Widget _row(String label, Widget value, {bool first = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        border:
            first
                ? null
                : const Border(top: BorderSide(color: CkColors.hairline)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 74,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                label.toUpperCase(),
                style: CkType.mono(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.07,
                  color: CkColors.muted,
                ),
              ),
            ),
          ),
          Expanded(child: value),
        ],
      ),
    );
  }
}

/// Artboard 14's dashed cream panel. The waiting state re-surfaces the share
/// code, because the only thing a host can do while waiting is reach captains
/// directly.
class _WaitingCard extends StatelessWidget {
  const _WaitingCard({required this.code});

  final String? code;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 2, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        color: CkColors.cream,
        borderRadius: BorderRadius.circular(16),
      ),
      foregroundDecoration: _dashed,
      child: Column(
        children: [
          Text(
            'Waiting for applicants',
            textAlign: TextAlign.center,
            style: CkType.display(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: CkColors.ink,
              letterSpacing: -0.01,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 250,
            child: Text(
              "We'll notify you the moment a team applies. Share the code to "
              'reach captains directly.',
              textAlign: TextAlign.center,
              style: CkType.body(
                fontSize: 11.5,
                height: 1.5,
                color: CkColors.ink2,
              ),
            ),
          ),
          if (code != null && code!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: CkColors.paper,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: CkColors.creamBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'CODE',
                    style: CkType.mono(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.06,
                      color: CkColors.muted,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    code!,
                    style: CkType.mono(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.16,
                      color: CkColors.ink,
                    ).copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static const _dashed = ShapeDecoration(
    shape: _DashedRoundedBorder(radius: 16, color: CkColors.creamBorder),
  );
}

/// A dashed rounded rectangle. Flutter has no dashed [BoxBorder], and the
/// design uses the dash to say "provisional" — a solid rule would read as a
/// settled panel.
class _DashedRoundedBorder extends ShapeBorder {
  const _DashedRoundedBorder({
    required this.radius,
    required this.color,
    this.width = 1,
  });

  final double radius;
  final Color color;
  final double width;

  static const _dash = 5.0;
  static const _gap = 4.0;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(width);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(
        RRect.fromRectAndRadius(rect.deflate(width), Radius.circular(radius)),
      );

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = width;

    final path =
        Path()..addRRect(
          RRect.fromRectAndRadius(
            rect.deflate(width / 2),
            Radius.circular(radius),
          ),
        );

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + _dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + _gap;
      }
    }
  }

  @override
  ShapeBorder scale(double t) =>
      _DashedRoundedBorder(radius: radius * t, color: color, width: width * t);
}

/// One applicant on artboard 15. Opens the applicant; it does not decide.
class _ApplicantRow extends ConsumerWidget {
  const _ApplicantRow({
    required this.application,
    required this.playersPerSide,
    required this.onTap,
  });

  final MatchPoolApplication application;
  final int playersPerSide;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final team =
        ref.watch(teamProvider(application.applicantTeamId.value)).value;
    final pending = application.status == PoolApplicationStatus.pending;
    final message = application.message?.trim();

    final card = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: pending ? CkColors.line : CkColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Crest(
                short: teamMonogram(team),
                color: teamCrestColor(team),
                logoUrl: team?.logoUrl,
                size: 40,
                radius: 11,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            team?.name ?? 'Applicant',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CkType.display(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: CkColors.ink,
                              letterSpacing: -0.01,
                            ),
                          ),
                        ),
                        if (team?.isVerified ?? false) ...[
                          const SizedBox(width: 6),
                          const PoolIcon(PoolIcons.verified, size: 12),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      applicantSummary(
                        application,
                        playersPerSide: playersPerSide,
                      ).toUpperCase(),
                      style: CkType.mono(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.05,
                        color: CkColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (pending)
                CkStatusPill.card('Pending')
              else
                const PoolIcon(PoolIcons.chevronDownSoft, size: 16),
            ],
          ),
          if (pending && message != null && message.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '“$message”',
              style: CkType.body(
                fontSize: 12.5,
                height: 1.5,
                color: CkColors.ink2,
              ).copyWith(fontStyle: FontStyle.italic),
            ),
          ],
          if (pending) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, thickness: 1, color: CkColors.hairline),
            const SizedBox(height: 11),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Review & decide'.toUpperCase(),
                  style: CkType.mono(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.07,
                    color: CkColors.muted,
                  ),
                ),
                const PoolIcon(PoolIcons.chevronRightSoft, size: 14),
              ],
            ),
          ],
        ],
      ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: pending ? card : Opacity(opacity: 0.9, child: card),
    );
  }
}

/// "11 named · applied 2h ago" — what the host needs to triage the row.
String applicantSummary(
  MatchPoolApplication app, {
  required int playersPerSide,
}) {
  final named = app.applicantXi.length;
  final squad =
      named == 0
          ? 'No XI named'
          : named >= playersPerSide
          ? 'Full squad'
          : '$named named';
  return '$squad · applied ${compactAgo(app.createdAt)}';
}

/// "2h ago" / "3d ago" — the design's compact form, not timeago's prose.
String compactAgo(DateTime at) {
  final d = DateTime.now().difference(at);
  if (d.inMinutes < 1) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  if (d.inDays < 7) return '${d.inDays}d ago';
  return '${(d.inDays / 7).floor()}w ago';
}

/// "41h" / "2d" for the host's Expires row. Null once it has lapsed.
String? hostExpiryLabel(DateTime? expiresAt) {
  if (expiresAt == null) return null;
  final left = expiresAt.difference(DateTime.now());
  if (left.isNegative) return null;
  if (left.inHours < 1) return '${left.inMinutes}m';
  if (left.inHours < 48) return '${left.inHours}h';
  return '${left.inDays}d';
}
