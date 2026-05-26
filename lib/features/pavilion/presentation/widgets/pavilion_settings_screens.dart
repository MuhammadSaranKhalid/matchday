// Faithful Flutter ports of three Pavilion settings drill-down screens from the
// design (design_bundle/matchday/project/app/screens/Pavilion.jsx):
//   PvSettingsNotifications  (~1555)
//   PvSettingsDiscoverability(~1628)
//   PvSettingsPrivacy        (~1666)
//
// Presentation-only, mock-data chrome. BODY-ONLY: the Pavilion shell renders the
// back/title header; these widgets return only the scrollable body. Toggles flip
// local StatefulWidget state — no Riverpod, no backend, buttons are inert.
import 'package:flutter/material.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/v2/v2_kit.dart';
import 'pv_kit.dart';

// ─────────────────────────────────────────────────────────
// Notifications & alerts
// ─────────────────────────────────────────────────────────

/// A single toggle definition (state key, label, optional sub copy).
class _NotifToggle {
  const _NotifToggle(this.key, this.label, [this.sub]);
  final String key;
  final String label;
  final String? sub;
}

/// A titled group of toggle rows.
class _NotifGroup {
  const _NotifGroup(this.title, this.items);
  final String title;
  final List<_NotifToggle> items;
}

class PvSettingsNotificationsBody extends StatefulWidget {
  const PvSettingsNotificationsBody({super.key});

  @override
  State<PvSettingsNotificationsBody> createState() =>
      _PvSettingsNotificationsBodyState();
}

class _PvSettingsNotificationsBodyState
    extends State<PvSettingsNotificationsBody> {
  // Defaults mirror the JSX React.useState seed.
  final Map<String, bool> _vals = {
    'matchStart': true,
    'matchResult': true,
    'milestoneMine': false,
    'milestoneFollowed': true,
    'mention': true,
    'follow': false,
    'reply': true,
    'invites': true,
    'claimUpdates': true,
    'captain': true,
    'organizer': true,
    'quietHours': true,
    'matchNearMe': false,
  };

  static const List<_NotifGroup> _groups = [
    _NotifGroup('Match', [
      _NotifToggle('matchStart', 'Match starting', 'Followed teams · 30 min before'),
      _NotifToggle('matchResult', 'Match results', 'Followed teams + tournaments'),
      _NotifToggle('matchNearMe', 'Match near you (v1.1)', '50 km · live now'),
    ]),
    _NotifGroup('Milestones', [
      _NotifToggle('milestoneMine', 'Milestones about me',
          'Auto-post 50/100/5-fer to your feed'),
      _NotifToggle('milestoneFollowed', 'Milestones · followed',
          '50 · 100 · hat-tricks · championship'),
    ]),
    _NotifGroup('Social', [
      _NotifToggle('mention', 'Mentions in posts'),
      _NotifToggle('follow', 'New followers'),
      _NotifToggle('reply', 'Replies to your posts'),
    ]),
    _NotifGroup('Roles & duties', [
      _NotifToggle('invites', 'Invites & requests',
          'Team · tournament · scorer · co-manager'),
      _NotifToggle('claimUpdates', 'Claim updates',
          'Approval · rejection · stat migration'),
      _NotifToggle('captain', 'Captain alerts',
          'XI deadlines · join requests · claims'),
      _NotifToggle('organizer', 'Organizer alerts',
          'Registrations · payments · scorer pool'),
    ]),
  ];

  void _set(String key, bool v) => setState(() => _vals[key] = v);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      children: [
        for (final g in _groups) ..._group(g),
        const PvSectionH('Quiet hours'),
        _quietHours(),
      ],
    );
  }

  List<Widget> _group(_NotifGroup g) {
    return [
      PvSectionH(g.title),
      // background: paper, margin: 0 18px, hairline border, radius 10.
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 18),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: CkColors.paper,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: CkColors.hairline),
        ),
        child: Column(
          children: [
            for (var i = 0; i < g.items.length; i++)
              _toggleRow(g.items[i], isLast: i == g.items.length - 1),
          ],
        ),
      ),
    ];
  }

  Widget _toggleRow(_NotifToggle t, {required bool isLast}) {
    return Container(
      // padding: '12px 4px'
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: CkColors.hairline)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(t.label,
                    style: CkType.body(
                        fontSize: 13, fontWeight: FontWeight.w600, height: 1.25)),
                if (t.sub != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(t.sub!,
                        style: CkType.body(fontSize: 11, color: CkColors.muted)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          PvSwitch(on: _vals[t.key]!, onChange: (v) => _set(t.key, v)),
        ],
      ),
    );
  }

  Widget _quietHours() {
    final on = _vals['quietHours']!;
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 24),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Mute push during sleep',
                    style: CkType.body(
                        fontSize: 13, fontWeight: FontWeight.w600, height: 1.25)),
              ),
              const SizedBox(width: 12),
              PvSwitch(on: on, onChange: (v) => _set('quietHours', v)),
            ],
          ),
          if (on) ...[
            const SizedBox(height: 10),
            const Row(
              children: [
                Expanded(child: _TimeTile(label: 'From', value: '22:00')),
                SizedBox(width: 8),
                Expanded(child: _TimeTile(label: 'To', value: '07:00')),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Inert From/To time tile (paper2 surface, mono label + display value).
class _TimeTile extends StatelessWidget {
  const _TimeTile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: CkColors.paper2,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label.toUpperCase(), style: pvMonoLabel()),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(value, style: pvDisplay(18)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Discoverability
// ─────────────────────────────────────────────────────────

class _DiscFlag {
  const _DiscFlag(this.key, this.label, this.sub);
  final String key;
  final String label;
  final String sub;
}

class PvSettingsDiscoverabilityBody extends StatefulWidget {
  const PvSettingsDiscoverabilityBody({super.key});

  @override
  State<PvSettingsDiscoverabilityBody> createState() =>
      _PvSettingsDiscoverabilityBodyState();
}

class _PvSettingsDiscoverabilityBodyState
    extends State<PvSettingsDiscoverabilityBody> {
  final Map<String, bool> _vals = {
    'appearInSearch': true,
    'suggestToOthers': true,
    'showLocation': true,
    'contactByCaptains': true,
  };

  static const List<_DiscFlag> _flags = [
    _DiscFlag('appearInSearch', 'Appear in search results',
        'Anyone can find you by name / handle'),
    _DiscFlag('suggestToOthers', 'Suggest me to others',
        'Surface in "you may know" + onboarding'),
    _DiscFlag('showLocation', 'Show my city on profile',
        'Karachi · used for nearby tournaments'),
    _DiscFlag('contactByCaptains', 'Captains can invite me to teams',
        'Off = teams must be requested by you'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      // JSX wrapper padding: '14px 18px'
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      children: [
        // One card, hairline border, radius 12, clipped rows.
        Container(
          decoration: BoxDecoration(
            color: CkColors.paper,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CkColors.hairline),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < _flags.length; i++)
                _flagRow(_flags[i], isLast: i == _flags.length - 1),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _noteBox(),
      ],
    );
  }

  Widget _flagRow(_DiscFlag f, {required bool isLast}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: CkColors.hairline)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(f.label,
                    style: CkType.body(
                        fontSize: 14, fontWeight: FontWeight.w600, height: 1.25)),
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(f.sub,
                      style: CkType.body(fontSize: 12, color: CkColors.muted)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          PvSwitch(
            on: _vals[f.key]!,
            onChange: (v) => setState(() => _vals[f.key] = v),
          ),
        ],
      ),
    );
  }

  Widget _noteBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CkColors.paper2,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const PvPill('Note'),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: CkType.body(
                  fontSize: 12, color: CkColors.ink2, height: 1.5),
              children: const [
                TextSpan(text: 'Discoverability is independent of '),
                TextSpan(
                    text: 'following',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                TextSpan(
                    text: ". Turning everything off doesn't hide your stats from "
                        "people who already follow you — they just can't find you "
                        'again.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Privacy & blocking
// ─────────────────────────────────────────────────────────

class _PersonRow {
  const _PersonRow(this.name, this.sub, this.action, {this.blocked = false});
  final String name;
  final String sub;
  final String action;
  final bool blocked;
}

class _ReportRow {
  const _ReportRow(this.title, this.sub, this.accent);
  final String title;
  final String sub;
  final Color? accent; // null = default hairline left border.
}

class PvSettingsPrivacyBody extends StatelessWidget {
  const PvSettingsPrivacyBody({super.key});

  static const List<_PersonRow> _muted = [
    _PersonRow('Random Spammer', 'muted 2 weeks ago', 'Unmute'),
    _PersonRow('Old Rivalry', 'muted 1 month', 'Unmute'),
  ];

  static const _PersonRow _blocked = _PersonRow(
    'Blocked X.',
    'blocked 3 months ago · cannot see you, message you, or tag you',
    'Unblock',
    blocked: true,
  );

  static const List<_ReportRow> _reports = [
    _ReportRow('Comment by Random S.', 'Reported 3d · under review', CkColors.amber),
    _ReportRow('Post by Spam Acct', 'Reported 1w · removed by admin', CkColors.green),
    _ReportRow('Profile by Fake Acct', 'Reported 2w · no action taken', null),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 20),
      children: [
        const PvSectionH('Muted', count: 2),
        _gridSection([for (final u in _muted) _personRow(u)]),
        const PvSectionH('Blocked', count: 1),
        _gridSection([_personRow(_blocked)]),
        const PvSectionH('Report receipts', count: 3),
        _gridSection([for (final r in _reports) _reportRow(r)]),
      ],
    );
  }

  /// padding: '0 18px', display: grid, gap: 6.
  Widget _gridSection(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 6),
            children[i],
          ],
        ],
      ),
    );
  }

  String _initials(String name) =>
      name.split(' ').where((s) => s.isNotEmpty).map((s) => s[0]).join();

  Widget _personRow(_PersonRow u) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Row(
        children: [
          if (u.blocked)
            // Blocked avatar: red fill, paper text, no border.
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: CkColors.red,
                shape: BoxShape.circle,
              ),
              child: Text(_initials(u.name),
                  style: CkType.display(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: CkColors.paper)),
            )
          else
            Avatar(mono: _initials(u.name), size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(u.name,
                    style: CkType.body(
                        fontSize: 13, fontWeight: FontWeight.w600, height: 1.25)),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(u.sub,
                      style: CkType.body(fontSize: 11, color: CkColors.muted)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _pillButton(u.action),
        ],
      ),
    );
  }

  /// Inert Unmute/Unblock button: paper, hairline border, radius 6.
  Widget _pillButton(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Text(label,
          style: CkType.body(
              fontSize: 11, fontWeight: FontWeight.w600, color: CkColors.ink)),
    );
  }

  Widget _reportRow(_ReportRow r) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: CkColors.paper,
          border: Border(
            top: const BorderSide(color: CkColors.hairline),
            right: const BorderSide(color: CkColors.hairline),
            bottom: const BorderSide(color: CkColors.hairline),
            left: BorderSide(color: r.accent ?? CkColors.hairline, width: 3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(r.title,
                style: CkType.body(
                    fontSize: 13, fontWeight: FontWeight.w600, height: 1.25)),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(r.sub,
                  style: CkType.body(fontSize: 11, color: CkColors.muted)),
            ),
          ],
        ),
      ),
    );
  }
}
