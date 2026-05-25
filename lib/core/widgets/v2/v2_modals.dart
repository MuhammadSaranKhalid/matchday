// v2 shared modals & detail surfaces — faithful ports of the inline stubs in
// `matchday v2 Prototype.html`: the Comments bottom sheet, the Team Page
// (opened by tapping a team crest), and the post Composer (opened by the
// Profile FAB).
import 'package:flutter/material.dart';

import '../../theme/circk_theme.dart';
import 'v2_kit.dart';

/// Identity passed when opening a team crest from the feed.
class TeamMeta {
  const TeamMeta({required this.name, required this.mono, required this.color});
  final String name;
  final String mono;
  final Color color;
}

/// Rises a Comments bottom sheet over the current screen (post peeks behind via
/// the dim backdrop). Drag the grabber or tap the scrim to dismiss.
Future<void> showCommentsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x73140A06), // rgba(20,16,10,0.45)
    builder: (_) => const _CommentsSheet(),
  );
}

class _Comment {
  const _Comment({
    required this.mono,
    required this.name,
    required this.t,
    required this.body,
    this.likes,
    this.me = false,
    this.indent = false,
  });
  final String mono;
  final String name;
  final String t;
  final String body;
  final int? likes;
  final bool me;
  final bool indent;
}

const _comments = <_Comment>[
  _Comment(mono: 'IS', name: 'Imran Saeed', t: '12m', body: 'No way bro, what a shot 🔥', likes: 8),
  _Comment(mono: 'FK', name: 'Faraz Khan', t: '18m', body: 'The pull off Asad in the 17th was something else.'),
  _Comment(mono: 'BA', name: 'Bilal Ahmed', t: '15m', me: true, body: 'Felt it from the toss yaar', indent: true),
  _Comment(mono: 'FK', name: 'Faraz Khan', t: '14m', body: 'And then YOU dropped him on 22 next over 😭', indent: true),
  _Comment(mono: 'AK', name: 'Ahmed K.', t: '22m', body: '“Cleanest cover drive I’ve seen all season.”'),
  _Comment(mono: 'AS', name: 'Adeel Sheikh', t: '34m', body: 'Khel khatam karne ka asli mazaa.', likes: 3),
];

class _CommentsSheet extends StatelessWidget {
  const _CommentsSheet();

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.72;
    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      decoration: const BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
              alignment: Alignment.center,
              color: Colors.transparent,
              child: Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD8D2C8),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 10),
            child: Row(
              children: [
                Text('Comments', style: CkType.display(fontSize: 18)),
                const SizedBox(width: 8),
                Text('· 23',
                    style: CkType.mono(fontSize: 10, fontWeight: FontWeight.w600)),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: V2Svg(V2Icons.close, size: 20, color: CkColors.muted, strokeWidth: 2),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              children: [
                for (final c in _comments) _CommentRow(c: c),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 14, 0, 8),
                  child: Center(
                    child: Text('17 MORE',
                        style: CkType.mono(fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
          _composer(),
        ],
      ),
    );
  }

  Widget _composer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
      decoration: const BoxDecoration(
        color: CkColors.paper,
        border: Border(top: BorderSide(color: CkColors.hairline)),
      ),
      child: Row(
        children: [
          const Avatar(mono: 'BA', size: 28, tone: AvatarTone.ink),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: CkColors.paper,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: CkColors.hairline),
              ),
              child: Text('Add a comment…',
                  style: CkType.body(fontSize: 13, color: CkColors.soft)),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
                color: CkColors.ink, shape: BoxShape.circle),
            child: const V2Svg(V2Icons.share,
                size: 14, color: CkColors.paper, strokeWidth: 2.4),
          ),
        ],
      ),
    );
  }
}

class _CommentRow extends StatelessWidget {
  const _CommentRow({required this.c});
  final _Comment c;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(c.indent ? 46 : 18, 10, 18, 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: CkColors.hairline)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Avatar(mono: c.mono, size: 28, tone: c.me ? AvatarTone.ink : AvatarTone.paper),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: CkType.body(fontSize: 12.5, height: 1.4, color: CkColors.ink),
                    children: [
                      TextSpan(
                          text: c.name,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (c.me)
                        TextSpan(
                            text: '  YOU',
                            style: CkType.mono(
                                fontSize: 8, fontWeight: FontWeight.w700)),
                      TextSpan(
                          text: '  ${c.body}',
                          style: CkType.body(fontSize: 12.5, color: CkColors.ink2)),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(c.t, style: CkType.body(fontSize: 10.5, color: CkColors.muted)),
                    if (c.likes != null) ...[
                      const SizedBox(width: 14),
                      Text('${c.likes} likes',
                          style: CkType.body(fontSize: 10.5, color: CkColors.muted)),
                    ],
                    const SizedBox(width: 14),
                    Text('Reply', style: CkType.body(fontSize: 10.5, color: CkColors.muted)),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(2),
            child: Text('♡', style: CkType.body(fontSize: 14, color: CkColors.muted)),
          ),
        ],
      ),
    );
  }
}

/// Team Page — opened by tapping a team crest in the feed (a faithful stub:
/// header + Posts/Squad/Matches/About tabs + next-match / last-result /
/// recruitment cards).
class TeamPage extends StatelessWidget {
  const TeamPage({super.key, required this.team});
  final TeamMeta team;

  @override
  Widget build(BuildContext context) {
    final color = team.color;
    return Scaffold(
      backgroundColor: CkColors.paper,
      body: Column(
        children: [
          Container(
            color: color,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: V2Svg(V2Icons.chevronLeft, size: 22, color: CkColors.paper, strokeWidth: 2),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(team.mono,
                            style: CkType.display(fontSize: 24, fontWeight: FontWeight.w800, color: CkColors.paper)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(team.name,
                                style: CkType.display(fontSize: 24, height: 1.1, color: CkColors.paper)),
                            const SizedBox(height: 6),
                            Text('14 ACTIVE · 142 MATCHES · EST. 2024',
                                style: CkType.mono(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.white).copyWith(letterSpacing: 0.9)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        flex: 14,
                        child: _hdrBtn('Follow', bg: CkColors.paper, fg: CkColors.ink, w: FontWeight.w700),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 10,
                        child: _hdrBtn('Message', bg: Colors.transparent, fg: CkColors.paper, w: FontWeight.w600, border: true),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: CkColors.hairline)),
            ),
            child: Row(
              children: [
                _tab('POSTS', active: true),
                const SizedBox(width: 14),
                _tab('SQUAD'),
                const SizedBox(width: 14),
                _tab('MATCHES'),
                const SizedBox(width: 14),
                _tab('ABOUT'),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
              children: [
                _infoCard(
                  label: 'NEXT MATCH',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('vs Karachi Eagles', style: CkType.display(fontSize: 15)),
                      const SizedBox(height: 4),
                      Text('Fri 30 May · 6 PM · Model Town',
                          style: CkType.body(fontSize: 12, color: CkColors.muted)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _infoCard(
                  label: 'LAST RESULT',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Crest(short: team.mono, color: color, size: 22, radius: 5),
                          const SizedBox(width: 10),
                          Text('142/6', style: CkType.mono(fontSize: 12, fontWeight: FontWeight.w700, color: CkColors.ink)),
                          const Spacer(),
                          Text('119/9', style: CkType.mono(fontSize: 12, fontWeight: FontWeight.w700, color: CkColors.muted)),
                          const SizedBox(width: 10),
                          const Crest(short: 'KC', color: Color(0xFF2E3E63), size: 22, radius: 5),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: CkColors.redSoft,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text('Won by 23 runs',
                            style: CkType.body(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF8C2218))),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _infoCard(
                  label: 'RECRUITMENT',
                  surface: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Right-arm fast bowler needed',
                          style: CkType.display(fontSize: 14, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text('Ages 18-28 · tape ball · apply by Wed',
                          style: CkType.body(fontSize: 12, color: CkColors.muted)),
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

  Widget _hdrBtn(String label, {required Color bg, required Color fg, required FontWeight w, bool border = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: border ? Border.all(color: Colors.white.withValues(alpha: 0.4)) : null,
      ),
      child: Text(label, style: CkType.body(fontSize: 13, fontWeight: w, color: fg)),
    );
  }

  Widget _tab(String label, {bool active = false}) {
    return Container(
      padding: const EdgeInsets.only(bottom: 10),
      decoration: active
          ? const BoxDecoration(
              border: Border(bottom: BorderSide(color: CkColors.ink, width: 2)))
          : null,
      child: Text(label,
          style: CkType.mono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: active ? CkColors.ink : CkColors.muted)),
    );
  }

  Widget _infoCard({required String label, required Widget child, bool surface = false}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: surface ? CkColors.surface : CkColors.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: CkType.mono(fontSize: 9, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
