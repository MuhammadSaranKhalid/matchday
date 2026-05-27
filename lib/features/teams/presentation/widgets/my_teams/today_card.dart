import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../../../core/widgets/v2/v2_kit.dart';
import '../../state/my_teams_view.dart';
import 'crest_palette.dart';
import 'role_pill.dart';

/// Today / Live match hero card. Inverted ink-on-paper when [TodayMatch.live]
/// is true (the only inverted surface on the screen — impossible to miss).
/// Cream-tagged paper card with a "TODAY · {when}" eyebrow when not live.
class TodayCard extends StatelessWidget {
  const TodayCard({super.key, required this.data});
  final TodayMatch data;

  bool get _inverted => data.live;
  Color get _fg => _inverted ? CkColors.paper : CkColors.ink;
  Color get _mutedFg =>
      _inverted ? CkColors.paper.withValues(alpha: 0.60) : CkColors.muted;
  Color get _eyebrowFg =>
      _inverted ? CkColors.paper.withValues(alpha: 0.85) : CkColors.ink;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _inverted ? CkColors.ink : CkColors.paper,
          borderRadius: BorderRadius.circular(14),
          border: _inverted ? null : Border.all(color: CkColors.hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TopRow(
              live: data.live,
              when: data.when,
              ctx: data.ctx,
              role: data.role,
              mutedFg: _mutedFg,
              eyebrowFg: _eyebrowFg,
            ),
            const SizedBox(height: 10),
            _Sides(data: data, fg: _fg),
            if (data.note != null) ...[
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.only(top: 10),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: _inverted
                          ? CkColors.paper.withValues(alpha: 0.12)
                          : CkColors.hairline,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        data.note!,
                        style: CkType.body(
                          fontSize: 12,
                          color: _inverted
                              ? CkColors.paper.withValues(alpha: 0.75)
                              : CkColors.ink2,
                        ),
                      ),
                    ),
                    if (data.venue != null)
                      Text(
                        data.venue!,
                        style: CkType.mono(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.10,
                          color: _mutedFg,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TopRow extends StatelessWidget {
  const _TopRow({
    required this.live,
    required this.when,
    required this.ctx,
    required this.role,
    required this.mutedFg,
    required this.eyebrowFg,
  });
  final bool live;
  final String? when;
  final String? ctx;
  final String? role;
  final Color mutedFg;
  final Color eyebrowFg;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (live)
          const LivePill()
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: CkColors.cream,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'TODAY · ${when ?? ''}',
              style: CkType.mono(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.10,
                color: CkInk.amber,
              ),
            ),
          ),
        if (ctx != null) ...[
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              ctx!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CkType.mono(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.10,
                color: mutedFg,
              ),
            ),
          ),
        ],
        if (role != null) ...[
          const Spacer(),
          Text(
            role!,
            style: CkType.body(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: eyebrowFg,
            ),
          ),
        ],
      ],
    );
  }
}

class _Sides extends StatelessWidget {
  const _Sides({required this.data, required this.fg});
  final TodayMatch data;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MiniCrest(crest: data.a),
        const SizedBox(width: 12),
        Expanded(child: _SideName(name: data.a.name, score: data.aScore, fg: fg)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'VS',
            style: CkType.mono(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.10,
              color: data.live
                  ? CkColors.paper.withValues(alpha: 0.55)
                  : CkColors.muted,
            ),
          ),
        ),
        Expanded(
            child: _SideName(
                name: data.b.name, score: data.bScore, fg: fg, alignEnd: true)),
        const SizedBox(width: 12),
        _MiniCrest(crest: data.b),
      ],
    );
  }
}

class _MiniCrest extends StatelessWidget {
  const _MiniCrest({required this.crest});
  final CrestStyle crest;

  Widget _mono() => Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: crest.color,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          crest.mono,
          style: CkType.display(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.03,
            color: CkColors.paper,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (crest.logoUrl == null || crest.logoUrl!.isEmpty) return _mono();
    final memW = (32 * MediaQuery.devicePixelRatioOf(context)).round();
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        color: CkColors.paper2,
        child: CachedNetworkImage(
          imageUrl: crest.logoUrl!,
          fit: BoxFit.cover,
          width: 32,
          height: 32,
          memCacheWidth: memW,
          errorWidget: (_, __, ___) => _mono(),
          placeholder: (_, __) => _mono(),
        ),
      ),
    );
  }
}

class _SideName extends StatelessWidget {
  const _SideName({
    required this.name,
    required this.score,
    required this.fg,
    this.alignEnd = false,
  });
  final String name;
  final String? score;
  final Color fg;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: CkType.display(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.02,
            color: fg,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          score ?? '—',
          style: CkType.mono(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
            color: fg,
          ),
        ),
      ],
    );
  }
}
