import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/v2/v2_kit.dart';
import '../../../teams/domain/entities/team.dart';
import '../../../teams/presentation/providers/teams_providers.dart';
import '../../domain/entities/match_request.dart';
import '../providers/matches_providers.dart';
import '../widgets/challenge/ch_icons.dart';

/// "Success" screen for the Match Challenge Flow.
///
/// Two layouts off the same `matchChallenge(requestId)` read:
///
/// * Targeted (toTeamId != null) — 80px green check pop, headline
///   "Challenge sent to {opp}.", body "They have 48h to reply — you'll get
///   a ping the moment they do.", followed by a compact ink preview card
///   showing both crests + when + venue.
/// * Open (toTeamId == null) — same hero, different copy, plus a paper
///   share-code panel with the 6-digit code (mono 34pt, 0.18em), a
///   decorative deterministic QR, and Copy/Share buttons.
///
/// Sticky footer: "Back to matches" (ghost) + "See challenge" (ink). On the
/// open path "See challenge" still routes to the request detail.
class ChallengeSentScreen extends ConsumerStatefulWidget {
  const ChallengeSentScreen({super.key, required this.requestId});

  final String requestId;

  @override
  ConsumerState<ChallengeSentScreen> createState() =>
      _ChallengeSentScreenState();
}

class _ChallengeSentScreenState extends ConsumerState<ChallengeSentScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop;
  late final Animation<double> _popScale;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _pop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _popScale = Tween(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pop, curve: Curves.easeOutBack),
    );
    _pop.forward();
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    setState(() => _copied = true);
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(matchChallengeProvider(widget.requestId));
    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        bottom: false,
        child: async.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: CkColors.ink),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              e.toString(),
              style: CkType.body(fontSize: 12, color: CkColors.muted),
            ),
          ),
          data: (req) {
            if (req == null) {
              return Center(
                child: Text(
                  'Challenge not found',
                  style: CkType.body(fontSize: 14, color: CkColors.muted),
                ),
              );
            }
            return _ResolvedBody(
              request: req,
              popScale: _popScale,
              copied: _copied,
              onCopy: _copyCode,
            );
          },
        ),
      ),
    );
  }
}

class _ResolvedBody extends ConsumerWidget {
  const _ResolvedBody({
    required this.request,
    required this.popScale,
    required this.copied,
    required this.onCopy,
  });

  final MatchRequest request;
  final Animation<double> popScale;
  final bool copied;
  final ValueChanged<String> onCopy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teams = ref.watch(allTeamsProvider).maybeWhen(
          data: (t) => t,
          orElse: () => const <Team>[],
        );
    final fromTeam = _findTeam(teams, request.fromTeamId.value);
    final toTeam = request.toTeamId == null
        ? null
        : _findTeam(teams, request.toTeamId!.value);
    final isOpen = request.toTeamId == null;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 44, 24, 24),
            children: [
              _SuccessTile(scale: popScale),
              const SizedBox(height: 22),
              Text(
                isOpen
                    ? 'Open challenge is live.'
                    : 'Challenge sent to ${toTeam?.name ?? 'opponent'}.',
                textAlign: TextAlign.center,
                style: CkType.display(
                  fontSize: 27,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.025,
                  height: 1.14,
                ),
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Center(
                  child: Text(
                    isOpen
                        ? 'Share the code below. The first captain to claim it locks in the match.'
                        : 'They have 48h to reply — you’ll get a ping the moment they do.',
                    textAlign: TextAlign.center,
                    style: CkType.body(
                      fontSize: 13.5,
                      color: CkColors.ink2,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 26),
              if (isOpen && request.shareCode != null)
                _ShareCodePanel(
                  code: request.shareCode!,
                  copied: copied,
                  onCopy: () => onCopy(request.shareCode!),
                )
              else if (!isOpen)
                _TargetedPreview(
                  fromTeam: fromTeam,
                  toTeam: toTeam,
                  start: request.proposedStartTime,
                  venue: request.proposedVenue,
                ),
              if (isOpen) ...[
                const SizedBox(height: 14),
                Text(
                  'Show this to a captain — they have 24h to claim it.',
                  textAlign: TextAlign.center,
                  style: CkType.body(
                    fontSize: 12,
                    color: CkColors.muted,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
        _Footer(requestId: request.id.value),
      ],
    );
  }

  Team? _findTeam(List<Team> teams, String id) {
    for (final t in teams) {
      if (t.id.value == id) return t;
    }
    return null;
  }
}

class _SuccessTile extends StatelessWidget {
  const _SuccessTile({required this.scale});
  final Animation<double> scale;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ScaleTransition(
        scale: scale,
        child: Container(
          width: 80,
          height: 80,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: CkColors.green,
            borderRadius: BorderRadius.circular(22),
          ),
          child: const V2Svg(
            ChIcons.check,
            size: 38,
            color: CkColors.paper,
            strokeWidth: 2.6,
          ),
        ),
      ),
    );
  }
}

class _TargetedPreview extends StatelessWidget {
  const _TargetedPreview({
    required this.fromTeam,
    required this.toTeam,
    required this.start,
    required this.venue,
  });

  final Team? fromTeam;
  final Team? toTeam;
  final DateTime? start;
  final String? venue;

  static const _dow = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _mon = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String get _whenLabel {
    if (start == null) return 'Date TBD';
    final hh = start!.hour.toString().padLeft(2, '0');
    final mm = start!.minute.toString().padLeft(2, '0');
    return '${_dow[start!.weekday - 1]} ${start!.day} ${_mon[start!.month - 1]} · $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CkColors.ink,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _CrestTile(team: fromTeam),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${fromTeam?.name ?? '—'} vs ${toTeam?.name ?? '—'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CkType.display(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: CkColors.paper,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '$_whenLabel · ${venue?.trim().isNotEmpty == true ? venue!.trim() : 'Venue TBD'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CkType.body(
                    fontSize: 11,
                    color: CkColors.paper.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _CrestTile(team: toTeam),
        ],
      ),
    );
  }
}

class _CrestTile extends StatelessWidget {
  const _CrestTile({required this.team});
  final Team? team;

  String get _mono {
    final t = team;
    if (t == null) return '—';
    final override = t.logoMonogram?.trim();
    if (override != null && override.isNotEmpty) return override.toUpperCase();
    final parts =
        t.name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (parts.isEmpty) return '–';
    if (parts.length == 1) {
      final w = parts.first;
      return (w.length >= 2 ? w.substring(0, 2) : w).toUpperCase();
    }
    return (parts.first[0] + parts.elementAt(1)[0]).toUpperCase();
  }

  Color get _color {
    final hex = team?.primaryColor;
    if (hex == null || hex.isEmpty) return CkCrest.ll;
    final norm = hex.startsWith('#') ? hex.substring(1) : hex;
    final v = int.tryParse(norm, radix: 16);
    if (v == null) return CkCrest.ll;
    return Color(norm.length == 6 ? (0xFF000000 | v) : v);
  }

  @override
  Widget build(BuildContext context) {
    return Crest(
      short: _mono,
      color: _color,
      logoUrl: team?.logoUrl,
      size: 36,
      radius: 9,
    );
  }
}

class _ShareCodePanel extends StatelessWidget {
  const _ShareCodePanel({
    required this.code,
    required this.copied,
    required this.onCopy,
  });

  final String code;
  final bool copied;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'SHARE CODE · EXPIRES IN 24H',
            style: CkType.mono(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.10,
              color: CkColors.muted,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Text(
              code,
              style: CkType.mono(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.18,
                color: CkColors.ink,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _DecorativeQR(seed: code),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ShareButton(
                  primary: true,
                  icon: copied ? ChIcons.check : ChIcons.copy,
                  label: copied ? 'Copied' : 'Copy',
                  onTap: onCopy,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ShareButton(
                  primary: false,
                  icon: ChIcons.share,
                  label: 'Share',
                  onTap: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShareButton extends StatelessWidget {
  const _ShareButton({
    required this.primary,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool primary;
  final String icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = primary ? CkColors.ink : CkColors.paper;
    final fg = primary ? CkColors.paper : CkColors.ink;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(11),
          border: primary ? null : Border.all(color: CkColors.hairline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            V2Svg(icon, size: 15, color: fg, strokeWidth: 2),
            const SizedBox(width: 7),
            Text(
              label,
              style: CkType.body(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Decorative deterministic QR — labelled, not a real scannable code.
/// Ported from `challenge-app.jsx` lines 141–155.
class _DecorativeQR extends StatelessWidget {
  const _DecorativeQR({required this.seed});
  final String seed;

  static const _n = 11;
  static const _s = 9.0;

  List<bool> _buildCells() {
    var h = 0;
    for (final c in seed.codeUnits) {
      h = (h * 131 + c) & 0xFFFFFFFF;
    }
    final cells = <bool>[];
    for (var y = 0; y < _n; y++) {
      for (var x = 0; x < _n; x++) {
        h = (h * 1103515245 + 12345) & 0xFFFFFFFF;
        final corner = (x < 3 && y < 3) ||
            (x > _n - 4 && y < 3) ||
            (x < 3 && y > _n - 4);
        if (corner) {
          // Hand-stenciled positional markers as in the JSX.
          final on = (x == 0 ||
              x == 2 ||
              y == 0 ||
              y == 2 ||
              (x == 1 && y == 1) ||
              (x > _n - 4 && (x == _n - 1 || x == _n - 3)) ||
              (y > _n - 4 && (y == _n - 1 || y == _n - 3)));
          cells.add(on);
        } else {
          cells.add(h % 100 < 48);
        }
      }
    }
    return cells;
  }

  @override
  Widget build(BuildContext context) {
    final cells = _buildCells();
    return Center(
      child: SizedBox(
        width: _n * _s,
        height: _n * _s,
        child: GridView.count(
          crossAxisCount: _n,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final on in cells)
              Container(color: on ? CkColors.ink : Colors.transparent),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.requestId});
  final String requestId;

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.viewPaddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(18, 12, 18, 12 + safeBottom),
      decoration: const BoxDecoration(
        color: CkColors.paper,
        border: Border(top: BorderSide(color: CkColors.hairline)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => context.go('/pavilion/my-matches'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: CkColors.paper,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CkColors.hairline),
                ),
                child: Text(
                  'Back to matches',
                  style: CkType.body(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              // Push (not go) so the detail screen sits on top of the Sent
              // screen — tapping back on detail returns here; tapping
              // "Back to matches" on Sent still clears to My Matches.
              onTap: () => context.push('/challenges/$requestId'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: CkColors.ink,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'See challenge',
                  style: CkType.body(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: CkColors.paper,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
