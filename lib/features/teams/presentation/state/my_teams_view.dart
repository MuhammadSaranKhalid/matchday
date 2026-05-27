// View model for the "My Teams" screen — a faithful port of the JSX
// `CASES.*` shape from design/screens/MyTeams.jsx.
//
// One [MyTeamsView] feeds [MyTeamsBody]. Two construction sites build it:
//   • Real data: [buildMyTeamsViewFromReal] in [my_teams_real_data_adapter.dart]
//   • Static mocks: `kMyTeamsCaseFixtures` in [my_teams_case_fixtures.dart]
//
// Sections render only when their list/value is non-empty (`isEmpty` short-
// circuits everything else), so each case yields a focused screen.
import 'package:flutter/foundation.dart';

import '../widgets/my_teams/crest_palette.dart';

/// A team's relationship to the signed-in user. The render layer uses this
/// to pick the RolePill style (and to short-circuit `PLAYER` to no chip).
enum MyTeamsRole {
  owner,
  captain,
  vc,
  wk,
  manager,
  player,
  following,
  pending,
  archived,
  suspended,
  draft,
  scorer,
}

/// Tone of a NeedsYou banner — drives the left-border accent color.
enum NeedsYouTone { red, amber, ink }

/// Filter chip selection.
enum MyTeamsFilter { all, playing, managing, following, archived }

@immutable
class NeedsYouAction {
  const NeedsYouAction(this.label, {this.onTap});
  final String label;

  /// Null = inert button (rendered but not tappable). Real handlers come
  /// from the adapter when the action has a known destination.
  final VoidCallback? onTap;
}

@immutable
class NeedsYouItem {
  const NeedsYouItem({
    required this.role,
    required this.tone,
    required this.title,
    required this.body,
    this.subTag,
    this.actions = const <NeedsYouAction>[],
  });

  final MyTeamsRole role;
  final NeedsYouTone tone;
  final String title;
  final String body;
  final String? subTag;

  /// Action buttons (first = primary, rest = ghost). Inert by default
  /// unless [NeedsYouAction.onTap] is provided.
  final List<NeedsYouAction> actions;
}

@immutable
class TodayMatch {
  const TodayMatch({
    required this.a,
    required this.b,
    required this.live,
    this.aScore,
    this.bScore,
    this.when,
    this.ctx,
    this.role,
    this.note,
    this.venue,
  });

  final CrestStyle a;
  final CrestStyle b;
  final bool live;
  final String? aScore;
  final String? bScore;

  /// e.g. "today 6:30 PM" — only used when [live] is false.
  final String? when;

  /// Eyebrow context: "SPRING CUP · QF 2".
  final String? ctx;

  /// "You · #7" / "#7 · VC".
  final String? role;

  /// Footer line: "Cobras need 24 from 12 balls".
  final String? note;

  /// Footer right: "GADDAFI B".
  final String? venue;
}

@immutable
class InviteEntry {
  const InviteEntry({
    required this.crest,
    required this.fromName,
    required this.role,
  });

  final CrestStyle crest;
  final String fromName;

  /// Free-text: "Player · top-order".
  final String role;
}

/// Lingua franca row for every team list section (captain/vc/playing/manage/
/// pending/archived/following/draft/scorer). Carries the crest inline so the
/// renderer never has to look up a global table.
@immutable
class TeamRowVm {
  const TeamRowVm({
    required this.crest,
    required this.role,
    this.teamId,
    this.jersey,
    this.meta,
    this.verified = false,
    this.live = false,
    this.notifCount,
  });

  final CrestStyle crest;
  final MyTeamsRole role;

  /// The team's id when this row maps to a real backend record. Null for
  /// fixture rows (cases gallery / static mocks). The screen uses this to
  /// route to `/teams/$teamId` on tap.
  final String? teamId;

  /// Jersey number when the user plays in this team.
  final int? jersey;

  /// Mono-style secondary line: "Spring Cup QF · today 4 PM".
  final String? meta;

  /// Adds a green tick next to the team name.
  final bool verified;

  /// Adds a small inline LIVE pill in the meta line.
  final bool live;

  /// Renders a red count badge over the crest's top-right corner.
  final int? notifCount;
}

@immutable
class TeamGroups {
  const TeamGroups({
    this.captain = const [],
    this.vc = const [],
    this.playing = const [],
    this.manage = const [],
    this.scorer = const [],
    this.draft = const [],
    this.pending = const [],
    this.archived = const [],
  });

  /// Teams the user owns or captains.
  final List<TeamRowVm> captain;

  /// Teams the user is vice-captain of.
  final List<TeamRowVm> vc;

  /// Teams the user plays for (non-captain).
  final List<TeamRowVm> playing;

  /// Teams the user manages off-field.
  final List<TeamRowVm> manage;

  /// Teams the user scores for.
  final List<TeamRowVm> scorer;

  /// Teams the user has created but not published.
  final List<TeamRowVm> draft;

  /// Teams the user has applied to join.
  final List<TeamRowVm> pending;

  /// Disbanded or left teams.
  final List<TeamRowVm> archived;

  bool get isEmpty =>
      captain.isEmpty &&
      vc.isEmpty &&
      playing.isEmpty &&
      manage.isEmpty &&
      scorer.isEmpty &&
      draft.isEmpty &&
      pending.isEmpty &&
      archived.isEmpty;
}

@immutable
class SuggestedTeam {
  const SuggestedTeam({required this.crest, required this.meta});
  final CrestStyle crest;

  /// Mono-style: "Karachi · Korangi · 12 players".
  final String meta;
}

/// The whole screen, in one shape. The renderer reads this and renders
/// each section only when its data is non-empty.
@immutable
class MyTeamsView {
  const MyTeamsView({
    this.subtitle,
    this.isEmpty = false,
    this.needsYou = const [],
    this.today,
    this.invites = const [],
    this.teams = const TeamGroups(),
    this.following = const [],
    this.suggested = const [],
    this.suggestedTitle,
    this.showCreateNudge = false,
    this.activeFilter = MyTeamsFilter.all,
  });

  /// Header subtitle: "3 teams · playing for 3 sides".
  final String? subtitle;

  /// Short-circuits everything else and shows the EmptyState card.
  final bool isEmpty;

  final List<NeedsYouItem> needsYou;
  final TodayMatch? today;
  final List<InviteEntry> invites;
  final TeamGroups teams;
  final List<TeamRowVm> following;
  final List<SuggestedTeam> suggested;
  final String? suggestedTitle;

  /// Renders the "Play, don't just watch." dashed nudge below following.
  final bool showCreateNudge;

  final MyTeamsFilter activeFilter;
}
