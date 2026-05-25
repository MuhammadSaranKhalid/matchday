// Faithful Flutter port of the matchday v2 prototype's `V2MessagesThread`
// screen (screens/v2-IA.jsx). Presentation-only, mock conversation, inert
// composer.
import 'package:flutter/material.dart';

import 'package:novex_clean_arch/core/theme/circk_theme.dart';
import 'package:novex_clean_arch/core/widgets/v2/v2_kit.dart';

class MessageThreadScreen extends StatelessWidget {
  const MessageThreadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            _ThreadHeader(onBack: () => Navigator.of(context).pop()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(14),
                children: const [
                  _DayDivider('Today'),
                  SizedBox(height: 10),
                  _Msg(
                    from: 'IS',
                    name: 'Imran Saeed',
                    body: 'XI confirmed for tomorrow. '
                        'Faraz at 3, Bilal opens with me.',
                    time: '9:14 AM',
                  ),
                  SizedBox(height: 10),
                  _Msg(
                    from: 'IS',
                    name: 'Imran Saeed',
                    body: 'Toss at 3:45. Be at the ground by 3:30.',
                    time: '9:14 AM',
                  ),
                  SizedBox(height: 10),
                  _SystemMsg(
                    [
                      _SysSpan('Imran added a match: '),
                      _SysSpan('Lions vs Cobras', bold: true),
                      _SysSpan(' · Sat 25 · 4 PM'),
                    ],
                  ),
                  SizedBox(height: 10),
                  _Msg(
                    from: 'FK',
                    name: 'Faraz Khan',
                    body: 'On it. Bringing two extra balls.',
                    time: '9:31 AM',
                  ),
                  SizedBox(height: 10),
                  _Msg(
                    body: 'Booking the practice net for Wed 7 PM 🏏',
                    time: '11:22 AM',
                    me: true,
                  ),
                  SizedBox(height: 10),
                  _DayDivider('Now'),
                  SizedBox(height: 10),
                  _Msg(
                    from: 'IS',
                    name: 'Imran Saeed',
                    body: 'Anyone got a spare pair of pads for Adeel? '
                        'His are torn.',
                    time: 'just now',
                  ),
                  SizedBox(height: 14),
                  _TypingIndicator(),
                ],
              ),
            ),
            const _Composer(),
          ],
        ),
      ),
    );
  }
}

class _ThreadHeader extends StatelessWidget {
  const _ThreadHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CkColors.hairline)),
      ),
      child: Row(
        children: [
          GestureDetector(
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
          const SizedBox(width: 10),
          const Crest(short: 'LL', color: CkColors.red, size: 32, radius: 8),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Lahore Lions',
                  style: CkType.display(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.01,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Text(
                    '14 members · 4 online',
                    style: CkType.body(fontSize: 11, color: CkColors.muted),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Padding(
            padding: EdgeInsets.all(4),
            child: V2Svg(
              V2Icons.dotsV,
              size: 22,
              color: CkColors.ink,
              filled: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayDivider extends StatelessWidget {
  const _DayDivider(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: SizedBox(height: 1, child: ColoredBox(color: CkColors.hairline)),
        ),
        const SizedBox(width: 10),
        Text(
          label.toUpperCase(),
          style: CkType.mono(fontSize: 9, color: CkColors.muted),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: SizedBox(height: 1, child: ColoredBox(color: CkColors.hairline)),
        ),
      ],
    );
  }
}

class _Msg extends StatelessWidget {
  const _Msg({
    this.from,
    this.name,
    required this.body,
    required this.time,
    this.me = false,
  });

  final String? from;
  final String? name;
  final String body;
  final String time;
  final bool me;

  @override
  Widget build(BuildContext context) {
    if (me) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.78,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: const BoxDecoration(
                      color: CkColors.ink,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(14),
                        topRight: Radius.circular(14),
                        bottomRight: Radius.circular(4),
                        bottomLeft: Radius.circular(14),
                      ),
                    ),
                    child: Text(
                      body,
                      style: CkType.body(
                        fontSize: 13.5,
                        height: 1.4,
                        color: CkColors.paper,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      time,
                      style: CkType.mono(fontSize: 9, color: CkColors.muted),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Avatar(mono: from ?? '', size: 26, tone: AvatarTone.ink),
        const SizedBox(width: 8),
        Flexible(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.78,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (name != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      name!,
                      style: CkType.display(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: CkColors.ink2,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: const BoxDecoration(
                    color: CkColors.paper2,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(14),
                      bottomRight: Radius.circular(14),
                      bottomLeft: Radius.circular(14),
                    ),
                  ),
                  child: Text(
                    body,
                    style: CkType.body(
                      fontSize: 13.5,
                      height: 1.4,
                      color: CkColors.ink,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    time,
                    style: CkType.mono(fontSize: 9, color: CkColors.muted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SysSpan {
  const _SysSpan(this.text, {this.bold = false});
  final String text;
  final bool bold;
}

class _SystemMsg extends StatelessWidget {
  const _SystemMsg(this.spans);

  final List<_SysSpan> spans;

  @override
  Widget build(BuildContext context) {
    final base = CkType.body(
      fontSize: 11,
      height: 1.4,
      color: CkInk.amber, // on cream — oklch(0.42 0.12 80)
    );
    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.85,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: CkColors.cream,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text.rich(
            TextSpan(
              style: base,
              children: [
                for (final s in spans)
                  TextSpan(
                    text: s.text,
                    style: s.bold
                        ? base.copyWith(fontWeight: FontWeight.w700)
                        : null,
                  ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Avatar(mono: 'IS', size: 26, tone: AvatarTone.ink),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: CkColors.paper2,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              3,
              (i) => Padding(
                padding: EdgeInsets.only(right: i == 2 ? 0 : 4),
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: CkColors.muted.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: CkColors.hairline)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: CkColors.paper2,
              shape: BoxShape.circle,
            ),
            child: const V2Svg(
              V2Icons.plus,
              size: 18,
              color: CkColors.ink,
              strokeWidth: 2,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: CkColors.paper,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: CkColors.hairline),
              ),
              child: Text(
                'Message Lahore Lions…',
                style: CkType.body(fontSize: 14, color: CkColors.soft),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: CkColors.ink,
              shape: BoxShape.circle,
            ),
            child: const V2Svg(
              V2Icons.share,
              size: 16,
              color: CkColors.paper,
              strokeWidth: 2.4,
            ),
          ),
        ],
      ),
    );
  }
}
