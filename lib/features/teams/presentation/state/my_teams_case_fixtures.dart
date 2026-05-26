// Faithful Flutter port of the JSX `CASES` map in
// `design/screens/MyTeams.jsx`. Each entry produces a [MyTeamsView] that the
// cases gallery feeds straight to `MyTeamsBody`. Presentation-only mocks —
// nothing here talks to providers.
import '../widgets/my_teams/crest_palette.dart';
import 'my_teams_view.dart';

/// The 12 named cases from the design source. Order mirrors the JSX
/// artboards.
enum MyTeamsCase {
  empty,
  firstTeam,
  activePlayer,
  captainNeedsYou,
  withInvites,
  todayLive,
  manager,
  powerUser,
  followingOnly,
  withArchived,
  pendingRequest,
}

/// Short human-readable labels for the cases gallery.
extension MyTeamsCaseInfo on MyTeamsCase {
  String get title {
    switch (this) {
      case MyTeamsCase.empty:
        return 'Empty';
      case MyTeamsCase.firstTeam:
        return 'First team';
      case MyTeamsCase.activePlayer:
        return 'Active player';
      case MyTeamsCase.captainNeedsYou:
        return 'Captain needs you';
      case MyTeamsCase.withInvites:
        return 'Invites';
      case MyTeamsCase.todayLive:
        return 'Today / live';
      case MyTeamsCase.manager:
        return 'Manager';
      case MyTeamsCase.powerUser:
        return 'Power user';
      case MyTeamsCase.followingOnly:
        return 'Following only';
      case MyTeamsCase.withArchived:
        return 'Archived';
      case MyTeamsCase.pendingRequest:
        return 'Awaiting approval';
    }
  }

  String get caseId {
    switch (this) {
      case MyTeamsCase.empty:
        return 'CASE 01';
      case MyTeamsCase.firstTeam:
        return 'CASE 02';
      case MyTeamsCase.activePlayer:
        return 'CASE 03';
      case MyTeamsCase.captainNeedsYou:
        return 'CASE 04';
      case MyTeamsCase.withInvites:
        return 'CASE 05';
      case MyTeamsCase.todayLive:
        return 'CASE 06';
      case MyTeamsCase.manager:
        return 'CASE 07';
      case MyTeamsCase.powerUser:
        return 'CASE 08';
      case MyTeamsCase.followingOnly:
        return 'CASE 09';
      case MyTeamsCase.withArchived:
        return 'CASE 10';
      case MyTeamsCase.pendingRequest:
        return 'CASE 11';
    }
  }
}

/// All 12 fixtures, keyed by the [MyTeamsCase] enum. The JSX `CASES` object
/// is reproduced here field-for-field; section content shapes are explained
/// in `my_teams_view.dart`.
final Map<MyTeamsCase, MyTeamsView> kMyTeamsCaseFixtures = {
  // ─── 01 — Empty / new user ────────────────────────────────────────────
  MyTeamsCase.empty: const MyTeamsView(
    subtitle: 'No teams yet · pick a starting point',
    isEmpty: true,
    suggested: [
      SuggestedTeam(
          crest: MyTeamsCrests.mk,
          meta: 'Karachi · Korangi · 12 players'),
      SuggestedTeam(
          crest: MyTeamsCrests.gg,
          meta: 'Lahore · Gulberg · 8 players · tape ball'),
      SuggestedTeam(
          crest: MyTeamsCrests.rs,
          meta: 'Rawalpindi · 14 players · hard ball'),
    ],
  ),

  // ─── 02 — First team just created ─────────────────────────────────────
  MyTeamsCase.firstTeam: const MyTeamsView(
    subtitle: '1 team · onboarding',
    needsYou: [
      NeedsYouItem(
        role: MyTeamsRole.captain,
        tone: NeedsYouTone.amber,
        subTag: 'LAHORE LIONS',
        title: 'Add players to your roster',
        body:
            'You created this team 4 minutes ago. Invite at least 6 players to start scoring matches.',
        actions: [NeedsYouAction('Add players'), NeedsYouAction('Later')],
      ),
    ],
    teams: TeamGroups(
      captain: [
        TeamRowVm(
          crest: MyTeamsCrests.ll,
          role: MyTeamsRole.captain,
          meta: 'You · 1 player · just created',
        ),
      ],
    ),
  ),

  // ─── 03 — Active player, three teams ──────────────────────────────────
  MyTeamsCase.activePlayer: const MyTeamsView(
    subtitle: '3 teams · playing for 3 sides',
    teams: TeamGroups(
      vc: [
        TeamRowVm(
          crest: MyTeamsCrests.ll,
          role: MyTeamsRole.vc,
          jersey: 7,
          meta: 'Spring Cup QF · today 4 PM',
          verified: true,
        ),
      ],
      playing: [
        TeamRowVm(
          crest: MyTeamsCrests.ke,
          role: MyTeamsRole.player,
          jersey: 22,
          meta: 'Sunday League · next Sat',
          verified: true,
        ),
        TeamRowVm(
          crest: MyTeamsCrests.mk,
          role: MyTeamsRole.player,
          jersey: 11,
          meta: 'Mohalla cricket · weekends',
        ),
      ],
    ),
  ),

  // ─── 04 — Captain with pending decisions ──────────────────────────────
  MyTeamsCase.captainNeedsYou: const MyTeamsView(
    subtitle: 'Captain · 1 team · 3 decisions',
    needsYou: [
      NeedsYouItem(
        role: MyTeamsRole.captain,
        tone: NeedsYouTone.red,
        subTag: 'LAHORE LIONS · 3 ACTIONS',
        title: "Pick the XI for tonight's QF",
        body: '1 join request · 2 claim approvals · XI not picked',
        actions: [NeedsYouAction('Open captain inbox')],
      ),
    ],
    teams: TeamGroups(
      captain: [
        TeamRowVm(
          crest: MyTeamsCrests.ll,
          role: MyTeamsRole.captain,
          jersey: 7,
          meta: 'Spring Cup QF · today 6:30 PM',
          verified: true,
          notifCount: 3,
        ),
      ],
      playing: [
        TeamRowVm(
          crest: MyTeamsCrests.ke,
          role: MyTeamsRole.player,
          jersey: 22,
          meta: 'Sunday League · 4 days',
          verified: true,
        ),
      ],
    ),
  ),

  // ─── 05 — Pending invites at top ──────────────────────────────────────
  MyTeamsCase.withInvites: const MyTeamsView(
    subtitle: '2 invites · 2 teams',
    invites: [
      InviteEntry(
        crest: MyTeamsCrests.dh,
        fromName: 'Asad Qureshi',
        role: 'Player · top-order',
      ),
      InviteEntry(
        crest: MyTeamsCrests.mq,
        fromName: 'Tariq Hussain',
        role: 'Player · any role',
      ),
    ],
    teams: TeamGroups(
      captain: [
        TeamRowVm(
          crest: MyTeamsCrests.ll,
          role: MyTeamsRole.captain,
          jersey: 7,
          meta: 'Spring Cup QF · today 6:30 PM',
          verified: true,
        ),
      ],
      playing: [
        TeamRowVm(
          crest: MyTeamsCrests.ke,
          role: MyTeamsRole.player,
          jersey: 22,
          meta: 'Sunday League · 4 days',
          verified: true,
        ),
      ],
    ),
  ),

  // ─── 06 — Today, live match ───────────────────────────────────────────
  MyTeamsCase.todayLive: const MyTeamsView(
    subtitle: 'Live · 1 match · 3 teams',
    today: TodayMatch(
      a: MyTeamsCrests.ll,
      b: MyTeamsCrests.kc,
      live: true,
      aScore: '142/6 (20)',
      bScore: '119/9 (19.2)',
      ctx: 'SPRING CUP · QF 2',
      role: 'You · #7',
      note: 'Cobras need 24 from 12 balls',
      venue: 'GADDAFI B',
    ),
    teams: TeamGroups(
      captain: [
        TeamRowVm(
          crest: MyTeamsCrests.ll,
          role: MyTeamsRole.vc,
          jersey: 7,
          meta: 'Spring Cup QF · LIVE NOW',
          verified: true,
          live: true,
        ),
      ],
      playing: [
        TeamRowVm(
          crest: MyTeamsCrests.ke,
          role: MyTeamsRole.player,
          jersey: 22,
          meta: 'Next: Sat 25 May · 4 PM',
          verified: true,
        ),
        TeamRowVm(
          crest: MyTeamsCrests.mk,
          role: MyTeamsRole.player,
          jersey: 11,
          meta: 'No fixtures · pick-up cricket',
        ),
      ],
    ),
  ),

  // ─── 07 — Manager / owner of multiple teams ───────────────────────────
  MyTeamsCase.manager: const MyTeamsView(
    subtitle: 'Manager · 2 teams · 1 draft',
    needsYou: [
      NeedsYouItem(
        role: MyTeamsRole.manager,
        tone: NeedsYouTone.amber,
        subTag: 'KARACHI EAGLES · 2 ACTIONS',
        title: 'Approve 2 join requests',
        body:
            'Imran S. · top-order · Karachi · Korangi  •  Faraz K. · keeper',
        actions: [NeedsYouAction('Review')],
      ),
    ],
    teams: TeamGroups(
      captain: [
        TeamRowVm(
          crest: MyTeamsCrests.ll,
          role: MyTeamsRole.owner,
          jersey: 7,
          meta: 'Spring Cup QF · today 6:30 PM',
          verified: true,
        ),
        TeamRowVm(
          crest: MyTeamsCrests.ke,
          role: MyTeamsRole.manager,
          jersey: 22,
          meta: '14 players · Sunday League',
          verified: true,
          notifCount: 2,
        ),
      ],
      draft: [
        TeamRowVm(
          crest: MyTeamsCrests.it,
          role: MyTeamsRole.draft,
          meta: 'Created · not published · 2 players added',
        ),
      ],
    ),
  ),

  // ─── 08 — Multi-role power user, dense ────────────────────────────────
  MyTeamsCase.powerUser: const MyTeamsView(
    subtitle: '6 teams · 1 live · 2 following',
    today: TodayMatch(
      a: MyTeamsCrests.ll,
      b: MyTeamsCrests.kc,
      live: true,
      aScore: '142/6 (20)',
      bScore: '119/9 (19.2)',
      ctx: 'SPRING CUP · QF',
      role: '#7 · VC',
      note: 'KC need 24 (12)',
      venue: 'GADDAFI B',
    ),
    teams: TeamGroups(
      captain: [
        TeamRowVm(
          crest: MyTeamsCrests.ll,
          role: MyTeamsRole.vc,
          jersey: 7,
          meta: 'Spring Cup QF · LIVE',
          verified: true,
          live: true,
        ),
      ],
      playing: [
        TeamRowVm(
          crest: MyTeamsCrests.ke,
          role: MyTeamsRole.player,
          jersey: 22,
          meta: 'Next: Sat 25 · 4 PM',
          verified: true,
        ),
        TeamRowVm(
          crest: MyTeamsCrests.mk,
          role: MyTeamsRole.player,
          jersey: 11,
          meta: 'Mohalla cricket · weekends',
        ),
        TeamRowVm(
          crest: MyTeamsCrests.ob,
          role: MyTeamsRole.player,
          jersey: 4,
          meta: 'Friendly side · 1 match/mo',
        ),
      ],
      manage: [
        TeamRowVm(
          crest: MyTeamsCrests.it,
          role: MyTeamsRole.manager,
          meta: '9 players · friendly only',
        ),
      ],
      scorer: [
        TeamRowVm(
          crest: MyTeamsCrests.sc,
          role: MyTeamsRole.scorer,
          meta: 'Spring Cup · 4 matches scored',
        ),
      ],
    ),
    following: [
      TeamRowVm(
        crest: MyTeamsCrests.gg,
        role: MyTeamsRole.following,
        meta: 'Lahore · Gulberg · 5 in your network',
      ),
      TeamRowVm(
        crest: MyTeamsCrests.pr,
        role: MyTeamsRole.following,
        meta: 'Karachi · Faisal · 2 in your network',
      ),
    ],
  ),

  // ─── 09 — Following only (spectator) ──────────────────────────────────
  MyTeamsCase.followingOnly: const MyTeamsView(
    subtitle: 'No teams playing · 5 following',
    following: [
      TeamRowVm(
        crest: MyTeamsCrests.ll,
        role: MyTeamsRole.following,
        meta: 'Spring Cup QF · today 4 PM',
        live: true,
      ),
      TeamRowVm(
        crest: MyTeamsCrests.ke,
        role: MyTeamsRole.following,
        meta: 'Sunday League · next: Sat 25 May',
      ),
      TeamRowVm(
        crest: MyTeamsCrests.gg,
        role: MyTeamsRole.following,
        meta: 'Lahore · Gulberg · 142 matches',
      ),
      TeamRowVm(
        crest: MyTeamsCrests.mk,
        role: MyTeamsRole.following,
        meta: 'Karachi · Korangi · mohalla',
      ),
      TeamRowVm(
        crest: MyTeamsCrests.pr,
        role: MyTeamsRole.following,
        meta: 'Karachi · Faisal · 8 in network',
      ),
    ],
    suggested: [
      SuggestedTeam(
        crest: MyTeamsCrests.rs,
        meta: 'Rawalpindi · 12 in your network',
      ),
      SuggestedTeam(
        crest: MyTeamsCrests.ob,
        meta: 'Lahore · Cantt · 5 in network',
      ),
    ],
    suggestedTitle: 'Suggested · captains you follow',
    showCreateNudge: true,
  ),

  // ─── 10 — Archived teams ──────────────────────────────────────────────
  MyTeamsCase.withArchived: const MyTeamsView(
    subtitle: '2 teams · 2 archived',
    teams: TeamGroups(
      captain: [
        TeamRowVm(
          crest: MyTeamsCrests.ll,
          role: MyTeamsRole.captain,
          jersey: 7,
          meta: 'Spring Cup QF · today',
          verified: true,
        ),
      ],
      playing: [
        TeamRowVm(
          crest: MyTeamsCrests.ke,
          role: MyTeamsRole.player,
          jersey: 22,
          meta: 'Sunday League · 4 days',
          verified: true,
        ),
      ],
      archived: [
        TeamRowVm(
          crest: MyTeamsCrests.kh,
          role: MyTeamsRole.archived,
          meta: 'Disbanded May 2024 · 22 matches',
        ),
        TeamRowVm(
          crest: MyTeamsCrests.rs,
          role: MyTeamsRole.archived,
          meta: 'Left team · Mar 2024 · 8 matches',
        ),
      ],
    ),
  ),

  // ─── 11 — Pending join request sent ───────────────────────────────────
  MyTeamsCase.pendingRequest: const MyTeamsView(
    subtitle: '1 team · 1 awaiting',
    needsYou: [
      NeedsYouItem(
        role: MyTeamsRole.pending,
        tone: NeedsYouTone.amber,
        subTag: 'KARACHI EAGLES',
        title: 'Awaiting captain approval',
        body:
            'You requested to join 2 days ago. Asad Q. typically responds within 4 days.',
        actions: [NeedsYouAction('Withdraw request'), NeedsYouAction('Message captain')],
      ),
    ],
    teams: TeamGroups(
      playing: [
        TeamRowVm(
          crest: MyTeamsCrests.ll,
          role: MyTeamsRole.player,
          jersey: 7,
          meta: 'Spring Cup QF · today 6:30 PM',
          verified: true,
        ),
      ],
      pending: [
        TeamRowVm(
          crest: MyTeamsCrests.ke,
          role: MyTeamsRole.pending,
          meta: 'Requested 2 days ago · Asad Q. captains',
        ),
      ],
    ),
  ),
};
