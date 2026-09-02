import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../../../core/widgets/v2/v2_kit.dart';
import '../../../domain/entities/match_request.dart';
import '../../providers/match_pool_providers.dart';
import '../../providers/matches_feed_providers.dart';
import '../pool/pool_challenge_card.dart';
import 'host_kit.dart';

/// A live challenge on the host's own list — `Pool.dc.html` artboard 12.
///
/// The board's card states a fixture; this one states a fixture *you own*, so
/// it adds the three things only the host can act on: the HOSTING pill, the
/// pending applicant count, and the share code. The count appears here and
/// nowhere else on the list.
class MyChallengeCard extends StatelessWidget {
  const MyChallengeCard({super.key, required this.row, this.onTap});

  final MyChallengeRow row;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final item = row.item;
    final team = item.fromTeam;
    final code = item.request.shareCode;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        decoration: BoxDecoration(
          color: CkColors.paper,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CkColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Crest(
                  short: teamMonogram(team),
                  color: teamCrestColor(team),
                  logoUrl: team?.logoUrl,
                  size: 42,
                  radius: 12,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      team?.name ?? 'Your team',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CkType.display(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: CkColors.ink,
                        letterSpacing: -0.01,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CkStatusPill.banner('Hosting', background: CkColors.amber),
              ],
            ),
            const SizedBox(height: 11),
            Text(
              item.formatLine.toUpperCase(),
              style: CkType.mono(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.04,
                color: CkColors.ink,
              ),
            ),
            if (_whenWhere(item) case final line?) ...[
              const SizedBox(height: 11),
              Text(
                line,
                style: CkType.display(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: CkColors.ink,
                  letterSpacing: -0.01,
                ),
              ),
            ],
            const SizedBox(height: 11),
            const Divider(height: 1, thickness: 1, color: CkColors.hairline),
            const SizedBox(height: 11),
            Row(
              children: [
                Expanded(child: _Applicants(count: row.pendingApplicants)),
                if (code != null && code.isNotEmpty) ShareCodeChip(code),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// "4 Applicants" behind an amber counter, or the plain waiting line.
class _Applicants extends StatelessWidget {
  const _Applicants({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    if (count == 0) {
      return Text(
        'No applicants yet'.toUpperCase(),
        style: CkType.mono(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.03,
          color: CkColors.muted,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: CkColors.amber,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '$count',
            style: CkType.display(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: CkColors.ink,
              letterSpacing: 0,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          (count == 1 ? 'Applicant' : 'Applicants').toUpperCase(),
          style: CkType.mono(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.03,
            color: CkColors.ink,
          ),
        ),
      ],
    );
  }
}

/// A settled challenge — `Pool.dc.html` artboard 12, "Past · closed".
///
/// Compact and on paper-2: it is a record, not something to act on.
class PastChallengeRow extends StatelessWidget {
  const PastChallengeRow({super.key, required this.row, this.onTap});

  final MyChallengeRow row;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final opponent = row.opponent;
    final settled = row.request.decidedAt ?? row.request.updatedAt;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Opacity(
        opacity: 0.85,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: CkColors.paper2,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: CkColors.hairline),
          ),
          child: Row(
            children: [
              Crest(
                short: teamMonogram(opponent ?? row.item.fromTeam),
                color: teamCrestColor(opponent ?? row.item.fromTeam),
                logoUrl: (opponent ?? row.item.fromTeam)?.logoUrl,
                size: 36,
                radius: 10,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      opponent == null
                          ? 'Your open challenge'
                          : 'v ${opponent.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CkType.display(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: CkColors.ink2,
                        letterSpacing: -0.01,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_shortDate(settled)} · ${_statusWord(row)}'
                          .toUpperCase(),
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
              const SizedBox(width: 10),
              row.matched
                  ? CkStatusPill.banner(
                      'Matched',
                      background: CkColors.greenSoft,
                      foreground: CkColors.greenInk,
                    )
                  : CkStatusPill.banner(
                      'Closed',
                      background: CkColors.soft,
                      foreground: CkColors.paper,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

String _statusWord(MyChallengeRow row) => switch (row.request.status) {
      MatchRequestStatus.accepted => 'Accepted',
      MatchRequestStatus.declined => 'Declined',
      MatchRequestStatus.cancelled => 'Withdrawn',
      MatchRequestStatus.expired => 'Expired',
      _ => 'Closed',
    };

/// "Aug 17" — the past list is a ledger, so the year is only worth the space
/// once the entry is not from this one.
String _shortDate(DateTime dt) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final label = '${months[dt.month - 1]} ${dt.day}';
  return dt.year == DateTime.now().year ? label : '$label ${dt.year}';
}

/// "Today · 4:30 PM · Gaddafi B Ground", dropping whatever the host left out.
String? _whenWhere(OpenMatchPoolItem item) {
  final parts = <String>[
    if (item.startTime case final start?) poolStartLabel(start),
    if (item.ground case final ground?) ground,
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}
