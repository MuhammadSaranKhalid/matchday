// Notifications "bell portal" screen.
//
// Faithful Flutter port of `V2NotificationsBell` from the matchday v2 design
// prototype (`screens/v2-IA.jsx`, ~lines 2426–2706). Presentation-only with
// inline mock data; every action button is inert, mirroring the prototype.
// There is intentionally NO settings/gear icon and NO bottom nav here —
// Notifications is a destination reached from the bell, not a tab.
import 'package:flutter/material.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/v2/v2_kit.dart';

/// Extra inline-SVG path data for icon tiles not present in [V2Icons].
abstract final class _NotifIcons {
  // clock — circle + hour/minute hands
  static const clock =
      '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>';
  // phone-lock — tall rounded rect with a small base notch (new device)
  static const phone =
      '<rect x="6" y="3" width="12" height="18" rx="2"/><path d="M11 18h2"/>';
  // up arrow (ranking)
  static const upArrow = '<path d="M12 19V5M5 12l7-7 7 7"/>';
  // shield + check (system / verified)
  static const shieldCheck =
      '<path d="M12 2l9 4v6c0 5-3.5 9-9 10-5.5-1-9-5-9-10V6l9-4z"/>'
      '<path d="M9 12l2 2 4-5"/>';
}

class NotificationsBellScreen extends StatelessWidget {
  const NotificationsBellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            _CompactNav(onBack: () => Navigator.of(context).maybePop()),
            const _TitleBlock(),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: const [
                  // ── REPLY NOW ──────────────────────────────────────────
                  _TierHead(label: 'REPLY NOW', count: 6, tone: _Tone.red),

                  _NotifRow(
                    tone: _Tone.red,
                    tag: 'MATCH REQUEST · expires 23h',
                    icon: _CrestIcon(short: 'LL', color: CkCrest.ll),
                    bodySpans: [
                      _Span('Lahore Lions', bold: true),
                      _Span(' challenged you to a friendly'),
                    ],
                    sub: 'Sat 25 May · 4 PM · 20 ov · Model Town',
                    actions: ['Accept', 'Counter', 'Decline'],
                    primary: true,
                    unread: true,
                    urgent: true,
                  ),

                  _NotifRow(
                    tone: _Tone.red,
                    tag: 'ROSTER · 5m',
                    icon: _CrestIcon(short: 'KE', color: CkCrest.ke),
                    bodySpans: [
                      _Span('Faraz dropped — you\'re '),
                      _Span('1 short', bold: true),
                      _Span(' for Sat\'s match'),
                    ],
                    sub: 'vs Lahore Lions · 3 PM · Model Town',
                    actions: ['View squad', 'Mute'],
                    unread: true,
                    urgent: true,
                  ),

                  _NotifRow(
                    tone: _Tone.red,
                    tag: 'STARTING · 1h 20m',
                    icon: _TileIcon(
                      bg: CkColors.redSoft,
                      svg: _NotifIcons.clock,
                      svgColor: CkInk.red,
                      strokeWidth: 2,
                    ),
                    bodySpans: [
                      _Span('Spring Cup \'26 · QF', bold: true),
                      _Span(' starts at 4 PM'),
                    ],
                    sub: 'Karachi Eagles vs Multan Tigers · Gaddafi B',
                    actions: ['Open'],
                    unread: true,
                  ),

                  _NotifRow(
                    tone: _Tone.red,
                    tag: 'TEAM INVITE · 12m',
                    icon: _CrestIcon(short: 'LL', color: CkCrest.ll),
                    bodySpans: [
                      _Span('Bilal invited you to '),
                      _Span('Lahore Lions', bold: true),
                    ],
                    sub: 'Squad of 14 · Player · Jersey #7 · Lahore',
                    actions: ['Accept', 'Decline'],
                    primary: true,
                    unread: true,
                  ),

                  _NotifRow(
                    tone: _Tone.red,
                    tag: 'SCORER · 1h',
                    icon: _AvatarIcon(mono: 'IS', tone: AvatarTone.ink),
                    bodySpans: [
                      _Span('Imran assigned you as '),
                      _Span('scorer', bold: true),
                      _Span(' for the Final'),
                    ],
                    sub: 'Sat 18 May · 5 PM · Lahore Lions vs Karachi XI',
                    actions: ['Accept', 'Decline'],
                    primary: true,
                    unread: true,
                  ),

                  _NotifRow(
                    tone: _Tone.red,
                    tag: 'SECURITY · just now',
                    icon: _TileIcon(
                      bg: CkColors.redSoft,
                      svg: _NotifIcons.phone,
                      svgColor: CkInk.red,
                      strokeWidth: 1.8,
                    ),
                    bodySpans: [
                      _Span('New device sign-in on '),
                      _Span('iPhone 15', bold: true),
                    ],
                    sub: 'Karachi · Apple ID · if this wasn\'t you, secure '
                        'your account',
                    actions: ['This was me', 'Sign out'],
                    unread: true,
                  ),

                  // ── THIS WEEK ──────────────────────────────────────────
                  _TierHead(label: 'THIS WEEK', count: 7, tone: _Tone.amber),

                  _NotifRow(
                    tag: 'MATCH REQUEST · Wed',
                    icon: _CrestIcon(short: 'MK', color: CkCrest.mk),
                    bodySpans: [
                      _Span('Your challenge to '),
                      _Span('Mohalla Kings', bold: true),
                      _Span(' is awaiting reply'),
                    ],
                    sub: 'Sat 25 May · 4 PM · sent 1d ago',
                    actions: ['View', 'Cancel'],
                  ),

                  _NotifRow(
                    tag: 'TOURNAMENT · Tue',
                    icon: _CrestIcon(short: 'SC', color: CkCrest.sc),
                    bodySpans: [
                      _Span('Your registration to '),
                      _Span('Spring Cup \'26', bold: true),
                      _Span(' was approved'),
                    ],
                    sub: 'Group A · R1 vs Multan Tigers · Tue 14 May',
                  ),

                  _NotifRow(
                    tag: 'CLAIM · Mon',
                    icon: _AvatarIcon(mono: 'AK', tone: AvatarTone.paper),
                    bodySpans: [
                      _Span('Ahmed wants to claim '),
                      _Span('"Ahmed K."', bold: true),
                      _Span(' in your squad'),
                    ],
                    sub: 'Added Mar 2024 · 22 matches · 312 runs',
                    actions: ['Approve', 'Reject'],
                  ),

                  _NotifRow(
                    tag: 'FIXTURE · Mon',
                    icon: _TextTileIcon(
                      bg: CkColors.paper2,
                      text: 'vs',
                      color: CkColors.muted,
                      fontSize: 13,
                    ),
                    bodySpans: [
                      _Span('Match vs '),
                      _Span('Karachi Cobras', bold: true),
                      _Span(' moved to Sat 18 May, 3 PM'),
                    ],
                    sub: 'Was Fri 17 May, 4 PM · Reason: rain forecast',
                  ),

                  _NotifRow(
                    tag: 'TEAM · Mon',
                    icon: _AvatarIcon(mono: 'BA', tone: AvatarTone.ink),
                    bodySpans: [
                      _Span('Bilal made you '),
                      _Span('vice-captain', bold: true),
                      _Span(' of Lahore Lions'),
                    ],
                    sub: 'Effective from next match · Was Player',
                  ),

                  _NotifRow(
                    tag: 'ORGANIZER · Sun',
                    icon: _CrestIcon(short: 'SC', color: CkCrest.sc),
                    bodySpans: [
                      _Span('2 teams', bold: true),
                      _Span(' registered for Spring Cup \'26'),
                    ],
                    sub: 'Multan Tigers · Karachi Cobras · awaiting your '
                        'approval',
                    actions: ['Review'],
                  ),

                  _NotifRow(
                    tag: 'RECRUITMENT · Sat',
                    icon: _CrestIcon(short: 'KR', color: Color(0xFF3F5C99)),
                    bodySpans: [
                      _Span('Karachi Royals', bold: true),
                      _Span(' is looking for a wicket-keeper'),
                    ],
                    sub: 'Matches your role · club · Karachi · apply by Wed',
                    actions: ['View', 'Mute'],
                  ),

                  // ── FYI ────────────────────────────────────────────────
                  _TierHead(label: 'FYI', count: 11, tone: _Tone.neutral),

                  _NotifRow(
                    tag: 'MILESTONE · Sun',
                    icon: _TextTileIcon(
                      bg: CkColors.ink,
                      text: '67*',
                      color: CkColors.paper,
                      fontSize: 12,
                    ),
                    bodySpans: [
                      _Span('67* vs Karachi Cobras', bold: true),
                      _Span(' — your highest score'),
                    ],
                    sub: '4 fours · 3 sixes · SR 142 · Spring Cup QF',
                  ),

                  _NotifRow(
                    tag: 'MATCH RESULT · Sun',
                    icon: _TileIcon(
                      bg: CkColors.ink,
                      svg: V2Icons.check,
                      svgColor: CkColors.paper,
                      strokeWidth: 2,
                    ),
                    bodySpans: [
                      _Span('Lahore Lions won by '),
                      _Span('23 runs', bold: true),
                      _Span(' vs Multan Tigers'),
                    ],
                    sub: 'R1 · 142/6 (20) defended 119/9 (20)',
                  ),

                  _NotifRow(
                    tag: 'AWARD · Sat',
                    icon: _EmojiTileIcon(
                      bg: CkColors.cream,
                      emoji: '♕',
                      color: CkInk.amber,
                    ),
                    bodySpans: [
                      _Span('You won '),
                      _Span('Player of the Match', bold: true),
                      _Span(' · R1'),
                    ],
                    sub: '67* (43) · 2/19 · 1 catch',
                    actions: ['Share'],
                  ),

                  _NotifRow(
                    tag: 'CLAIM APPROVED · Sat',
                    icon: _TileIcon(
                      bg: CkColors.greenSoft,
                      svg: V2Icons.check,
                      svgColor: CkInk.green,
                      strokeWidth: 2.4,
                    ),
                    bodySpans: [
                      _Span('Your claim on '),
                      _Span('"Bilal K. · Spring \'23"', bold: true),
                      _Span(' was approved'),
                    ],
                    sub: '180 runs · 9 wkts · 4 catches migrated to your '
                        'profile',
                  ),

                  _NotifRow(
                    tag: 'RANKING · Fri',
                    icon: _TileIcon(
                      bg: CkColors.greenSoft,
                      svg: _NotifIcons.upArrow,
                      svgColor: CkInk.green,
                      strokeWidth: 2,
                    ),
                    bodySpans: [
                      _Span('You entered the '),
                      _Span('Top 50 batters · Punjab', bold: true),
                    ],
                    sub: 'Up 8 places this week · #47 · 1,012 career runs',
                  ),

                  _NotifRow(
                    tag: 'COMMENT · Fri',
                    icon: _AvatarIcon(mono: 'JA', tone: AvatarTone.paper),
                    bodySpans: [
                      _Span('Junaid Ali', bold: true),
                      _Span(' commented on your post'),
                    ],
                    sub: '"Brilliant innings bro 🔥 bring the bat to our '
                        'ground next time"',
                    actions: ['Reply'],
                  ),

                  _NotifRow(
                    tag: 'LIKES · Fri',
                    icon: _EmojiTileIcon(
                      bg: CkColors.redSoft,
                      emoji: '♥',
                      color: CkColors.red,
                    ),
                    bodySpans: [
                      _Span('Usman', bold: true),
                      _Span(' and '),
                      _Span('4 others', bold: true),
                      _Span(' liked your post'),
                    ],
                    sub: '"3 in 4 balls — best over of my life"',
                  ),

                  _NotifRow(
                    tag: 'MENTION · Fri',
                    icon: _AvatarIcon(mono: 'FK', tone: AvatarTone.paper),
                    bodySpans: [
                      _Span('@faraz', bold: true),
                      _Span(' mentioned you in a post'),
                    ],
                    sub: '"Best opening partnership ever with @bilal — 88 '
                        'in 7…"',
                  ),

                  _NotifRow(
                    tag: 'FOLLOW · Fri',
                    icon: _AvatarIcon(mono: 'AS', tone: AvatarTone.paper),
                    bodySpans: [
                      _Span('Adeel Sheikh', bold: true),
                      _Span(' started following you'),
                    ],
                    sub: 'Wicket-keeper · Lahore · 22 matches',
                  ),

                  _NotifRow(
                    tag: 'BRACKET · Thu',
                    icon: _CrestIcon(short: 'SC', color: CkCrest.sc),
                    bodySpans: [
                      _Span('Spring Cup \'26', bold: true),
                      _Span(' published its bracket'),
                    ],
                    sub: '8 teams · Lions seeded #3 · R1 vs Multan Tigers',
                  ),

                  _NotifRow(
                    tag: 'SYSTEM · Thu',
                    icon: _TileIcon(
                      bg: CkColors.paper2,
                      svg: _NotifIcons.shieldCheck,
                      svgColor: CkColors.muted,
                      strokeWidth: 1.8,
                    ),
                    bodySpans: [
                      _Span('Your phone '),
                      _Span('+92 300 ··· 4521', bold: true),
                      _Span(' was verified'),
                    ],
                    sub: 'Account secured · 2-step recovery active',
                  ),

                  _Footer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// Compact nav — back · BELL PORTAL · MARK ALL READ
// ════════════════════════════════════════════════════════════════════════

class _CompactNav extends StatelessWidget {
  const _CompactNav({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onBack,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const V2Svg(
                    V2Icons.chevronLeft,
                    size: 20,
                    color: CkColors.ink,
                    strokeWidth: 2,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Home',
                    style: CkType.body(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Text(
            'BELL PORTAL',
            style: CkType.mono(
              fontSize: 9.5,
              letterSpacing: 0.10,
              color: CkColors.muted,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(6),
            child: Text(
              'MARK ALL READ',
              style: CkType.mono(
                fontSize: 9.5,
                letterSpacing: 0.10,
                color: CkColors.ink2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// Title block — "Notifications" + "6 need you · 24 total"
// ════════════════════════════════════════════════════════════════════════

class _TitleBlock extends StatelessWidget {
  const _TitleBlock();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Notifications', style: CkType.display(fontSize: 26)),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text.rich(
              TextSpan(
                style: CkType.body(fontSize: 12, color: CkColors.muted),
                children: [
                  TextSpan(
                    text: '6 need you',
                    style: CkType.body(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: CkColors.ink,
                    ),
                  ),
                  const TextSpan(text: ' · 24 total'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// TierHead — coloured dot + label + · count
// ════════════════════════════════════════════════════════════════════════

enum _Tone { red, amber, neutral }

class _TierHead extends StatelessWidget {
  const _TierHead({
    required this.label,
    required this.count,
    required this.tone,
  });

  final String label;
  final int count;
  final _Tone tone;

  @override
  Widget build(BuildContext context) {
    final dot = switch (tone) {
      _Tone.red => CkColors.red,
      _Tone.amber => CkColors.amber,
      _Tone.neutral => CkColors.muted,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: CkType.mono(
              fontSize: 10,
              letterSpacing: 0.10,
              color: CkColors.ink,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '· $count',
            style: CkType.mono(
              fontSize: 10,
              letterSpacing: 0.10,
              color: CkColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// NotifRow
// ════════════════════════════════════════════════════════════════════════

/// One run of body text, optionally bold.
class _Span {
  const _Span(this.text, {this.bold = false});
  final String text;
  final bool bold;
}

class _NotifRow extends StatelessWidget {
  const _NotifRow({
    this.tone = _Tone.neutral,
    required this.tag,
    required this.icon,
    required this.bodySpans,
    this.sub,
    this.actions,
    this.primary = false,
    this.unread = false,
    this.urgent = false,
  });

  final _Tone tone;
  final String tag;
  final Widget icon;
  final List<_Span> bodySpans;
  final String? sub;
  final List<String>? actions;
  final bool primary;
  final bool unread;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    final tagColor = tone == _Tone.red ? CkColors.red : CkColors.muted;
    return Container(
      decoration: const BoxDecoration(
        color: CkColors.paper,
        border: Border(top: BorderSide(color: CkColors.hairline)),
      ),
      child: Stack(
        children: [
          if (unread)
            Positioned(
              left: 0,
              top: 14,
              bottom: 14,
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                  color: urgent ? CkColors.red : CkColors.ink2,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(2),
                    bottomRight: Radius.circular(2),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 13, 18, 13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                icon,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          tag,
                          style: CkType.mono(
                            fontSize: 9,
                            letterSpacing: 0.10,
                            color: tagColor,
                          ),
                        ),
                      ),
                      Text.rich(
                        TextSpan(
                          style: CkType.body(
                            fontSize: 13.5,
                            height: 1.35,
                            color: CkColors.ink,
                          ),
                          children: [
                            for (final s in bodySpans)
                              TextSpan(
                                text: s.text,
                                style: s.bold
                                    ? const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      )
                                    : null,
                              ),
                          ],
                        ),
                      ),
                      if (sub != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            sub!,
                            style: CkType.body(
                              fontSize: 11.5,
                              height: 1.4,
                              color: CkColors.muted,
                            ),
                          ),
                        ),
                      if (actions != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (var i = 0; i < actions!.length; i++)
                                _ActionButton(
                                  label: actions![i],
                                  isPrimary: primary && i == 0,
                                ),
                            ],
                          ),
                        ),
                    ],
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.isPrimary});

  final String label;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isPrimary ? CkColors.ink : CkColors.paper,
        borderRadius: BorderRadius.circular(999),
        border: isPrimary ? null : Border.all(color: CkColors.hairline),
      ),
      child: Text(
        label,
        style: CkType.body(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isPrimary ? CkColors.paper : CkColors.ink,
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// Icon slots — 32px crest / avatar / rounded-9 tiles
// ════════════════════════════════════════════════════════════════════════

class _CrestIcon extends StatelessWidget {
  const _CrestIcon({required this.short, required this.color});
  final String short;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      Crest(short: short, color: color, size: 32, radius: 9);
}

class _AvatarIcon extends StatelessWidget {
  const _AvatarIcon({required this.mono, required this.tone});
  final String mono;
  final AvatarTone tone;

  @override
  Widget build(BuildContext context) =>
      Avatar(mono: mono, size: 32, tone: tone);
}

/// 32×32 rounded-9 tile carrying an inline SVG glyph.
class _TileIcon extends StatelessWidget {
  const _TileIcon({
    required this.bg,
    required this.svg,
    required this.svgColor,
    this.strokeWidth = 1.8,
  });

  final Color bg;
  final String svg;
  final Color svgColor;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9),
      ),
      child: V2Svg(
        svg,
        size: 16,
        color: svgColor,
        strokeWidth: strokeWidth,
      ),
    );
  }
}

/// 32×32 rounded-9 tile carrying short Inter Tight text (e.g. "vs", "67*").
class _TextTileIcon extends StatelessWidget {
  const _TextTileIcon({
    required this.bg,
    required this.text,
    required this.color,
    required this.fontSize,
  });

  final Color bg;
  final String text;
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        text,
        style: CkType.display(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

/// 32×32 rounded-9 tile carrying a single emoji/symbol glyph (♕, ♥).
class _EmojiTileIcon extends StatelessWidget {
  const _EmojiTileIcon({
    required this.bg,
    required this.emoji,
    required this.color,
  });

  final Color bg;
  final String emoji;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(emoji, style: TextStyle(fontSize: 16, color: color)),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// Footer — END OF INBOX
// ════════════════════════════════════════════════════════════════════════

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
      margin: const EdgeInsets.only(top: 4),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: CkColors.hairline)),
      ),
      alignment: Alignment.center,
      child: Text(
        'END OF INBOX',
        style: CkType.mono(
          fontSize: 9,
          letterSpacing: 0.10,
          color: CkColors.muted,
        ),
      ),
    );
  }
}
