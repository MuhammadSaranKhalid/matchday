import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/circk_theme.dart';
import 'tp_atoms.dart';
import 'tp_view.dart';

/// Live match banner — inverted ink-on-paper live card.
class TpLiveBanner extends StatelessWidget {
  const TpLiveBanner({super.key, required this.data});
  final TpLiveCard data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: Container(
        decoration: BoxDecoration(
          color: CkColors.ink,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              offset: const Offset(0, 4),
              blurRadius: 16,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(5, 2, 6, 2),
                    decoration: BoxDecoration(
                      color: CkColors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const TpLivePulse(),
                        const SizedBox(width: 5),
                        Text(
                          'LIVE NOW',
                          style: tpMono(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      data.ctx,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tpMono(
                        fontSize: 9,
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _LiveSide(
                      name: data.us,
                      score: data.usScore,
                      alignEnd: false,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      'VS',
                      style: tpMono(
                        fontSize: 9,
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _LiveSide(
                      name: data.them,
                      score: data.themScore,
                      alignEnd: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.only(top: 10),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        data.note,
                        style: CkType.body(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.78),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        'WATCH LIVE',
                        style: tpMono(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveSide extends StatelessWidget {
  const _LiveSide({
    required this.name,
    required this.score,
    required this.alignEnd,
  });
  final String name;
  final String score;
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
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.02,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          score,
          style: tpMono(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

/// Tinted info banner — green / amber / red / gray. Circular icon, title +
/// body, optional CTA pill on the right.
class TpInfoBannerWidget extends StatelessWidget {
  const TpInfoBannerWidget({
    super.key,
    required this.banner,
    required this.teamId,
  });

  final TpInfoBanner banner;
  final String teamId;

  ({Color bg, Color border, Color accent, Color ctaBg}) get _tones {
    switch (banner.tone) {
      case TpInfoBannerTone.green:
        return (
          bg: CkColors.greenSoft,
          border: CkColors.green.withValues(alpha: 0.35),
          accent: CkColors.green,
          ctaBg: CkColors.green,
        );
      case TpInfoBannerTone.amber:
        return (
          bg: CkColors.cream,
          border: CkColors.amber.withValues(alpha: 0.45),
          accent: CkColors.amber,
          ctaBg: CkColors.amber,
        );
      case TpInfoBannerTone.red:
        return (
          bg: CkColors.redSoft,
          border: CkColors.red.withValues(alpha: 0.35),
          accent: CkColors.red,
          ctaBg: CkColors.red,
        );
      case TpInfoBannerTone.gray:
        return (
          bg: CkColors.paper2,
          border: CkColors.hairline,
          accent: CkColors.ink,
          ctaBg: CkColors.ink,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _tones;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: banner.cta != null ? () => context.push('/teams/$teamId/manage') : null,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: t.bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: t.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(color: t.ctaBg, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Icon(
                  banner.icon ?? Icons.info_outline,
                  size: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      banner.title,
                      style: CkType.display(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.01,
                        color: t.accent,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      banner.body,
                      style: CkType.body(
                        fontSize: 12,
                        color: t.accent.withValues(alpha: 0.85),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (banner.cta != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: t.ctaBg,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    banner.cta!,
                    style: CkType.body(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
