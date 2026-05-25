// Faithful Flutter port of the matchday v2 prototype's `V2Messages` screen
// (screens/v2-IA.jsx). Presentation-only, mock data, inert affordances — the
// shell owns the bottom nav so it is intentionally not rendered here.
import 'package:flutter/material.dart';

import 'package:novex_clean_arch/core/theme/circk_theme.dart';
import 'package:novex_clean_arch/core/widgets/v2/v2_kit.dart';

import 'message_thread_screen.dart';

/// A single ThreadRow's preview line is a sequence of styled spans so the
/// JSX's bold sender prefix (`<b>Imran:</b> …`) reproduces 1:1.
class _PreviewSpan {
  const _PreviewSpan(this.text, {this.bold = false});
  final String text;
  final bool bold;
}

class _Thread {
  const _Thread({
    required this.mono,
    required this.name,
    required this.preview,
    required this.time,
    this.unread = 0,
    this.read = false,
    this.pinned = false,
    this.system = false,
    this.team = false,
    this.color,
  });

  final String mono;
  final String name;
  final List<_PreviewSpan> preview;
  final String time;
  final int unread;
  final bool read;
  final bool pinned;
  final bool system;
  final bool team;
  final Color? color;
}

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key, this.onBell});

  final VoidCallback? onBell;

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  String _tab = 'all';

  static const List<_Thread> _threads = [
    _Thread(
      mono: 'LL',
      team: true,
      color: CkCrest.ll,
      name: 'Lahore Lions',
      preview: [
        _PreviewSpan('Imran:', bold: true),
        _PreviewSpan(' XI confirmed for tomorrow. Faraz at 3.'),
      ],
      time: 'now',
      unread: 5,
    ),
    _Thread(
      mono: 'QF',
      team: true,
      color: CkCrest.sc,
      name: 'QF · Lions vs Cobras',
      preview: [
        _PreviewSpan('Scorer:', bold: true),
        _PreviewSpan(' Toss done. Lions chose to bowl.'),
      ],
      time: '2h',
      unread: 1,
      pinned: true,
    ),
    _Thread(
      mono: 'BA',
      name: 'Bilal Ahmed',
      preview: [_PreviewSpan('Are we still on for nets Wednesday?')],
      time: 'Yesterday',
    ),
    _Thread(
      mono: 'IS',
      name: 'Imran Saeed',
      preview: [
        _PreviewSpan('You:', bold: true),
        _PreviewSpan(" Yeah I'll be there by 7"),
      ],
      time: '2d',
      read: true,
    ),
    _Thread(
      mono: 'KE',
      team: true,
      color: CkCrest.ke,
      name: 'Karachi Eagles · Roster',
      preview: [_PreviewSpan('Faisal joined the team')],
      time: '3d',
      system: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: CkColors.paper,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            V2Header(
              title: 'Messages',
              sub: '3 active · 2 unread',
              notifCount: 3,
              onBell: widget.onBell,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
              child: Row(
                children: [
                  _MTab(
                    label: 'All',
                    count: 3,
                    active: _tab == 'all',
                    onTap: () => setState(() => _tab = 'all'),
                  ),
                  const SizedBox(width: 6),
                  _MTab(
                    label: 'Teams',
                    count: 2,
                    active: _tab == 'teams',
                    onTap: () => setState(() => _tab = 'teams'),
                  ),
                  const SizedBox(width: 6),
                  _MTab(
                    label: 'DMs',
                    count: 1,
                    active: _tab == 'dms',
                    onTap: () => setState(() => _tab = 'dms'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: _threads.length,
                itemBuilder: (context, i) => _ThreadRow(
                  thread: _threads[i],
                  onOpen: () => Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const MessageThreadScreen(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// JBMono 9.5 / 700 / 0.10em filter tab. Active = ink bg / paper fg; inactive =
/// paper bg / ink2 fg + 1px hairline border. Renders "LABEL · count".
class _MTab extends StatelessWidget {
  const _MTab({
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = active ? CkColors.paper : CkColors.ink2;
    final base = CkType.mono(
      fontSize: 9.5,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.10,
      color: fg,
    );
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? CkColors.ink : CkColors.paper,
          borderRadius: BorderRadius.circular(999),
          border: active ? null : Border.all(color: CkColors.hairline),
        ),
        child: Text.rich(
          TextSpan(
            style: base,
            children: [
              TextSpan(text: label.toUpperCase()),
              TextSpan(
                text: ' · $count',
                style: base.copyWith(
                  fontWeight: FontWeight.w500,
                  color: fg.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThreadRow extends StatelessWidget {
  const _ThreadRow({required this.thread, required this.onOpen});

  final _Thread thread;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final t = thread;
    final unread = t.unread > 0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: const BoxDecoration(
          color: CkColors.paper,
          border: Border(top: BorderSide(color: CkColors.hairline)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (t.team)
              Crest(short: t.mono, color: t.color!, size: 42, radius: 11)
            else
              Avatar(mono: t.mono, size: 42, tone: AvatarTone.ink),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: Text(
                          t.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CkType.display(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.01,
                          ),
                        ),
                      ),
                      if (t.pinned) ...[
                        const SizedBox(width: 6),
                        Text(
                          '📌',
                          style: CkType.mono(
                            fontSize: 8,
                            color: CkColors.muted,
                          ),
                        ),
                      ],
                      const Spacer(),
                      const SizedBox(width: 6),
                      Text(
                        t.time,
                        style: CkType.mono(
                          fontSize: 9,
                          color: unread ? CkColors.red : CkColors.muted,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text.rich(
                      _previewSpan(t, unread: unread),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            if (unread) ...[
              const SizedBox(width: 12),
              Container(
                constraints: const BoxConstraints(minWidth: 18),
                height: 18,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: CkColors.red,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${t.unread}',
                  style: CkType.display(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: CkColors.paper,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  TextSpan _previewSpan(_Thread t, {required bool unread}) {
    final base = CkType.body(
      fontSize: 12.5,
      height: 1.4,
      color: unread ? CkColors.ink : CkColors.muted,
      fontWeight: FontWeight.w400,
    ).copyWith(
      fontStyle: t.system ? FontStyle.italic : FontStyle.normal,
    );
    return TextSpan(
      style: base,
      children: [
        for (final span in t.preview)
          TextSpan(
            text: span.text,
            style: span.bold
                ? base.copyWith(fontWeight: FontWeight.w700)
                : null,
          ),
      ],
    );
  }
}
